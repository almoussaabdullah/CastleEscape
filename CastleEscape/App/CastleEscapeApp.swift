import SwiftUI

@main
struct CastleEscapeApp: App {
    @StateObject private var coordinator = GameCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .environmentObject(coordinator.session)
                .environmentObject(coordinator.localization)
                .environmentObject(coordinator.ads)
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background, .inactive:
                        coordinator.didEnterBackground()
                    case .active:
                        coordinator.willEnterForeground()
                    @unknown default:
                        break
                    }
                }
        }
    }
}
