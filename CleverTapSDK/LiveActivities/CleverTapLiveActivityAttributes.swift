/// Protocol that an app's `ActivityAttributes` struct must conform to when using
/// the **Push-to-Start (Remote)** Live Activities flow with CleverTap.
///
/// The SDK embeds the `cleverTapActivityId` into the initial `attributes` payload
/// of the push-to-start APNs notification so that — after iOS creates the activity
/// remotely — the SDK can read this ID back from the running activity and map its
/// update token to the correct CT campaign.
///
/// ## Implementation
///
/// ```swift
/// import ActivityKit
/// import CleverTapSDK
///
/// @available(iOS 16.1, *)
/// struct OrderActivityAttributes: ActivityAttributes, CleverTapLiveActivityAttributes {
///
///     public struct ContentState: Codable, Hashable {
///         var status: String
///         var estimatedTime: String
///     }
///
///     var orderNumber: String
///
///     // Required by CleverTapLiveActivityAttributes — DO NOT rename this property.
///     var cleverTapActivityId: String?
/// }
/// ```
///
/// - Note: This protocol is required only for the Push-to-Start flow
///   (`registerPushToStart(_:name:)`). It is **not** required for the Local
///   flow (`launchActivity(_:activity:)`).
public protocol CleverTapLiveActivityAttributes {
    /// The CleverTap activity identifier injected by the backend into the
    /// push-to-start APNs payload. The SDK reads this value from running
    /// activities so it can register their update tokens under the correct
    /// campaign ID.
    ///
    /// - Important: Do **not** rename this property. The SDK accesses it by
    ///   its exact name via the protocol.
    var cleverTapActivityId: String? { get set }
}
