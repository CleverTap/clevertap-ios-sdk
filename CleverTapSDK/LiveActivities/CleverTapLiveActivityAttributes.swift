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
/// - Note: The app's `ActivityAttributes` should conform to this protocol so the SDK can read
///   the backend-injected identifiers for the Push-to-Start flow (`registerPushToStart(_:name:)`).
public protocol CleverTapLiveActivityAttributes {
    /// The CleverTap activity identifier injected by the backend into the
    /// push-to-start APNs payload. The SDK reads this value from running
    /// activities so it can register their update tokens under the correct
    /// campaign ID.
    ///
    /// - Important: Do **not** rename this property. The SDK accesses it by
    ///   its exact name via the protocol. The conforming type may back it with a
    ///   stored property or a computed one (e.g. mapped from a nested `wzrk` object).
    var cleverTapActivityId: String? { get }

    /// The numeric activity-type code from the backend `wzrk` payload (`wzrk.activityType`). Optional.
    var cleverTapActivityType: Int? { get }

    /// The CleverTap milestone identifier from the backend `wzrk` payload (`wzrk.milestoneId`). Optional.
    var cleverTapMilestoneId: String? { get }

    /// The CleverTap campaign identifier from the backend `wzrk` payload (`wzrk.campaignId`). Optional.
    var cleverTapCampaignId: Int? { get }
}

public extension CleverTapLiveActivityAttributes {
    // Defaults so existing conformers (and the Local testing flow) don't have to
    // declare these; the Push-to-Start payload populates them when present. The SDK
    // assembles these into the `wzrk` dictionary it sends on every Live Activity event.
    var cleverTapActivityType: Int? { nil }
    var cleverTapMilestoneId: String? { nil }
    var cleverTapCampaignId: Int? { nil }
}
