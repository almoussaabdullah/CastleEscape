import Foundation
import Combine

/// Where an ad may be shown. Gameplay never shows ads while a puzzle is active.
enum AdPlacement: String {
    case continueAfterLoss
    case hint
    case doubleCoins
    case betweenFloors
}

enum AdResult: Equatable {
    case rewarded
    case dismissed
    case unavailable
}

/// Abstraction over any ad network. Gameplay code only talks to this protocol, which keeps
/// the eventual AdMob integration isolated in a single class.
protocol AdManaging: AnyObject {
    /// True when ads are switched off (premium mode or no SDK configured).
    var isAdFree: Bool { get set }
    func isRewardedAdReady(for placement: AdPlacement) -> Bool
    /// Presents a rewarded ad. `completion` is always called on the main thread.
    func showRewardedAd(for placement: AdPlacement, completion: @escaping (AdResult) -> Void)
    /// Presents an interstitial between floors (a no-op when ad-free). Always completes.
    func showInterstitial(for placement: AdPlacement, completion: @escaping () -> Void)
}

/// Simulated ad provider used by the first version. The rewarded flow presents an in-app
/// countdown sheet (see `RewardedAdSimulatorView`) instead of a real creative.
///
/// To integrate Google AdMob later, create `AdMobAdManager: AdManaging` that loads
/// `GADRewardedAd` / `GADInterstitialAd` with your own ad unit IDs and inject it in
/// `GameCoordinator` — nothing else needs to change.
final class MockAdManager: ObservableObject, AdManaging {
    @Published var isAdFree: Bool = false
    /// Published so the SwiftUI layer can present the simulated ad sheet.
    @Published var pendingRewarded: AdPlacement?

    private var rewardedCompletion: ((AdResult) -> Void)?
    /// Seconds the simulated ad "plays" before the reward can be claimed.
    let simulatedDuration: Int = 3

    func isRewardedAdReady(for placement: AdPlacement) -> Bool { true }

    func showRewardedAd(for placement: AdPlacement, completion: @escaping (AdResult) -> Void) {
        if isAdFree {
            // Premium players receive rewards without watching anything.
            DispatchQueue.main.async { completion(.rewarded) }
            return
        }
        rewardedCompletion = completion
        pendingRewarded = placement
    }

    func showInterstitial(for placement: AdPlacement, completion: @escaping () -> Void) {
        // Interstitials are intentionally silent in the mock so testing stays fast.
        DispatchQueue.main.async { completion() }
    }

    /// Called by the simulator sheet.
    func finishSimulatedAd(result: AdResult) {
        let completion = rewardedCompletion
        rewardedCompletion = nil
        pendingRewarded = nil
        DispatchQueue.main.async { completion?(result) }
    }
}
