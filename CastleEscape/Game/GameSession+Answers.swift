import Foundation

extension GameSession {
    /// Player tapped a choice.
    func select(choiceID: Int) {
        guard phase == .playing, !interactionLocked, let puzzle = currentPuzzle else { return }
        guard !hiddenChoiceIDs.contains(choiceID), !selection.contains(choiceID) else { return }
        AudioManager.shared.play(.uiTap, volume: 0.5)
        var next = selection
        next.append(choiceID)
        selection = next

        switch puzzle.answer {
        case .single:
            resolve(correct: PuzzleValidator.isCorrect(puzzle: puzzle, selection: next))
        case .ordered(let ids):
            if !PuzzleValidator.isPrefixValid(puzzle: puzzle, selection: next) {
                resolve(correct: false)
            } else if next.count == ids.count {
                resolve(correct: true)
            }
        }
    }

    func handleTimeout() {
        guard phase == .playing else { return }
        AudioManager.shared.play(.timeout)
        resolve(correct: false, timedOut: true)
    }

    func resolve(correct: Bool, timedOut: Bool = false) {
        guard let puzzle = currentPuzzle, let floor = currentFloor else { return }
        stopTimer()
        interactionLocked = true
        phase = .resolving
        floorStats.attempted += 1
        progress.totalPuzzlesAttempted += 1
        if !isReplay { progress.campaignPuzzlesAttempted += 1 }

        if correct {
            let elapsed = Date().timeIntervalSince(puzzleStartDate ?? Date())
            let event = scoreKeeper.registerCorrect(reward: puzzle.reward, elapsed: elapsed, timeLimit: puzzle.timeLimit)
            syncScoreState()
            floorStats.correct += 1
            floorStats.score += event.points
            floorStats.coins += event.coins
            progress.totalScore += event.points
            progress.totalPuzzlesSolved += 1
            progress.bestStreak = max(progress.bestStreak, scoreKeeper.streak)
            if !isReplay {
                progress.campaignScore += event.points
                progress.campaignPuzzlesSolved += 1
            }
            feedback = .correct(points: event.points, fastBonus: event.fastBonus, multiplier: event.multiplier, comboTier: event.comboTierReached)
            AudioManager.shared.play(.correct)
            playHaptic(success: true)
            if event.comboTierReached { director?.showCombo(multiplier: event.multiplier) }
            if event.shieldGranted { director?.showShieldGained() }
            unlockAchievements(lastFloorMistakes: nil)
            store.save(progress)

            let obstacleIndex = encounterIndex
            let isLast = encounterIndex + 1 >= floor.encounterCount
            director?.heroAdvances(obstacleIndex: obstacleIndex, dangerLevel: dangerLevel, maxDanger: maxDanger) { [weak self] in
                guard let self = self, self.phase == .resolving else { return }
                if isLast {
                    self.completeFloor()
                } else {
                    self.presentPuzzle(at: obstacleIndex + 1)
                }
            }
        } else {
            floorStats.mistakes += 1
            let absorbed = scoreKeeper.registerWrong()
            syncScoreState()
            playHaptic(success: false)
            if absorbed {
                feedback = .shieldSaved
                director?.guardConfused()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                    guard let self = self, self.phase == .resolving else { return }
                    self.retryCurrentPuzzle(fresh: timedOut)
                }
                return
            }
            feedback = timedOut ? .timeout : .wrong
            if !timedOut { AudioManager.shared.play(.wrong) }
            dangerLevel += 1
            if case .single(let correctID) = puzzle.answer, let wrongID = selection.last, wrongID != correctID {
                hiddenChoiceIDs.insert(wrongID)
            }
            if dangerLevel >= maxDanger {
                director?.guardCatches { [weak self] in
                    guard let self = self, self.phase == .resolving else { return }
                    AudioManager.shared.play(.gameOver)
                    self.phase = .gameOver
                }
            } else {
                director?.guardAdvances(dangerLevel: dangerLevel, maxDanger: maxDanger) { [weak self] in
                    guard let self = self, self.phase == .resolving else { return }
                    self.retryCurrentPuzzle(fresh: timedOut)
                }
            }
        }
    }

    // MARK: - Hints

    /// Hints only apply to single-answer puzzles with at least three visible choices.
    var canUseHint: Bool {
        guard phase == .playing, !interactionLocked, let puzzle = currentPuzzle else { return false }
        guard case .single = puzzle.answer, case .buttons = puzzle.presentation else { return false }
        return puzzle.choices.count - hiddenChoiceIDs.count >= 3
    }

    var hintCost: Int { config.scoring.hintCost }

    var canAffordHint: Bool { progress.coins >= hintCost }

    func useHint() {
        guard canUseHint else { return }
        if canAffordHint {
            progress.coins -= hintCost
            store.save(progress)
            applyHint()
        } else {
            ads.showRewardedAd(for: .hint) { [weak self] result in
                guard let self = self, result == .rewarded else { return }
                self.applyHint()
            }
        }
    }

    private func applyHint() {
        guard let puzzle = currentPuzzle, case .single(let correctID) = puzzle.answer else { return }
        let wrong = puzzle.choices.map(\.id).filter { $0 != correctID && !hiddenChoiceIDs.contains($0) }
        let removeCount = max(1, min(2, wrong.count - 1))
        var removed = Set<Int>()
        var pool = wrong
        for _ in 0..<removeCount where !pool.isEmpty {
            let pick = pool.remove(at: rngIndex(pool.count))
            removed.insert(pick)
        }
        hiddenChoiceIDs.formUnion(removed)
        AudioManager.shared.play(.unlock, volume: 0.6)
    }

    private func rngIndex(_ count: Int) -> Int {
        Int.random(in: 0..<max(1, count))
    }
}
