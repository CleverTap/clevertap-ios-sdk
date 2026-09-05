#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Static and dynamic data for the Food Order Live Activity.
///
/// - Static attributes are set once when the activity is created and never change.
/// - `ContentState` is updated as the order progresses through each stage.
@available(iOS 16.2, *)
struct FoodOrderActivityAttributes: ActivityAttributes {

    // MARK: - ContentState (dynamic — updated via push "update")

    struct ContentState: Codable, Hashable {
        /// Human-readable status message shown on the lock screen.
        var status: String
        /// Estimated delivery time remaining, in **minutes**.
        var estimatedDelivery: Int
        /// Progress step index: 0 = Placed, 1 = Preparing, 2 = En Route, 3 = Delivered.
        var progressStep: Int
        /// CleverTap milestone id — **changes across start/update/end**, so it rides in
        /// `content-state` (the only field readable on update/end). The SDK reads it fresh on
        /// each event and merges it over the fixed `wzrk` from `attributes`.
        var wzrk_milestoneId: String?
    }

    // MARK: - CleverTap wzrk (FIXED fields, nested inside aps.attributes at START)
    //
    // The backend injects this `wzrk` object into `aps.attributes` on `event=start` (the only
    // part of a push-to-start payload the app can read, and immutable thereafter). It holds the
    // fields that DON'T change for the activity. `wzrk_id` is the CAMPAIGN id. The changing
    // milestone lives in `ContentState.wzrk_milestoneId` above. The SDK reads both generically.

    struct Wzrk: Codable, Hashable {
        var wzrk_activityId: String?
        var wzrk_activityType: Int?
        var wzrk_id: Int?   // campaign id
    }

    // MARK: - Static attributes

    /// Restaurant name shown in the Live Activity header.
    var restaurantName: String
    /// Short order summary (e.g. "2× Margherita, 1× Garlic Bread").
    var orderSummary: String
    /// Order identifier shown to the user.
    var orderId: String
    /// Fixed CleverTap campaign attribution, injected by the backend into `aps.attributes` at start.
    var wzrk: Wzrk?
}
#endif
