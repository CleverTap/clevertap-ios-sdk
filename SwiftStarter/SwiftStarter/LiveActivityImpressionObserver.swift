#if canImport(ActivityKit)
import ActivityKit
#endif
import Foundation
import CleverTapSDK

/// Observes Food Order Live Activities and reports a CleverTap impression the moment each
/// activity is shown (state `.active`).
///
/// Impression is an opt-in client-side API, so the host app owns *when* to call it. ActivityKit
/// exposes no literal "shown on screen" callback, so `.active` — the state in which iOS presents
/// the activity on the Lock Screen / Dynamic Island — is used as the proxy for "shown".
///
/// The app does **not** need to track which activities have already been reported: the SDK
/// de-duplicates `recordLiveActivityImpression(_:)` to one impression per activity (persisted
/// across launches), so calling it on every `.active` transition / relaunch is safe.
///
/// Start it once at launch (see `AppDelegate`). It covers activities the backend starts while the
/// app is running as well as any already running when the app launches.
@available(iOS 16.2, *)
final class LiveActivityImpressionObserver {

    static let shared = LiveActivityImpressionObserver()
    private init() {}

    func start() {
        // Already-running activities at launch.
        for activity in Activity<FoodOrderActivityAttributes>.activities {
            recordImpressionIfShown(activity)
            observeState(of: activity)
        }
        // Activities the backend starts while the app is alive.
        Task { [weak self] in
            for await activity in Activity<FoodOrderActivityAttributes>.activityUpdates {
                self?.recordImpressionIfShown(activity)
                self?.observeState(of: activity)
            }
        }
    }

    private func observeState(of activity: Activity<FoodOrderActivityAttributes>) {
        Task { [weak self] in
            for await state in activity.activityStateUpdates {
                if state == .active { self?.recordImpressionIfShown(activity) }
            }
        }
    }

    /// Fires the impression public API when the activity is on screen. The SDK de-dupes, so this
    /// can be called repeatedly (e.g. on every relaunch) without sending duplicate impressions.
    private func recordImpressionIfShown(_ activity: Activity<FoodOrderActivityAttributes>) {
        guard activity.activityState == .active else { return }
        // The SDK reads the `wzrk` from the activity itself (attributes + current content-state),
        // so the app doesn't build the dict and doesn't conform to any CleverTap protocol.
        CleverTap.sharedInstance()?.recordLiveActivityImpression(activity)
    }
}
