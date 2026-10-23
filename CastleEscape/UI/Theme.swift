import SwiftUI

/// Shared colours, fonts and reusable styles for the SwiftUI layer.
enum Theme {
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.30)
    static let goldDark = Color(red: 0.72, green: 0.52, blue: 0.14)
    static let parchment = Color(red: 0.97, green: 0.93, blue: 0.82)
    static let ink = Color(red: 0.10, green: 0.09, blue: 0.16)
    static let panel = Color(red: 0.09, green: 0.09, blue: 0.19)
    static let panelLight = Color(red: 0.16, green: 0.16, blue: 0.30)
    static let danger = Color(red: 1.0, green: 0.36, blue: 0.36)
    static let success = Color(red: 0.42, green: 0.90, blue: 0.56)
    static let magic = Color(red: 0.55, green: 0.65, blue: 1.0)
    static let scarf = Color(red: 0.90, green: 0.22, blue: 0.26)

    static func title(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func heading(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func mono(_ size: CGFloat = 30) -> Font { .system(size: size, weight: .heavy, design: .rounded).monospacedDigit() }

    static func color(for tint: PuzzleSymbol.Tint) -> Color {
        let c = tint.rgb
        return Color(red: c.red, green: c.green, blue: c.blue)
    }
}

/// Gold fantasy button used across menus.
struct FantasyButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, danger }
    var kind: Kind = .primary
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? Theme.body(16) : Theme.heading(20))
            .foregroundStyle(kind == .primary ? Theme.ink : Theme.parchment)
            .padding(.vertical, compact ? 10 : 15)
            .padding(.horizontal, compact ? 18 : 26)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(kind == .primary ? Theme.goldDark : Theme.gold.opacity(0.6), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }

    private var background: some View {
        let colors: [Color]
        switch kind {
        case .primary: colors = [Theme.gold, Theme.goldDark]
        case .secondary: colors = [Theme.panelLight, Theme.panel]
        case .danger: colors = [Color(red: 0.75, green: 0.20, blue: 0.22), Color(red: 0.45, green: 0.10, blue: 0.14)]
        }
        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
    }
}

/// Dark translucent panel with a gold frame.
struct ParchmentPanel<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.panel.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
    }
}

/// Horizontal shake used by the puzzle panel after a wrong answer.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}

/// Reports a view's height through the preference system (used to size the camera framing).
struct HeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    func reportHeight() -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
        })
    }
}

/// Draws a puzzle symbol glyph.
struct SymbolGlyph: View {
    let symbol: PuzzleSymbol
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: symbol.shape.systemImageName)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Theme.color(for: symbol.tint))
            .shadow(color: Theme.color(for: symbol.tint).opacity(0.6), radius: 6)
            .frame(width: size + 12, height: size + 12)
    }
}

/// Small star row for floor results.
struct StarsView: View {
    let stars: Int
    var size: CGFloat = 26

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(index < stars ? Theme.gold : Theme.parchment.opacity(0.35))
            }
        }
    }
}
