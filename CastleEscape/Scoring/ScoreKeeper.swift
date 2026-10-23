import Foundation

/// Result of scoring one answer.
struct ScoreEvent: Equatable {
    var points: Int
    var basePoints: Int
    var fastBonus: Int
    var multiplier: Double
    var streak: Int
    var coins: Int
    /// True on the exact answer that earned a shield.
    var shieldGranted: Bool
    /// True when the streak just crossed a combo threshold (for UI celebration).
    var comboTierReached: Bool
}

/// Tracks score, streaks and the protective shield for the current run.
struct ScoreKeeper: Equatable {
    let config: ScoreConfig
    private(set) var score: Int = 0
    private(set) var coins: Int = 0
    private(set) var streak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var hasShield: Bool = false
    private(set) var correctCount: Int = 0
    private(set) var wrongCount: Int = 0

    init(config: ScoreConfig = .default) {
        self.config = config
    }

    var multiplier: Double { config.multiplier(forStreak: streak) }
    var attempted: Int { correctCount + wrongCount }

    /// Registers a correct answer.
    /// - Parameters:
    ///   - reward: the puzzle's base reward.
    ///   - elapsed: seconds spent on the puzzle.
    ///   - timeLimit: the puzzle's limit, if any.
    @discardableResult
    mutating func registerCorrect(reward: Int, elapsed: Double, timeLimit: Double?) -> ScoreEvent {
        let previousMultiplier = multiplier
        streak += 1
        bestStreak = max(bestStreak, streak)
        correctCount += 1

        let fast: Bool
        if let limit = timeLimit {
            fast = elapsed <= limit * config.fastAnswerFraction
        } else {
            fast = elapsed <= config.fastAnswerSeconds
        }
        let fastBonus = fast ? config.fastAnswerBonus : 0
        let base = reward > 0 ? reward : config.basePoints
        let mult = multiplier
        let points = Int((Double(base + fastBonus) * mult).rounded())
        score += points
        coins += config.coinsPerCorrect

        var shieldGranted = false
        if streak == config.shieldStreak && !hasShield {
            hasShield = true
            shieldGranted = true
        }
        return ScoreEvent(points: points, basePoints: base, fastBonus: fastBonus, multiplier: mult,
                          streak: streak, coins: config.coinsPerCorrect, shieldGranted: shieldGranted,
                          comboTierReached: mult > previousMultiplier)
    }

    /// Registers a wrong answer. Returns `true` when a shield absorbed the mistake.
    @discardableResult
    mutating func registerWrong() -> Bool {
        wrongCount += 1
        streak = 0
        if hasShield {
            hasShield = false
            return true
        }
        return false
    }

    mutating func addCoins(_ amount: Int) { coins += amount }

    mutating func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }

    mutating func resetStreak() { streak = 0 }
}
