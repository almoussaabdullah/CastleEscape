import Foundation

/// A piece of text that carries both Arabic and English variants.
///
/// Puzzle content is generated programmatically, so the generators emit both
/// languages at once. The UI resolves the variant that matches the player's
/// selected language, which also lets the player switch languages mid-game.
struct LocalizedText: Codable, Equatable, Hashable {
    var ar: String
    var en: String

    init(ar: String, en: String) {
        self.ar = ar
        self.en = en
    }

    /// Same text in both languages (numbers, symbols, names...).
    init(_ shared: String) {
        self.ar = shared
        self.en = shared
    }

    func resolved(_ language: AppLanguage) -> String {
        switch language {
        case .arabic: return ar
        case .english: return en
        }
    }

    static let empty = LocalizedText(ar: "", en: "")

    static func + (lhs: LocalizedText, rhs: LocalizedText) -> LocalizedText {
        LocalizedText(ar: lhs.ar + rhs.ar, en: lhs.en + rhs.en)
    }
}
