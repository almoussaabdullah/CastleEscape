import Foundation

/// Result stored for each completed floor.
struct FloorResult: Codable, Equatable {
    var stars: Int
    var bestScore: Int
    var bestTime: Double
    var completions: Int

    mutating func merge(stars newStars: Int, score newScore: Int, time newTime: Double) {
        stars = max(stars, newStars)
        bestScore = max(bestScore, newScore)
        bestTime = bestTime == 0 ? newTime : min(bestTime, newTime)
        completions += 1
    }
}

/// Everything that must survive the app being closed.
struct GameProgress: Codable, Equatable {
    var schemaVersion: Int = 1
    /// Floor the hero is currently on (10 = start).
    var currentFloor: Int = FloorCatalog.topFloor
    var completedFloors: [Int: FloorResult] = [:]
    var totalScore: Int = 0
    var coins: Int = 0
    var totalPuzzlesSolved: Int = 0
    var totalPuzzlesAttempted: Int = 0
    var totalPlayTime: Double = 0
    var bestStreak: Int = 0
    var bestRunScore: Int = 0
    var achievements: Set<String> = []
    var hasEscaped: Bool = false
    var timesEscaped: Int = 0
    // Stats for the current campaign (reset by `restartCampaign`).
    var campaignScore: Int = 0
    var campaignPuzzlesSolved: Int = 0
    var campaignPuzzlesAttempted: Int = 0
    var campaignTime: Double = 0
    var storyShown: Bool = false

    var starsEarned: Int { completedFloors.values.reduce(0) { $0 + $1.stars } }

    /// True once every floor including the gate has been cleared in this campaign.
    var isCampaignComplete: Bool { completedFloors.count >= FloorCatalog.floors.count }

    var hasStarted: Bool { currentFloor != FloorCatalog.topFloor || !completedFloors.isEmpty || totalPuzzlesAttempted > 0 }

    func status(ofFloor floor: Int) -> FloorStatus {
        if let result = completedFloors[floor] { return .completed(stars: result.stars) }
        if floor == currentFloor { return .current }
        return .locked
    }

    /// Applies a finished floor run.
    mutating func recordFloorCompletion(floor: Int, stars: Int, score: Int, time: Double, coins earned: Int) {
        if var existing = completedFloors[floor] {
            existing.merge(stars: stars, score: score, time: time)
            completedFloors[floor] = existing
        } else {
            completedFloors[floor] = FloorResult(stars: stars, bestScore: score, bestTime: time, completions: 1)
        }
        coins += earned
        // Only advance the campaign when the player completed their current floor.
        if floor == currentFloor {
            if let next = FloorCatalog.nextFloor(after: floor) {
                currentFloor = next
            } else {
                hasEscaped = true
                timesEscaped += 1
            }
        }
    }

    /// Starts a fresh campaign while keeping lifetime statistics and achievements.
    mutating func restartCampaign() {
        currentFloor = FloorCatalog.topFloor
        completedFloors = [:]
        campaignScore = 0
        campaignPuzzlesSolved = 0
        campaignPuzzlesAttempted = 0
        campaignTime = 0
    }
}

/// Player preferences.
struct GameSettings: Codable, Equatable {
    var language: AppLanguage = .arabic
    var musicEnabled: Bool = true
    var soundEffectsEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var reducedMotion: Bool = false
    /// Ad-free premium mode (simulated purchase in this version).
    var isPremium: Bool = false
}
