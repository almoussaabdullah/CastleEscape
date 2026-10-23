import SwiftUI

/// Shared chrome for the sub-screens opened from the main menu.
struct MenuSheet<Content: View>: View {
    let title: String
    let onClose: () -> Void
    let content: Content

    init(title: String, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(Theme.title(26))
                        .foregroundStyle(Theme.gold)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Theme.parchment)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Theme.panelLight))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 10)
                ScrollView {
                    content
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Theme.panel.opacity(0.96))
            )
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(Theme.gold.opacity(0.7), lineWidth: 2))
            .padding(.horizontal, 14)
            .padding(.vertical, 40)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        MenuSheet(title: loc.t(.settingsTitle), onClose: { coordinator.route = .none }) {
            VStack(spacing: 18) {
                section(loc.t(.settingsLanguage)) {
                    HStack(spacing: 10) {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                session.settings.language = language
                            } label: {
                                Text(language.nativeName)
                                    .font(Theme.body(16))
                                    .foregroundStyle(session.settings.language == language ? Theme.ink : Theme.parchment)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(session.settings.language == language ? Theme.gold : Theme.panelLight))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                section(loc.t(.settingsAudio)) {
                    toggle(loc.t(.settingsMusic), icon: "music.note", isOn: $session.settings.musicEnabled)
                    toggle(loc.t(.settingsSfx), icon: "speaker.wave.2.fill", isOn: $session.settings.soundEffectsEnabled)
                    toggle(loc.t(.settingsHaptics), icon: "iphone.radiowaves.left.and.right", isOn: $session.settings.hapticsEnabled)
                }
                section(loc.t(.settingsPremium)) {
                    toggle(loc.t(.settingsPremium), icon: "crown.fill", isOn: $session.settings.isPremium)
                    Text(loc.t(.settingsPremiumHint))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.parchment.opacity(0.6))
                }
                Button(loc.t(.settingsReset)) { coordinator.showResetConfirmation = true }
                    .buttonStyle(FantasyButtonStyle(kind: .danger))
                VStack(spacing: 4) {
                    Text(loc.t(.settingsVersion, Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                    Text(loc.t(.settingsAbout))
                        .multilineTextAlignment(.center)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.parchment.opacity(0.55))
            }
            .onChange(of: session.settings.musicEnabled) { _, enabled in
                if enabled { AudioManager.shared.startMusic() }
            }
        }
        .alert(loc.t(.settingsResetTitle), isPresented: $coordinator.showResetConfirmation) {
            Button(loc.t(.commonCancel), role: .cancel) {}
            Button(loc.t(.settingsReset), role: .destructive) { session.resetAllProgress() }
        } message: {
            Text(loc.t(.settingsResetMessage))
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Theme.heading(16))
                .foregroundStyle(Theme.gold)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.panelLight.opacity(0.45)))
    }

    private func toggle(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: icon)
                .font(Theme.body(16))
                .foregroundStyle(Theme.parchment)
        }
        .tint(Theme.gold)
    }
}

struct LevelsView: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        MenuSheet(title: loc.t(.levelsTitle), onClose: { coordinator.route = .none }) {
            VStack(spacing: 10) {
                ForEach(FloorCatalog.playOrder) { floor in
                    floorRow(floor)
                }
            }
        }
    }

    private func floorRow(_ floor: FloorDefinition) -> some View {
        let status = session.progress.status(ofFloor: floor.number)
        let playable: Bool
        switch status {
        case .locked: playable = false
        case .current, .completed: playable = true
        }
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(playable ? Theme.gold : Theme.panelLight)
                Text("\(floor.number)")
                    .font(Theme.heading(18))
                    .foregroundStyle(playable ? Theme.ink : Theme.parchment.opacity(0.5))
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(loc.t(floor.name))
                    .font(Theme.heading(16))
                    .foregroundStyle(playable ? Theme.parchment : Theme.parchment.opacity(0.5))
                HStack(spacing: 8) {
                    Text(loc.t(.levelsPuzzles, floor.encounterCount))
                    if case .completed = status, let result = session.progress.completedFloors[floor.number] {
                        Text(loc.t(.levelsBestScore, result.bestScore))
                    }
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.parchment.opacity(0.6))
                if case .completed(let stars) = status {
                    StarsView(stars: stars, size: 14)
                }
            }
            Spacer()
            switch status {
            case .locked:
                Image(systemName: "lock.fill").foregroundStyle(Theme.parchment.opacity(0.4))
            case .current:
                Button(loc.t(.levelsPlay)) {
                    coordinator.route = .none
                    session.replayFloor(floor.number)
                }
                .buttonStyle(FantasyButtonStyle(kind: .primary, compact: true))
            case .completed:
                Button(loc.t(.levelsReplay)) {
                    coordinator.route = .none
                    session.replayFloor(floor.number)
                }
                .buttonStyle(FantasyButtonStyle(kind: .secondary, compact: true))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.panelLight.opacity(playable ? 0.5 : 0.25)))
    }
}

struct AchievementsView: View {
    @EnvironmentObject private var coordinator: GameCoordinator
    @EnvironmentObject private var session: GameSession
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        MenuSheet(title: loc.t(.achievementsTitle), onClose: { coordinator.route = .none }) {
            VStack(spacing: 10) {
                Text(loc.t(.achievementsUnlocked, session.progress.achievements.count, Achievement.all.count))
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.parchment.opacity(0.7))
                ForEach(Achievement.all) { achievement in
                    let unlocked = session.progress.achievements.contains(achievement.id)
                    HStack(spacing: 12) {
                        Image(systemName: achievement.systemImageName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(unlocked ? Theme.gold : Theme.parchment.opacity(0.35))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Theme.panelLight))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(loc.t(achievement.title))
                                .font(Theme.heading(16))
                                .foregroundStyle(unlocked ? Theme.parchment : Theme.parchment.opacity(0.5))
                            Text(unlocked ? loc.t(achievement.detail) : loc.t(.achievementsLocked) + " · " + loc.t(achievement.detail))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.parchment.opacity(0.6))
                        }
                        Spacer()
                        if unlocked {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.success)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.panelLight.opacity(unlocked ? 0.5 : 0.25)))
                }
            }
        }
    }
}
