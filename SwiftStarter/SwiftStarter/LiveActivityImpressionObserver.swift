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
/// Start it once at launch (see `AppDelegate`). It covers activities the backend starts while the
/// app is running as well as any already running when the app launches.
@available(iOS 16.2, *)
final class LiveActivityImpressionObserver {

    static let shared = LiveActivityImpressionObserver()
    private init() {}

    /// Activity ids we've already reported an impression for this app session (dedupe).
    private var recordedActivityIDs = Set<String>()
    private let lock = NSLock()

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

    /// Fires the impression public API once per activity (this session) when it is on screen.
    private func recordImpressionIfShown(_ activity: Activity<FoodOrderActivityAttributes>) {
        guard activity.activityState == .active else { return }
        let key = activity.id

        lock.lock()
        let alreadyRecorded = recordedActivityIDs.contains(key)
        if !alreadyRecorded { recordedActivityIDs.insert(key) }
        lock.unlock()
        guard !alreadyRecorded else { return }

        // Build the wzrk dict from the actual fields the backend injected into the activity's
        // attributes (NOT hardcoded). Whatever wzrk fields are present are forwarded as-is.
        let wzrk = Self.wzrk(from: activity.attributes)
        CleverTap.sharedInstance()?.recordLiveActivityImpression(wzrk: wzrk)
        NSLog("LiveActivityImpressionObserver: recorded impression (shown) with wzrk %@", wzrk)
    }

    /// Assembles the `wzrk` dictionary from the activity's attributes, including only the fields
    /// the backend actually provided.
    private static func wzrk(from attributes: FoodOrderActivityAttributes) -> [AnyHashable: Any] {
        guard let w = attributes.wzrk else { return [:] }
        var wzrk: [AnyHashable: Any] = [:]
        if let activityId = w.wzrk_activityId { wzrk["wzrk_activityId"] = activityId }
        if let activityType = w.wzrk_activityType { wzrk["wzrk_activityType"] = activityType }
        if let milestoneId = w.wzrk_milestoneId { wzrk["wzrk_milestoneId"] = milestoneId }
        if let campaignId = w.wzrk_id { wzrk["wzrk_id"] = campaignId }  // wzrk_id = campaign id
        return wzrk
    }
}
