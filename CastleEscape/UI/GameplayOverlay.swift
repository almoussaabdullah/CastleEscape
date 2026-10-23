import SwiftUI

/// HUD at the top, puzzle panel at the bottom; the SpriteKit corridor shows in between.
struct GameplayOverlay: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @EnvironmentObject private var session: GameSession
    @State private var hudHeight: CGFloat = 0
    @State private var panelHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HUDView()
                    .background(GeometryReader { proxy in
                        Color.clear
                            .onAppear { hudHeight = proxy.size.height }
                            .onChange(of: proxy.size.height) { _, newValue in hudHeight = newValue }
                    })
                Spacer(minLength: 0)
                PuzzlePanelView()
                    .background(GeometryReader { proxy in
                        Color.clear
                            .onAppear { panelHeight = proxy.size.height }
                            .onChange(of: proxy.size.height) { _, newValue in panelHeight = newValue }
                    })
            }
            .onChange(of: hudHeight) { _, _ in report(safeArea: geo.safeAreaInsets) }
            .onChange(of: panelHeight) { _, _ in report(safeArea: geo.safeAreaInsets) }
            .onAppear { report(safeArea: geo.safeAreaInsets) }
        }
    }

    private func report(safeArea: EdgeInsets) {
        let top = (hudHeight > 0 ? hudHeight : 70) + safeArea.top
        let bottom = (panelHeight > 0 ? panelHeight : 330) + safeArea.bottom
        coordinator.reportGameplayInsets(top: top, bottom: bottom)
    }
}

/// Hearts, floor, score, combo and pause.
struct HUDView: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            hearts
            Spacer(minLength: 4)
            floorBadge
            Spacer(minLength: 4)
            scoreBadge
            Button {
                session.pause()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.parchment)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.panel.opacity(0.85)))
                    .overlay(Circle().stroke(Theme.gold.opacity(0.6), lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .top, endPoint: .bottom).ignoresSafeArea(edges: .top))
    }

    private var hearts: some View {
        HStack(spacing: 3) {
            ForEach(0..<session.maxDanger, id: \.self) { index in
                let filled = index < session.maxDanger - session.dangerLevel
                Image(systemName: filled ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(filled ? Theme.scarf : Theme.parchment.opacity(0.35))
                    .scaleEffect(filled ? 1 : 0.85)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: session.dangerLevel)
            }
            if session.hasShield {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.magic)
                    .transition(.scale)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Capsule().fill(Theme.panel.opacity(0.8)))
        .overlay(Capsule().stroke(Theme.gold.opacity(0.5), lineWidth: 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: session.hasShield)
    }

    private var floorBadge: some View {
        VStack(spacing: 1) {
            Text(loc.t(.hudFloor, session.currentFloor?.number ?? 0))
                .font(Theme.heading(15))
                .foregroundStyle(Theme.gold)
            if let floor = session.currentFloor {
                Text(loc.t(floor.name))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.parchment.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.panel.opacity(0.8)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.gold.opacity(0.5), lineWidth: 1))
    }

    private var scoreBadge: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("\(session.runScore)")
                .font(Theme.mono(18))
                .foregroundStyle(Theme.parchment)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.4), value: session.runScore)
            if session.multiplier > 1 {
                Text(loc.t(.hudCombo, Int(session.multiplier)))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.gold))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text(loc.t(.hudScore))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.parchment.opacity(0.7))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.panel.opacity(0.8)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.gold.opacity(0.5), lineWidth: 1))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: session.multiplier)
    }
}
