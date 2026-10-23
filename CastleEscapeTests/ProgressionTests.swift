import XCTest
@testable import CastleEscape

final class ProgressionTests: XCTestCase {
    func testCatalogHasTenFloorsInDescendingOrder() {
        XCTAssertEqual(FloorCatalog.floors.count, 10)
        XCTAssertEqual(FloorCatalog.playOrder.map(\.number), Array((1...10).reversed()))
        XCTAssertEqual(FloorCatalog.floor(10).theme, .prisonTower)
        XCTAssertEqual(FloorCatalog.floor(1).theme, .mainGate)
        XCTAssertTrue(FloorCatalog.floor(1).isFinalFloor)
    }

    func testNextFloorDescendsToTheGate() {
        XCTAssertEqual(FloorCatalog.nextFloor(after: 10), 9)
        XCTAssertEqual(FloorCatalog.nextFloor(after: 2), 1)
        XCTAssertNil(FloorCatalog.nextFloor(after: 1))
    }

    func testEveryFloorHasPlayableContent() {
        for floor in FloorCatalog.floors {
            XCTAssertGreaterThanOrEqual(floor.encounterCount, 5)
            XCTAssertFalse(floor.recipe.entries.isEmpty)
            XCTAssertFalse(floor.obstacles.isEmpty)
            XCTAssertGreaterThan(floor.safetyMargin, 0)
            XCTAssertFalse(floor.name.ar.isEmpty)
            XCTAssertFalse(floor.name.en.isEmpty)
        }
        // Difficulty increases from the prison tower to the gate.
        let bases = FloorCatalog.playOrder.map(\.recipe.baseDifficulty)
        XCTAssertEqual(bases, bases.sorted())
    }

    func testStarsDependOnMistakes() {
        XCTAssertEqual(ProgressionRules.stars(forMistakes: 0), 3)
        XCTAssertEqual(ProgressionRules.stars(forMistakes: 1), 2)
        XCTAssertEqual(ProgressionRules.stars(forMistakes: 2), 1)
        XCTAssertEqual(ProgressionRules.stars(forMistakes: 5), 1)
    }

    func testCompletingCurrentFloorAdvancesTheCampaign() {
        var progress = GameProgress()
        XCTAssertEqual(progress.currentFloor, 10)
        XCTAssertEqual(progress.status(ofFloor: 10), .current)
        XCTAssertEqual(progress.status(ofFloor: 9), .locked)
        progress.recordFloorCompletion(floor: 10, stars: 3, score: 500, time: 60, coins: 95)
        XCTAssertEqual(progress.currentFloor, 9)
        XCTAssertEqual(progress.status(ofFloor: 10), .completed(stars: 3))
        XCTAssertEqual(progress.status(ofFloor: 9), .current)
        XCTAssertEqual(progress.coins, 95)
        XCTAssertEqual(progress.starsEarned, 3)
    }

    func testReplayingAnOldFloorKeepsBestResultsWithoutAdvancing() {
        var progress = GameProgress()
        progress.recordFloorCompletion(floor: 10, stars: 1, score: 200, time: 90, coins: 10)
        progress.recordFloorCompletion(floor: 10, stars: 3, score: 150, time: 70, coins: 10)
        XCTAssertEqual(progress.currentFloor, 9)
        XCTAssertEqual(progress.completedFloors[10]?.stars, 3)
        XCTAssertEqual(progress.completedFloors[10]?.bestScore, 200)
        XCTAssertEqual(progress.completedFloors[10]?.bestTime, 70)
        XCTAssertEqual(progress.completedFloors[10]?.completions, 2)
    }

    func testEscapingTheGateMarksTheCampaignComplete() {
        var progress = GameProgress()
        for floor in (1...10).reversed() {
            progress.recordFloorCompletion(floor: floor, stars: 2, score: 100, time: 10, coins: 5)
        }
        XCTAssertTrue(progress.hasEscaped)
        XCTAssertTrue(progress.isCampaignComplete)
        XCTAssertEqual(progress.timesEscaped, 1)
        progress.restartCampaign()
        XCTAssertEqual(progress.currentFloor, 10)
        XCTAssertTrue(progress.completedFloors.isEmpty)
        XCTAssertTrue(progress.hasEscaped, "lifetime flag survives a restart")
    }

    func testAchievementsUnlockOnce() {
        var progress = GameProgress()
        progress.totalPuzzlesSolved = 1
        let first = AchievementTracker.evaluate(progress: progress, currentCombo: 0, lastFloorMistakes: nil)
        XCTAssertEqual(first, ["first_light"])
        progress.achievements.formUnion(first)
        let again = AchievementTracker.evaluate(progress: progress, currentCombo: 10, lastFloorMistakes: 0)
        XCTAssertEqual(Set(again), ["combo_ten", "flawless_floor"])
    }

    func testCheckpointsAndObstaclesStayInsideTheRoom() {
        for floor in FloorCatalog.floors {
            let points = CastleLayout.checkpoints(count: floor.encounterCount)
            XCTAssertEqual(points.count, floor.encounterCount + 1)
            XCTAssertEqual(points.first, CastleLayout.heroStartX)
            XCTAssertEqual(points.last!, CastleLayout.doorApproachX, accuracy: 0.001)
            for index in 0..<floor.encounterCount {
                let x = CastleLayout.obstacleX(index: index, count: floor.encounterCount)
                XCTAssertGreaterThan(x, points[index])
                XCTAssertLessThan(x, points[index + 1])
            }
        }
        XCTAssertEqual(CastleLayout.guardGap(dangerLevel: 3, maxDanger: 3), 70)
        XCTAssertGreaterThan(CastleLayout.guardGap(dangerLevel: 0, maxDanger: 3), CastleLayout.guardGap(dangerLevel: 1, maxDanger: 3))
    }
}
