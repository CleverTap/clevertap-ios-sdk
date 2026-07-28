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
        /// Estimated delivery time remaining, in **minutes** (plain Int — avoids the
        /// Date/epoch encoding gotcha in push payloads).
        var estimatedDelivery: Int
        /// Progress step index: 0 = Placed, 1 = Preparing, 2 = En Route, 3 = Delivered.
        var progressStep: Int
    }

    // MARK: - Static attributes

    /// Restaurant name shown in the Live Activity header.
    var restaurantName: String
    /// Short order summary (e.g. "2× Margherita, 1× Garlic Bread").
    var orderSummary: String
    /// Order identifier shown to the user.
    var orderId: String

    /// CleverTap activity identifier injected by the backend into the push-to-start payload.
    /// Required by the Push-to-Start flow so the SDK can map this activity's update token to
    /// the correct CT campaign. Conformance to `CleverTapLiveActivityAttributes` is declared in
    /// the app target (see `LiveActivitiesViewController.swift`) so this shared file stays free
    /// of a CleverTapSDK import (the widget extension compiles it too).
    var cleverTapActivityId: String?
}
#endif
