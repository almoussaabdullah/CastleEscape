import Combine
import Foundation
import UIKit

/// The gameplay state machine. Owns progress, scoring and the puzzle run, and drives the
/// scene through `SceneDirecting`. UI reads the published properties.
final class GameSession: ObservableObject {
    enum Phase: Equatable {
        case menu, story, entering, playing, resolving, floorCleared, gameOver, victory, paused
    }

    // MARK: Published state

    @Published var phase: Phase = .menu
    @Published var progress: GameProgress
    @Published var settings: GameSettings {
        didSet { applySettings(); store.save(settings) }
    }
    @Published var currentFloor: FloorDefinition?
    @Published var currentPuzzle: Puzzle?
    @Published var encounterIndex: Int = 0
    @Published var dangerLevel: Int = 0
    @Published var runScore: Int = 0
    @Published var streak: Int = 0
    @Published var multiplier: Double = 1
    @Published var hasShield: Bool = false
    @Published var timeRemaining: Double?
    @Published var selection: [Int] = []
    @Published var hiddenChoiceIDs: Set<Int> = []
    @Published var feedback: AnswerFeedback?
    @Published var isMemorizing: Bool = false
    @Published var interactionLocked: Bool = true
    @Published var floorSummary: FloorSummary?
    @Published var victorySummary: VictorySummary?
    @Published var achievementToast: Achievement?
    @Published var floorStats = FloorRunStats()
    /// True while the current floor is a replay of an already completed floor.
    @Published var isReplay: Bool = false

    // MARK: Dependencies

    weak var director: SceneDirecting?
    let ads: MockAdManager
    let store: ProgressStore
    let config: GameConfigFile
    let localization: LocalizationManager

    var scoreKeeper: ScoreKeeper
    private let factory = PuzzleFactory()
    private var rng = SeededRandom()
    var puzzles: [Puzzle] = []
    var puzzleStartDate: Date?
    private var timer: Timer?
    private var pausedPhase: Phase?
    private var toastWorkItem: DispatchWorkItem?
    private let haptics = UINotificationFeedbackGenerator()

    var maxDanger: Int { currentFloor?.safetyMargin ?? config.defaultSafetyMargin }

    init(store: ProgressStore = ProgressStore(), ads: MockAdManager = MockAdManager(), config: GameConfigFile = GameConfigFile.load(), localization: LocalizationManager = .shared) {
        self.store = store
        self.ads = ads
        self.config = config
        self.localization = localization
        self.progress = store.loadProgress()
        self.settings = store.loadSettings()
        self.scoreKeeper = ScoreKeeper(config: config.scoring)
        applySettings()
    }

    // MARK: - Settings

    func applySettings() {
        localization.setLanguage(settings.language)
        AudioManager.shared.musicEnabled = settings.musicEnabled
        AudioManager.shared.soundEffectsEnabled = settings.soundEffectsEnabled
        ads.isAdFree = settings.isPremium
    }

    func resetAllProgress() {
        stopTimer()
        progress = GameProgress()
        store.deleteProgress()
        store.save(progress)
        director?.applyProgress(statuses: progress.floorStatuses, animated: true)
    }

    // MARK: - Lifecycle

    /// Called once the scene is attached.
    func start() {
        director?.applyProgress(statuses: progress.floorStatuses, animated: false)
        director?.showOverview(menu: true, animated: false)
        phase = .menu
    }

    func saveNow() {
        store.save(progress)
        store.save(settings)
    }

    // MARK: - Menu actions

    var canContinue: Bool { progress.hasStarted && !progress.isCampaignComplete }

    func playFromMenu() {
        if progress.isCampaignComplete {
            startNewAdventure()
        } else if !progress.storyShown {
            phase = .story
        } else {
            beginFloor(progress.currentFloor, replay: false)
        }
    }

    func storyFinished() {
        progress.storyShown = true
        store.save(progress)
        beginFloor(progress.currentFloor, replay: false)
    }

    func startNewAdventure() {
        progress.restartCampaign()
        store.save(progress)
        director?.applyProgress(statuses: progress.floorStatuses, animated: true)
        if !progress.storyShown {
            phase = .story
        } else {
            beginFloor(FloorCatalog.topFloor, replay: false)
        }
    }

    func replayFloor(_ number: Int) {
        guard progress.completedFloors[number] != nil || number == progress.currentFloor else { return }
        beginFloor(number, replay: progress.completedFloors[number] != nil && number != progress.currentFloor)
    }

    func returnToMenu() {
        stopTimer()
        currentPuzzle = nil
        currentFloor = nil
        floorSummary = nil
        victorySummary = nil
        interactionLocked = true
        director?.abandonFloor()
        phase = .menu
    }

    // MARK: - Floor flow

