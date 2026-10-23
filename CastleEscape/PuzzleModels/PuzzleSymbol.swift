import Foundation

/// A colored glyph used by visual puzzles (memory sequences, odd-one-out grids).
/// Rendered by the UI layer; the model only describes shape + color.
struct PuzzleSymbol: Codable, Equatable, Hashable {
    enum Shape: String, Codable, CaseIterable {
        case circle, square, triangle, diamond, star, heart, hexagon, moon
    }

    enum Tint: String, Codable, CaseIterable {
        case ruby, amber, emerald, sapphire, violet, teal, coral, gold
    }

    var shape: Shape
    var tint: Tint

    /// Short, language independent description used for accessibility and tests.
    var debugName: String { "\(tint.rawValue)-\(shape.rawValue)" }

    var localizedName: LocalizedText {
        LocalizedText(ar: "\(tint.arabicName) \(shape.arabicName)",
                      en: "\(tint.englishName) \(shape.englishName)")
    }
}

extension PuzzleSymbol.Shape {
    var arabicName: String {
        switch self {
        case .circle: return "دائرة"
        case .square: return "مربع"
        case .triangle: return "مثلث"
        case .diamond: return "معيّن"
        case .star: return "نجمة"
        case .heart: return "قلب"
        case .hexagon: return "سداسي"
        case .moon: return "هلال"
        }
    }

    var englishName: String {
        switch self {
        case .circle: return "circle"
        case .square: return "square"
        case .triangle: return "triangle"
        case .diamond: return "diamond"
        case .star: return "star"
        case .heart: return "heart"
        case .hexagon: return "hexagon"
        case .moon: return "moon"
        }
    }

    /// SF Symbol name used by SwiftUI to draw the glyph.
    var systemImageName: String {
        switch self {
        case .circle: return "circle.fill"
        case .square: return "square.fill"
        case .triangle: return "triangle.fill"
        case .diamond: return "diamond.fill"
        case .star: return "star.fill"
        case .heart: return "heart.fill"
        case .hexagon: return "hexagon.fill"
        case .moon: return "moon.fill"
        }
    }
}

extension PuzzleSymbol.Tint {
    var arabicName: String {
        switch self {
        case .ruby: return "أحمر"
        case .amber: return "برتقالي"
        case .emerald: return "أخضر"
        case .sapphire: return "أزرق"
        case .violet: return "بنفسجي"
        case .teal: return "فيروزي"
        case .coral: return "وردي"
        case .gold: return "ذهبي"
        }
    }

    var englishName: String {
        switch self {
        case .ruby: return "red"
        case .amber: return "orange"
        case .emerald: return "green"
        case .sapphire: return "blue"
        case .violet: return "purple"
        case .teal: return "teal"
        case .coral: return "pink"
        case .gold: return "gold"
        }
    }

    /// RGB components (0...1) so both SwiftUI and SpriteKit can use the same palette.
    var rgb: (red: Double, green: Double, blue: Double) {
        switch self {
        case .ruby: return (0.93, 0.26, 0.30)
        case .amber: return (0.99, 0.60, 0.20)
        case .emerald: return (0.25, 0.78, 0.45)
        case .sapphire: return (0.27, 0.52, 0.96)
        case .violet: return (0.62, 0.40, 0.93)
        case .teal: return (0.18, 0.78, 0.80)
        case .coral: return (0.98, 0.45, 0.62)
        case .gold: return (0.98, 0.80, 0.25)
        }
    }
}
