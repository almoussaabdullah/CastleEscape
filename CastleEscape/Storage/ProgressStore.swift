import Foundation

/// Persists progress as JSON in Application Support and settings in UserDefaults.
final class ProgressStore {
    private let directory: URL
    private let defaults: UserDefaults
    private let settingsKey = "castleescape.settings.v1"
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    private let decoder = JSONDecoder()

    var progressURL: URL { directory.appendingPathComponent("progress.json") }

    /// - Parameters:
    ///   - directory: where `progress.json` lives; defaults to Application Support.
    ///   - defaults: UserDefaults suite for settings.
    init(directory: URL? = nil, defaults: UserDefaults = .standard) {
        if let directory = directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.directory = base.appendingPathComponent("CastleEscape", isDirectory: true)
        }
        self.defaults = defaults
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    // MARK: Progress

    func loadProgress() -> GameProgress {
        guard let data = try? Data(contentsOf: progressURL),
              let progress = try? decoder.decode(GameProgress.self, from: data) else {
            return GameProgress()
        }
        return progress
    }

    func save(_ progress: GameProgress) {
        guard let data = try? encoder.encode(progress) else { return }
        do {
            try data.write(to: progressURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("ProgressStore: failed to save progress: \(error)")
            #endif
        }
    }

    func deleteProgress() {
        try? FileManager.default.removeItem(at: progressURL)
    }

    // MARK: Settings

    func loadSettings() -> GameSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? decoder.decode(GameSettings.self, from: data) else {
            return GameSettings()
        }
        return settings
    }

    func save(_ settings: GameSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }
}
