import Foundation
import SwiftUI

/// Languages the game ships with. Adding a language means adding a case here,
/// a column in `tools/strings.py` and a variant in every `LocalizedText`.
enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case arabic = "ar"
    case english = "en"

    var id: String { rawValue }

    var isRightToLeft: Bool { self == .arabic }

    var layoutDirection: LayoutDirection { isRightToLeft ? .rightToLeft : .leftToRight }

    var locale: Locale { Locale(identifier: rawValue) }

    var nativeName: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        }
    }

    /// Best match for the device's preferred languages; Arabic remains the default.
    static func preferred() -> AppLanguage {
        for code in Locale.preferredLanguages {
            if code.hasPrefix("ar") { return .arabic }
            if code.hasPrefix("en") { return .english }
        }
        return .arabic
    }
}

/// Resolves UI strings for the currently selected language at runtime,
/// independent of the device locale, so the in-game language switch is instant.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var language: AppLanguage
    private var bundle: Bundle
    private var cache: [String: Bundle] = [:]

    init(language: AppLanguage = .arabic) {
        self.language = language
        self.bundle = LocalizationManager.bundle(for: language)
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != self.language else { return }
        self.language = language
        bundle = LocalizationManager.bundle(for: language)
    }

    private static func bundle(for language: AppLanguage) -> Bundle {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    /// Plain string lookup.
    func t(_ key: L10nKey) -> String {
        let value = bundle.localizedString(forKey: key.rawValue, value: nil, table: "Localizable")
        if value == key.rawValue, let fallback = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let english = Bundle(path: fallback) {
            return english.localizedString(forKey: key.rawValue, value: key.rawValue, table: "Localizable")
        }
        return value
    }

    /// Format string lookup (`%d`, `%@`). Numbers always use Western digits so they
    /// match the math expressions shown in puzzles.
    func t(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: LocalizationManager.formatLocale, arguments: arguments)
    }

    static let formatLocale = Locale(identifier: "en_US_POSIX")

    /// Resolves generated bilingual content.
    func t(_ text: LocalizedText) -> String {
        text.resolved(language)
    }
}

/// Convenience for non-view code.
func L(_ key: L10nKey) -> String { LocalizationManager.shared.t(key) }
func L(_ key: L10nKey, _ arguments: CVarArg...) -> String {
    String(format: LocalizationManager.shared.t(key), locale: LocalizationManager.formatLocale, arguments: arguments)
}
