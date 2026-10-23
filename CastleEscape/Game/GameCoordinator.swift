import Combine
import SpriteKit
import SwiftUI

/// Wires the SwiftUI layer, the game session and the SpriteKit scene together.
final class GameCoordinator: ObservableObject {
    enum Route: Equatable {
        case none, settings, levels, achievements
    }

    let scene: CastleScene
    let session: GameSession
    let localization: LocalizationManager
    let ads: MockAdManager

    @Published var route: Route = .none
    @Published var showNewGameConfirmation = false
    @Published var showResetConfirmation = false

    private var cancellables: Set<AnyCancellable> = []

    init() {
        localization = LocalizationManager.shared
        ads = MockAdManager()
        scene = CastleScene(size: UIScreen.main.bounds.size)
        session = GameSession(ads: ads, localization: localization)
        session.director = scene
        AudioManager.shared.prepare()
        session.start()
        AudioManager.shared.startMusic()

        // Re-publish nested object changes so views observing the coordinator refresh.
        session.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        ads.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
    }

    // MARK: - App lifecycle

    func didEnterBackground() {
        session.saveNow()
        if session.phase == .playing || session.phase == .resolving {
            session.pause()
        }
        AudioManager.shared.stopMusic()
    }

    func willEnterForeground() {
        if session.settings.musicEnabled { AudioManager.shared.startMusic() }
    }

    // MARK: - Insets reported by the UI

    func reportGameplayInsets(top: CGFloat, bottom: CGFloat) {
        scene.updateGameplayInsets(top: top, bottom: bottom)
    }

    func reportMenuInsets(top: CGFloat, bottom: CGFloat) {
        scene.updateMenuInsets(top: top, bottom: bottom)
    }
}
