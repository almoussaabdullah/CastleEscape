import SpriteKit
import SwiftUI

/// Hosts the SpriteKit world full-screen and layers the SwiftUI screens on top of it.
struct RootView: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var ads: MockAdManager

    var body: some View {
        ZStack {
            SpriteView(scene: coordinator.scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            overlay
                .animation(.easeInOut(duration: 0.35), value: session.phase)

            if let achievement = session.achievementToast {
                AchievementToast(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(50)
            }

            if let placement = ads.pendingRewarded {
                RewardedAdSimulatorView(placement: placement)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .environment(\.layoutDirection, loc.language.layoutDirection)
        .environment(\.locale, loc.language.locale)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .animation(.easeInOut(duration: 0.3), value: session.achievementToast?.id)
        .animation(.easeInOut(duration: 0.3), value: ads.pendingRewarded)
    }

    @ViewBuilder
    private var overlay: some View {
        switch session.phase {
        case .menu:
            MainMenuView()
                .transition(.opacity)
        case .story:
            StoryIntroView()
                .transition(.opacity)
        case .entering:
            FloorTitleOverlay()
                .transition(.opacity)
        case .playing, .resolving:
            GameplayOverlay()
                .transition(.opacity)
        case .paused:
            ZStack {
                GameplayOverlay()
                PauseView()
            }
            .transition(.opacity)
        case .floorCleared:
            FloorClearedView()
                .transition(.opacity)
        case .gameOver:
            ZStack {
                GameplayOverlay()
                GameOverView()
            }
            .transition(.opacity)
        case .victory:
            VictoryView()
                .transition(.opacity)
        }
    }
}

/// Floor name and tagline shown while the camera flies into the window.
struct FloorTitleOverlay: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @State private var visible = false

    var body: some View {
        VStack {
            Spacer()
            if let floor = session.currentFloor {
                VStack(spacing: 10) {
                    Text(loc.t(.transitionEnteringFloor, floor.number))
                        .font(Theme.heading(18))
                        .foregroundStyle(Theme.gold)
                        .tracking(2)
                    Text(loc.t(floor.name))
                        .font(Theme.title(38))
                        .foregroundStyle(Theme.parchment)
                        .shadow(color: .black, radius: 10)
                    Text(loc.t(floor.tagline))
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.parchment.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom))
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 20)
            }
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) { visible = true }
        }
    }
}

/// Small banner announcing an unlocked achievement.
struct AchievementToast: View {
    let achievement: Achievement
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: achievement.systemImageName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.t(.achievementsToast, loc.t(achievement.title)))
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.parchment)
                    Text(loc.t(achievement.detail))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.parchment.opacity(0.75))
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.panel.opacity(0.95)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.gold, lineWidth: 1.5))
            .padding(.horizontal, 20)
            .padding(.top, 8)
            Spacer()
        }
    }
}
