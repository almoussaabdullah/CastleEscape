import SwiftUI

/// Animated main menu over the drifting castle overview.
struct MainMenuView: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @State private var titleVisible = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                titleBlock
                    .padding(.top, 18)
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : -16)
                Spacer()
                buttons
                    .padding(.horizontal, 28)
                    .padding(.bottom, 22)
                    .reportHeight()
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible ? 0 : 24)
            }
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                coordinator.reportMenuInsets(top: 180, bottom: height * 0.55)
            }

            switch coordinator.route {
            case .settings:
                SettingsView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .levels:
                LevelsView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .achievements:
                AchievementsView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .none:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: coordinator.route)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) { titleVisible = true }
        }
        .alert(loc.t(.menuNewGameConfirmTitle), isPresented: $coordinator.showNewGameConfirmation) {
            Button(loc.t(.commonCancel), role: .cancel) {}
            Button(loc.t(.menuNewGame), role: .destructive) { session.startNewAdventure() }
        } message: {
            Text(loc.t(.menuNewGameConfirmMessage))
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(loc.t(.appTitle))
                .font(Theme.title(40))
                .foregroundStyle(LinearGradient(colors: [Theme.parchment, Theme.gold], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.8), radius: 8, y: 4)
                .multilineTextAlignment(.center)
            Text(loc.t(.appSubtitle))
                .font(Theme.heading(15))
                .tracking(4)
                .foregroundStyle(Theme.gold.opacity(0.9))
                .shadow(color: .black.opacity(0.8), radius: 6, y: 2)
            Text(loc.t(.menuTagline))
                .font(Theme.body(14))
                .foregroundStyle(Theme.parchment.opacity(0.8))
                .shadow(color: .black.opacity(0.8), radius: 6, y: 2)
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            progressLine
            if session.canContinue {
                Button(loc.t(.menuContinue)) { session.playFromMenu() }
                    .buttonStyle(FantasyButtonStyle(kind: .primary))
                Button(loc.t(.menuNewGame)) { coordinator.showNewGameConfirmation = true }
                    .buttonStyle(FantasyButtonStyle(kind: .secondary))
            } else {
                Button(loc.t(.menuPlay)) { session.playFromMenu() }
                    .buttonStyle(FantasyButtonStyle(kind: .primary))
            }
            HStack(spacing: 12) {
                Button {
                    coordinator.route = .levels
                } label: {
                    Label(loc.t(.menuLevels), systemImage: "building.columns.fill")
                }
                .buttonStyle(FantasyButtonStyle(kind: .secondary, compact: true))
                Button {
                    coordinator.route = .achievements
                } label: {
                    Label(loc.t(.menuAchievements), systemImage: "rosette")
                }
                .buttonStyle(FantasyButtonStyle(kind: .secondary, compact: true))
                Button {
                    coordinator.route = .settings
                } label: {
                    Label(loc.t(.menuSettings), systemImage: "gearshape.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(FantasyButtonStyle(kind: .secondary, compact: true))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var progressLine: some View {
        HStack(spacing: 14) {
            if session.progress.isCampaignComplete {
                Label(loc.t(.menuEscaped, session.progress.timesEscaped), systemImage: "sunrise.fill")
            } else {
                Label(loc.t(.menuProgress, session.progress.currentFloor, FloorCatalog.topFloor), systemImage: "figure.stairs")
            }
            Label("\(session.progress.coins)", systemImage: "circle.hexagongrid.fill")
            Label("\(session.progress.starsEarned)", systemImage: "star.fill")
        }
        .font(Theme.body(13))
        .foregroundStyle(Theme.parchment.opacity(0.9))
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Capsule().fill(Theme.panel.opacity(0.75)))
        .overlay(Capsule().stroke(Theme.gold.opacity(0.5), lineWidth: 1))
    }
}

/// Three-line story intro shown before the first floor.
struct StoryIntroView: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @State private var revealed = 0

    private let lines: [L10nKey] = [.storyLine1, .storyLine2, .storyLine3]

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                ForEach(Array(lines.enumerated()), id: \.offset) { index, key in
                    Text(loc.t(key))
                        .font(Theme.heading(21))
                        .foregroundStyle(Theme.parchment)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(index < revealed ? 1 : 0)
                        .offset(y: index < revealed ? 0 : 14)
                }
                Spacer()
                HStack(spacing: 14) {
                    Button(loc.t(.storySkip)) { session.storyFinished() }
                        .buttonStyle(FantasyButtonStyle(kind: .secondary, compact: true))
                    Button(loc.t(.storyBegin)) { session.storyFinished() }
                        .buttonStyle(FantasyButtonStyle(kind: .primary, compact: true))
                        .opacity(revealed >= lines.count ? 1 : 0.4)
                        .disabled(revealed < lines.count)
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            for i in 0..<lines.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 1.6) {
                    withAnimation(.easeOut(duration: 0.7)) { revealed = i + 1 }
                }
            }
        }
    }
}
