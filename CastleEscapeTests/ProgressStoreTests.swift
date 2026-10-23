import XCTest
@testable import CastleEscape

final class ProgressStoreTests: XCTestCase {
    private var directory: URL!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("CastleEscapeTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults = UserDefaults(suiteName: "CastleEscapeTests.\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testProgressRoundTrip() {
        let store = ProgressStore(directory: directory, defaults: defaults)
        var progress = GameProgress()
        progress.recordFloorCompletion(floor: 10, stars: 2, score: 420, time: 33, coins: 80)
        progress.totalScore = 1_234
        progress.achievements = ["first_light", "tower_breaker"]
        progress.campaignScore = 420
        progress.storyShown = true
        store.save(progress)

        let reloaded = ProgressStore(directory: directory, defaults: defaults).loadProgress()
        XCTAssertEqual(reloaded, progress)
        XCTAssertEqual(reloaded.currentFloor, 9)
        XCTAssertEqual(reloaded.completedFloors[10]?.stars, 2)
    }

    func testMissingFileYieldsFreshProgress() {
        let store = ProgressStore(directory: directory, defaults: defaults)
        let progress = store.loadProgress()
        XCTAssertEqual(progress, GameProgress())
        XCTAssertFalse(progress.hasStarted)
    }

    func testCorruptFileYieldsFreshProgress() throws {
        let store = ProgressStore(directory: directory, defaults: defaults)
        try "not json".data(using: .utf8)!.write(to: store.progressURL)
        XCTAssertEqual(store.loadProgress(), GameProgress())
    }

    func testDeleteProgress() {
        let store = ProgressStore(directory: directory, defaults: defaults)
        var progress = GameProgress()
        progress.coins = 50
        store.save(progress)
        XCTAssertEqual(store.loadProgress().coins, 50)
        store.deleteProgress()
        XCTAssertEqual(store.loadProgress().coins, 0)
    }

    func testSettingsRoundTripThroughDefaults() {
        let store = ProgressStore(directory: directory, defaults: defaults)
        var settings = GameSettings()
        settings.language = .english
        settings.musicEnabled = false
        settings.isPremium = true
        store.save(settings)
        let reloaded = ProgressStore(directory: directory, defaults: defaults).loadSettings()
        XCTAssertEqual(reloaded, settings)
        XCTAssertEqual(reloaded.language, .english)
    }

    func testDefaultSettingsAreArabicWithAudioOn() {
        let settings = GameSettings()
        XCTAssertEqual(settings.language, .arabic)
        XCTAssertTrue(settings.musicEnabled)
        XCTAssertTrue(settings.soundEffectsEnabled)
        XCTAssertFalse(settings.isPremium)
    }
}
