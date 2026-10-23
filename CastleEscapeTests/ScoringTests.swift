import XCTest
@testable import CastleEscape

final class ScoringTests: XCTestCase {
    func testBasePointsAndFastBonus() {
        var keeper = ScoreKeeper(config: .default)
        let slow = keeper.registerCorrect(reward: 100, elapsed: 9, timeLimit: 10)
        XCTAssertEqual(slow.points, 100)
        XCTAssertEqual(slow.fastBonus, 0)
        let fast = keeper.registerCorrect(reward: 100, elapsed: 2, timeLimit: 10)
        XCTAssertEqual(fast.fastBonus, 50)
        XCTAssertEqual(fast.points, 150)
        XCTAssertEqual(keeper.score, 250)
    }

    func testComboMultipliersAtThreeAndFive() {
        var keeper = ScoreKeeper(config: .default)
        var events: [ScoreEvent] = []
        for _ in 0..<5 {
            events.append(keeper.registerCorrect(reward: 100, elapsed: 20, timeLimit: 20))
        }
        XCTAssertEqual(events.map(\.multiplier), [1, 1, 2, 2, 3])
        XCTAssertEqual(events.map(\.points), [100, 100, 200, 200, 300])
        XCTAssertEqual(events.map(\.comboTierReached), [false, false, true, false, true])
        XCTAssertEqual(keeper.streak, 5)
    }

    func testWrongAnswerResetsStreak() {
        var keeper = ScoreKeeper(config: .default)
        for _ in 0..<4 { keeper.registerCorrect(reward: 100, elapsed: 20, timeLimit: 20) }
        XCTAssertEqual(keeper.multiplier, 2)
        XCTAssertFalse(keeper.registerWrong())
        XCTAssertEqual(keeper.streak, 0)
        XCTAssertEqual(keeper.multiplier, 1)
        XCTAssertEqual(keeper.wrongCount, 1)
    }

    func testShieldGrantedAtTenAndAbsorbsOneMistake() {
        var keeper = ScoreKeeper(config: .default)
        var granted = false
        for _ in 0..<10 {
            let event = keeper.registerCorrect(reward: 100, elapsed: 20, timeLimit: 20)
            granted = granted || event.shieldGranted
        }
        XCTAssertTrue(granted)
        XCTAssertTrue(keeper.hasShield)
        XCTAssertTrue(keeper.registerWrong(), "the shield should absorb the first mistake")
        XCTAssertFalse(keeper.hasShield)
        XCTAssertFalse(keeper.registerWrong())
    }

    func testConfigurableThresholds() {
        var config = ScoreConfig.default
        config.comboThresholds = [ScoreConfig.ComboTier(streak: 2, multiplier: 4)]
        config.basePoints = 10
        var keeper = ScoreKeeper(config: config)
        keeper.registerCorrect(reward: 0, elapsed: 50, timeLimit: nil)
        let second = keeper.registerCorrect(reward: 0, elapsed: 50, timeLimit: nil)
        XCTAssertEqual(second.multiplier, 4)
        XCTAssertEqual(second.points, 40)
    }

    func testGameConfigFileLoadsFromBundle() {
        // The app bundle is the test host, so Bundle.main carries GameConfig.json.
        let config = GameConfigFile.load(bundle: Bundle.main)
        XCTAssertEqual(config.scoring.basePoints, 100)
        XCTAssertEqual(config.scoring.shieldStreak, 10)
        XCTAssertEqual(config.defaultSafetyMargin, 3)
    }

    func testCoinsCanBeSpentOnlyWhenAvailable() {
        var keeper = ScoreKeeper(config: .default)
        keeper.addCoins(25)
        XCTAssertFalse(keeper.spendCoins(30))
        XCTAssertTrue(keeper.spendCoins(20))
        XCTAssertEqual(keeper.coins, 5)
    }
}
