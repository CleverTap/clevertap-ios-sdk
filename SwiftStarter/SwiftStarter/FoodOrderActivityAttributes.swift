#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// Static and dynamic data for the Food Order Live Activity.
///
/// - Static attributes are set once when the activity is created and never change.
/// - `ContentState` is updated as the order progresses through each stage.
@available(iOS 16.2, *)
struct FoodOrderActivityAttributes: ActivityAttributes {

    // MARK: - ContentState (dynamic — updated via Activity.update)

    struct ContentState: Codable, Hashable {
        /// Human-readable status message shown on the lock screen.
        var status: String
        /// Estimated delivery time displayed as a live countdown timer.
        var estimatedDelivery: Date
        /// Progress step index: 0 = Placed, 1 = Preparing, 2 = Picked Up, 3 = Delivered.
        var progressStep: Int
    }

    // MARK: - Static attributes

    /// Restaurant name shown in the Live Activity header.
    var restaurantName: String
    /// Short order summary (e.g. "2× Margherita, 1× Garlic Bread").
    var orderSummary: String
    /// Order identifier shown to the user.
    var orderId: String
}
#endif
