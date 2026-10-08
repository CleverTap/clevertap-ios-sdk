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
        /// CleverTap per-send render/push id. The backend puts this in `content-state` (it
        /// changes on every push), so it is captured here — not in the fixed `wzrk` below.
        var wzrk_pid: String?
    }

    // MARK: - CleverTap wzrk (FIXED fields, nested inside aps.attributes at START)
    //
    // The backend injects this `wzrk` object into `aps.attributes` on `event=start` (the only
    // part of a push-to-start payload the app can read, and immutable thereafter). It holds the
    // fields that DON'T change for the activity. The changing per-state fields (milestone id,
    // per-send push id) live in `ContentState` above. The SDK reads both generically.
    //
    // Declare EVERY wzrk field the backend injects here. `ActivityAttributes` is a typed Codable
    // struct, so any key NOT declared is dropped on decode and will be missing from the
    // impression/click payload — AND a declared type that mismatches the JSON (e.g. Int vs a
    // String value) makes the WHOLE attributes decode throw, so the activity fails to start.
    //   wzrk_id       – campaign id. Composite STRING, e.g. "1784798893_20260916" (push: W$id).
    //   wzrk_acct_id  – account id; used by the SDK to HARD-VALIDATE the calling instance
    //                   (event is dropped if it records on a different account).
    //   wzrk_activityId / wzrk_activityType – Live Activity ids.
    //   wzrk_rnv      – "raised not viewed" flag. The backend sends it as `W$rnv`; a plain
    //                   `CodingKeys` raw value maps that JSON key onto the `wzrk_rnv` property, so
    //                   Codable synthesis (no custom init) handles it. The SDK normalizes any
    //                   remaining `W$…` keys to `wzrk_…` when it builds the event payload.
    struct Wzrk: Codable, Hashable {
        var wzrk_activityId: String?
        var wzrk_activityType: Int?
        var wzrk_id: String?       // campaign id — composite string, e.g. "1784798893_20260916"
        var wzrk_acct_id: String?  // account id (multi-instance validation)
        var wzrk_rnv: Bool?        // JSON key is "W$rnv" (mapped below)

        enum CodingKeys: String, CodingKey {
            case wzrk_activityId, wzrk_activityType, wzrk_id, wzrk_acct_id
            case wzrk_rnv = "W$rnv"   // map the backend's "W$rnv" JSON key onto this property
        }
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