    func beginFloor(_ number: Int, replay: Bool) {
        stopTimer()
        let floor = FloorCatalog.floor(number)
        currentFloor = floor
        isReplay = replay
        puzzles = factory.makeRun(recipe: floor.recipe, count: floor.encounterCount, rng: &rng)
        encounterIndex = 0
        dangerLevel = 0
        floorStats = FloorRunStats()
        scoreKeeper = ScoreKeeper(config: config.scoring)
        syncScoreState()
        currentPuzzle = nil
        feedback = nil
        selection = []
        hiddenChoiceIDs = []
        floorSummary = nil
        victorySummary = nil
        interactionLocked = true
        phase = .entering
        director?.enterFloor(floor) { [weak self] in
            guard let self = self else { return }
            self.floorStats.startDate = Date()
            self.phase = .playing
            let delay = number == FloorCatalog.topFloor ? 1.0 : 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.presentPuzzle(at: 0)
            }
        }
    }

    func presentPuzzle(at index: Int) {
        guard phase == .playing || phase == .resolving, index < puzzles.count else { return }
        phase = .playing
        encounterIndex = index
        let puzzle = puzzles[index]
        currentPuzzle = puzzle
        selection = []
        hiddenChoiceIDs = []
        feedback = nil
        timeRemaining = puzzle.timeLimit
        director?.heroThinks()
        if case .memorySequence(_, let reveal) = puzzle.presentation {
            isMemorizing = true
            interactionLocked = true
            DispatchQueue.main.asyncAfter(deadline: .now() + reveal) { [weak self] in
                guard let self = self, self.currentPuzzle?.id == puzzle.id, self.phase == .playing else { return }
                self.isMemorizing = false
                self.interactionLocked = false
                self.puzzleStartDate = Date()
                self.startTimer(limit: puzzle.timeLimit)
            }
        } else {
            isMemorizing = false
            interactionLocked = false
            puzzleStartDate = Date()
            startTimer(limit: puzzle.timeLimit)
        }
    }

    /// Re-presents the current encounter after a mistake. A fresh puzzle replaces the old one
    /// when the previous attempt timed out or the puzzle type cannot be retried in place.
    func retryCurrentPuzzle(fresh: Bool) {
        guard let floor = currentFloor, encounterIndex < puzzles.count else { return }
        let old = puzzles[encounterIndex]
        let needsFresh: Bool
        switch old.presentation {
        case .buttons: needsFresh = fresh
        case .symbolGrid, .memorySequence: needsFresh = true
        }
        if needsFresh {
            let difficulty = floor.recipe.difficulty(forEncounter: encounterIndex)
            puzzles[encounterIndex] = factory.makePuzzle(category: old.category, difficulty: difficulty, rng: &rng)
            hiddenChoiceIDs = []
        }
        let keepHidden = hiddenChoiceIDs
        presentPuzzle(at: encounterIndex)
        if !needsFresh { hiddenChoiceIDs = keepHidden }
    }

    func completeFloor() {
        guard let floor = currentFloor else { return }
        stopTimer()
        interactionLocked = true
        currentPuzzle = nil
        let elapsed = floorStats.elapsed
        let stars = ProgressionRules.stars(forMistakes: floorStats.mistakes)
        let coins = ProgressionRules.coins(forFloor: floor.number, stars: stars, config: config.scoring) + floorStats.coins
        let wasCurrent = floor.number == progress.currentFloor
        progress.recordFloorCompletion(floor: floor.number, stars: stars, score: floorStats.score, time: elapsed, coins: coins)
        progress.totalPlayTime += elapsed
        if wasCurrent {
            progress.campaignTime += elapsed
        }
        progress.bestRunScore = max(progress.bestRunScore, floorStats.score)
        let summary = FloorSummary(floor: floor.number, stars: stars, score: floorStats.score, coins: coins,
                                   mistakes: floorStats.mistakes, time: elapsed, nextFloor: wasCurrent ? FloorCatalog.nextFloor(after: floor.number) : nil)
        floorSummary = summary
        store.save(progress)
        unlockAchievements(lastFloorMistakes: floorStats.mistakes)

        let statuses = progress.floorStatuses
        if floor.isFinalFloor && wasCurrent {
            director?.exitFloor { [weak self] in
                guard let self = self else { return }
                self.director?.playVictory { [weak self] in
                    guard let self = self else { return }
                    self.victorySummary = VictorySummary(score: self.progress.campaignScore,
                                                         puzzlesSolved: self.progress.campaignPuzzlesSolved,
                                                         accuracy: ProgressionRules.accuracy(correct: self.progress.campaignPuzzlesSolved, attempted: self.progress.campaignPuzzlesAttempted),
                                                         totalTime: self.progress.campaignTime,
                                                         stars: self.progress.starsEarned)
                    self.phase = .victory
                }
            }
        } else {
            director?.exitFloor { [weak self] in
                guard let self = self else { return }
                self.director?.zoomOutAfterFloor(completedFloor: floor.number, statuses: statuses, nextFloor: summary.nextFloor) { [weak self] in
                    self?.phase = .floorCleared
                }
            }
        }
    }

    /// From the floor-cleared card: descend to the next floor (or back to the castle after a replay).
    func continueAfterFloor() {
        guard let summary = floorSummary else { returnToMenu(); return }
        if let next = summary.nextFloor {
            ads.showInterstitial(for: .betweenFloors) { [weak self] in
                self?.beginFloor(next, replay: false)
            }
        } else {
            returnToMenu()
        }
    }

    func doubleCoinsAfterFloor() {
        guard let summary = floorSummary else { return }
        ads.showRewardedAd(for: .doubleCoins) { [weak self] result in
            guard let self = self, result == .rewarded else { return }
            self.progress.coins += summary.coins
            self.floorSummary = FloorSummary(floor: summary.floor, stars: summary.stars, score: summary.score, coins: summary.coins * 2,
                                             mistakes: summary.mistakes, time: summary.time, nextFloor: summary.nextFloor)
            self.store.save(self.progress)
        }
    }

    // MARK: - Game over actions

    func retryFloor() {
        guard let floor = currentFloor else { return }
        stopTimer()
        currentPuzzle = nil
        feedback = nil
        selection = []
        hiddenChoiceIDs = []
        interactionLocked = true
        phase = .playing
        puzzles = factory.makeRun(recipe: floor.recipe, count: floor.encounterCount, rng: &rng)
        encounterIndex = 0
        dangerLevel = 0
        floorStats = FloorRunStats()
        scoreKeeper = ScoreKeeper(config: config.scoring)
        syncScoreState()
        director?.resetPositions(checkpoint: 0, dangerLevel: 0, maxDanger: maxDanger)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.presentPuzzle(at: 0)
        }
    }

    func continueAfterLoss() {
        ads.showRewardedAd(for: .continueAfterLoss) { [weak self] result in
            guard let self = self else { return }
            guard result == .rewarded else { return }
            self.dangerLevel = 0
            self.scoreKeeper.resetStreak()
            self.syncScoreState()
            self.phase = .playing
            self.director?.resetPositions(checkpoint: self.encounterIndex, dangerLevel: 0, maxDanger: self.maxDanger)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.retryCurrentPuzzle(fresh: true)
            }
        }
    }

    func restartFromVictory() {
        victorySummary = nil
        startNewAdventure()
    }

    // MARK: - Pause

    func pause() {
        // Pausing is only allowed while the player is thinking; animation callbacks keep
        // the resolving phase consistent on their own.
        guard phase == .playing else { return }
        pausedPhase = phase
        stopTimer(keepRemaining: true)
        floorStats.elapsedBeforePause = floorStats.elapsed
        floorStats.startDate = Date()
        phase = .paused
        director?.setPaused(true)
    }

    func resume() {
        guard phase == .paused else { return }
        director?.setPaused(false)
        floorStats.startDate = Date()
        phase = pausedPhase ?? .playing
        pausedPhase = nil
        if phase == .playing, isMemorizing, currentPuzzle != nil {
            // The reveal countdown was interrupted; show the sequence again from the start.
            presentPuzzle(at: encounterIndex)
            return
        }
        if phase == .playing, let remaining = timeRemaining, !isMemorizing, currentPuzzle != nil {
            puzzleStartDate = Date().addingTimeInterval(-((currentPuzzle?.timeLimit ?? remaining) - remaining))
            startTimer(limit: remaining, resuming: true)
        }
    }

    // MARK: - Scoring helpers

    func syncScoreState() {
        runScore = scoreKeeper.score
        streak = scoreKeeper.streak
        multiplier = scoreKeeper.multiplier
        hasShield = scoreKeeper.hasShield
    }

    func unlockAchievements(lastFloorMistakes: Int?) {
        let unlocked = AchievementTracker.evaluate(progress: progress, currentCombo: scoreKeeper.streak, lastFloorMistakes: lastFloorMistakes)
        guard !unlocked.isEmpty else { return }
        for id in unlocked { progress.achievements.insert(id) }
        store.save(progress)
        if let first = unlocked.first, let achievement = Achievement.named(first) {
            showToast(achievement)
        }
    }

    func showToast(_ achievement: Achievement) {
        toastWorkItem?.cancel()
        achievementToast = achievement
        let work = DispatchWorkItem { [weak self] in self?.achievementToast = nil }
        toastWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: work)
    }

    // MARK: - Timer

    func startTimer(limit: Double?, resuming: Bool = false) {
        stopTimer()
        guard let limit = limit else { timeRemaining = nil; return }
        timeRemaining = limit
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stopTimer(keepRemaining: Bool = false) {
        timer?.invalidate()
        timer = nil
        if !keepRemaining { /* timeRemaining is left for display until the next puzzle */ }
    }

    private func tick() {
        guard phase == .playing, let start = puzzleStartDate, let limit = currentPuzzle?.timeLimit else { return }
        let remaining = max(0, limit - Date().timeIntervalSince(start))
        timeRemaining = remaining
        if remaining <= 0 {
            stopTimer()
            handleTimeout()
        }
    }

    func playHaptic(success: Bool) {
        guard settings.hapticsEnabled else { return }
        haptics.notificationOccurred(success ? .success : .error)
    }
}
