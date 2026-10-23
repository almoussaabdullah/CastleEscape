import SwiftUI

/// Dimmed backdrop shared by modal cards.
struct ModalBackdrop<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            ParchmentPanel { content }
                .padding(.horizontal, 24)
        }
    }
}

struct PauseView: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        ModalBackdrop {
            VStack(spacing: 14) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.gold)
                Text(loc.t(.pauseTitle))
                    .font(Theme.title(30))
                    .foregroundStyle(Theme.parchment)
                Button(loc.t(.pauseResume)) { session.resume() }
                    .buttonStyle(FantasyButtonStyle(kind: .primary))
                Button(loc.t(.pauseRestart)) {
                    session.resume()
                    session.retryFloor()
                }
                .buttonStyle(FantasyButtonStyle(kind: .secondary))
                Button(loc.t(.pauseQuit)) {
                    session.resume()
                    session.returnToMenu()
                }
                .buttonStyle(FantasyButtonStyle(kind: .danger))
            }
        }
    }
}

struct GameOverView: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @State private var appeared = false

    var body: some View {
        ModalBackdrop {
            VStack(spacing: 14) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.danger)
                    .rotationEffect(.degrees(appeared ? 0 : -20))
                    .scaleEffect(appeared ? 1 : 0.4)
                Text(loc.t(.gameoverTitle))
                    .font(Theme.title(28))
                    .foregroundStyle(Theme.parchment)
                    .multilineTextAlignment(.center)
                Text(loc.t(.gameoverSubtitle))
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.parchment.opacity(0.8))
                    .multilineTextAlignment(.center)
                Button(loc.t(.gameoverRetry)) { session.retryFloor() }
                    .buttonStyle(FantasyButtonStyle(kind: .primary))
                VStack(spacing: 4) {
                    Button {
                        session.continueAfterLoss()
                    } label: {
                        Label(loc.t(.gameoverExtra), systemImage: "play.rectangle.fill")
                    }
                    .buttonStyle(FantasyButtonStyle(kind: .secondary))
                    Text(loc.t(.gameoverExtraHint))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.parchment.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                Button(loc.t(.gameoverCastle)) { session.returnToMenu() }
                    .buttonStyle(FantasyButtonStyle(kind: .danger))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) { appeared = true }
        }
    }
}

struct FloorClearedView: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @State private var starsShown = 0

    var body: some View {
        VStack {
            Spacer()
            if let summary = session.floorSummary {
                ParchmentPanel {
                    VStack(spacing: 12) {
                        Text(loc.t(.transitionFloorCleared))
                            .font(Theme.title(26))
                            .foregroundStyle(Theme.gold)
                        Text(loc.t(FloorCatalog.floor(summary.floor).name))
                            .font(Theme.heading(18))
                            .foregroundStyle(Theme.parchment)
                        StarsView(stars: min(summary.stars, starsShown), size: 34)
                        HStack(spacing: 18) {
                            stat(icon: "star.circle.fill", value: "\(summary.score)", label: loc.t(.hudScore))
                            stat(icon: "circle.hexagongrid.fill", value: loc.t(.transitionCoins, summary.coins), label: loc.t(.commonCoins))
                            stat(icon: "clock.fill", value: DurationFormatter.string(summary.time), label: loc.t(.victoryTime))
                        }
                        if let next = summary.nextFloor {
                            Button(loc.t(.transitionDescending, next)) { session.continueAfterFloor() }
                                .buttonStyle(FantasyButtonStyle(kind: .primary))
                        } else {
                            Button(loc.t(.transitionBackToCastle)) { session.continueAfterFloor() }
                                .buttonStyle(FantasyButtonStyle(kind: .primary))
                        }
                        Button {
                            session.doubleCoinsAfterFloor()
                        } label: {
                            Label(loc.t(.transitionDoubleCoins), systemImage: "play.rectangle.fill")
                        }
                        .buttonStyle(FantasyButtonStyle(kind: .secondary, compact: true))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            starsShown = 0
            for i in 1...3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { starsShown = i }
                    if i <= (session.floorSummary?.stars ?? 0) { AudioManager.shared.play(.tick) }
                }
            }
        }
    }

    private func stat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).foregroundStyle(Theme.gold)
            Text(value).font(Theme.mono(16)).foregroundStyle(Theme.parchment)
            Text(label).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(Theme.parchment.opacity(0.6))
        }
    }
}

struct VictoryView: View {
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager
    @State private var visible = false

    var body: some View {
        VStack {
            Spacer()
            if let summary = session.victorySummary {
                ParchmentPanel {
                    VStack(spacing: 12) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.gold)
                        Text(loc.t(.victoryTitle))
                            .font(Theme.title(28))
                            .foregroundStyle(Theme.parchment)
                            .multilineTextAlignment(.center)
                        Text(loc.t(.victorySubtitle))
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.parchment.opacity(0.8))
                            .multilineTextAlignment(.center)
                        VStack(spacing: 8) {
                            row(loc.t(.victoryScore), "\(summary.score)")
                            row(loc.t(.victoryPuzzles), "\(summary.puzzlesSolved)")
                            row(loc.t(.victoryAccuracy), "\(Int((summary.accuracy * 100).rounded()))%")
                            row(loc.t(.victoryTime), DurationFormatter.string(summary.totalTime))
                            row(loc.t(.victoryStars), "\(summary.stars) / \(FloorCatalog.floors.count * 3)")
                        }
                        .padding(.vertical, 6)
                        Button(loc.t(.victoryReplay)) { session.restartFromVictory() }
                            .buttonStyle(FantasyButtonStyle(kind: .primary))
                        Button(loc.t(.victoryMenu)) { session.returnToMenu() }
                            .buttonStyle(FantasyButtonStyle(kind: .secondary))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) { visible = true }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.body(15)).foregroundStyle(Theme.parchment.opacity(0.8))
            Spacer()
            Text(value).font(Theme.mono(17)).foregroundStyle(Theme.gold)
        }
    }
}

/// In-app stand-in for a rewarded ad: a countdown, then a claim button.
struct RewardedAdSimulatorView: View {
    let placement: AdPlacement
    @EnvironmentObject private var ads: MockAdManager
    @EnvironmentObject private var loc: LocalizationManager
    @State private var secondsLeft: Int = 3
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.gold)
                Text(loc.t(.adTitle))
                    .font(Theme.title(26))
                    .foregroundStyle(Theme.parchment)
                Text(loc.t(.adBody))
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.parchment.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                if secondsLeft > 0 {
                    Text(loc.t(.adCountdown, secondsLeft))
                        .font(Theme.mono(20))
                        .foregroundStyle(Theme.gold)
                        .contentTransition(.numericText())
                } else {
                    Button(loc.t(.adClaim)) { ads.finishSimulatedAd(result: .rewarded) }
                        .buttonStyle(FantasyButtonStyle(kind: .primary))
                        .padding(.horizontal, 30)
                }
                Button(loc.t(.adClose)) { ads.finishSimulatedAd(result: .dismissed) }
                    .buttonStyle(FantasyButtonStyle(kind: .secondary, compact: true))
            }
            .padding(30)
        }
        .onAppear {
            secondsLeft = ads.simulatedDuration
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if secondsLeft > 0 { withAnimation { secondsLeft -= 1 } }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}
