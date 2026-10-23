import Foundation

/// Tunable scoring parameters. Loaded from `GameConfig.json` when present,
/// otherwise the defaults below apply.
struct ScoreConfig: Codable, Equatable {
    var basePoints: Int = 100
    /// Extra points when the answer arrives within `fastAnswerFraction` of the time limit
    /// (or within `fastAnswerSeconds` for untimed puzzles).
    var fastAnswerBonus: Int = 50
    var fastAnswerFraction: Double = 0.4
    var fastAnswerSeconds: Double = 4.0
    /// Streak thresholds and their multipliers, ascending.
    var comboThresholds: [ComboTier] = [
        ComboTier(streak: 3, multiplier: 2.0),
        ComboTier(streak: 5, multiplier: 3.0),
    ]
    /// Streak that grants a protective shield absorbing one mistake.
    var shieldStreak: Int = 10
    var coinsPerCorrect: Int = 10
    var floorCompletionCoins: Int = 50
    var coinsPerStar: Int = 15
    var hintCost: Int = 30

    struct ComboTier: Codable, Equatable {
        var streak: Int
        var multiplier: Double
    }

    /// Multiplier that applies to a streak of `streak` consecutive correct answers.
    func multiplier(forStreak streak: Int) -> Double {
        var result = 1.0
        for tier in comboThresholds.sorted(by: { $0.streak < $1.streak }) where streak >= tier.streak {
            result = tier.multiplier
        }
        return result
    }

    static let `default` = ScoreConfig()
}

/// Loads `GameConfig.json` from the bundle.
struct GameConfigFile: Codable, Equatable {
    var scoring: ScoreConfig = .default
    /// Seconds the guard needs to catch the hero at the final danger step; purely cosmetic.
    var guardLungeDuration: Double = 0.55
    /// Danger steps (wrong answers) allowed when a floor does not override it.
    var defaultSafetyMargin: Int = 3

    static func load(bundle: Bundle = .main) -> GameConfigFile {
        guard let url = bundle.url(forResource: "GameConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(GameConfigFile.self, from: data) else {
            return GameConfigFile()
        }
        return decoded
    }
}
