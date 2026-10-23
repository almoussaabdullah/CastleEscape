import Foundation

/// Feedback shown by the puzzle panel after an answer.
enum AnswerFeedback: Equatable {
    case correct(points: Int, fastBonus: Int, multiplier: Double, comboTier: Bool)
    case wrong
    case timeout
    case shieldSaved
}

/// Result card shown after a floor is cleared.
struct FloorSummary: Equatable {
    let floor: Int
    let stars: Int
    let score: Int
    let coins: Int
    let mistakes: Int
    let time: Double
    let nextFloor: Int?
}

/// Numbers shown on the victory screen.
struct VictorySummary: Equatable {
    let score: Int
    let puzzlesSolved: Int
    let accuracy: Double
    let totalTime: Double
    let stars: Int
}

/// Counters for the current floor run.
struct FloorRunStats: Equatable {
    var mistakes = 0
    var correct = 0
    var attempted = 0
    var score = 0
    var coins = 0
    var startDate = Date()
    var elapsedBeforePause: Double = 0

    var elapsed: Double { elapsedBeforePause + Date().timeIntervalSince(startDate) }
}

/// Snapshot of progress used by the castle overview.
extension GameProgress {
    var floorStatuses: [Int: FloorStatus] {
        var result: [Int: FloorStatus] = [:]
        for floor in FloorCatalog.bottomFloor...FloorCatalog.topFloor {
            result[floor] = status(ofFloor: floor)
        }
        return result
    }
}

/// Formats durations like 03:42.
enum DurationFormatter {
    static func string(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        if minutes >= 60 {
            return String(format: "%d:%02d:%02d", minutes / 60, minutes % 60, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
