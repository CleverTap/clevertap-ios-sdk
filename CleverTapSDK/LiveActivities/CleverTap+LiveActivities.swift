#if canImport(ActivityKit)
import ActivityKit
#endif
import Foundation
import ObjectiveC

// MARK: - Associated object key for CTLiveActivityManager storage

private var kLiveActivityManagerKey: UInt8 = 0

// MARK: - CleverTap Swift Extension (Live Activities)

public extension CleverTap {

    // MARK: - Manager accessor

    /// Returns the `CTLiveActivityManager` associated with this CleverTap instance,
    /// creating one if it doesn't exist yet. Returns `nil` on iOS < 16.2.
    @available(iOS 16.2, *)
    internal var liveActivityManager: CTLiveActivityManager {
        if let existing = objc_getAssociatedObject(self, &kLiveActivityManagerKey) as? CTLiveActivityManager {
            return existing
        }
        let manager = CTLiveActivityManager(cleverTap: self)
        objc_setAssociatedObject(self, &kLiveActivityManagerKey, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return manager
    }

    // MARK: - Local Flow

    /// Registers a locally-started Live Activity with CleverTap and begins automatic
    /// token monitoring.
    ///
    /// Call this immediately after requesting an activity with `Activity<T>.request(...)`.
    /// The SDK will:
    /// - Send the current push token to the CT backend.
    /// - Observe `activity.pushTokenUpdates` and forward every new/rotated token automatically.
    /// - Observe `activity.activityStateUpdates` and signal the backend when the activity ends.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if #available(iOS 16.2, *) {
    ///     let activity = try Activity<OrderAttributes>.request(
    ///         attributes: attributes,
    ///         content: .init(state: initialState, staleDate: nil),
    ///         pushType: .token
    ///     )
    ///     CleverTap.sharedInstance()?.launchActivity("order-\(orderId)", activity: activity)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - pushTokenTag: A developer-supplied string that uniquely identifies this activity
    ///     on the CT backend (e.g. `"order-tracking-12345"`). Used by the server when calling
    ///     the CT Update/End Activity API.
    ///   - activity: The `Activity<Attributes>` object returned by `Activity.request(...)`.
    /// - Returns: The same `activity` object passed in, for optional chaining convenience.
    @available(iOS 16.2, *)
    @discardableResult
    func launchActivity<Attributes: ActivityAttributes>(
        _ pushTokenTag: String,
        activity: Activity<Attributes>
    ) -> Activity<Attributes>? {
        guard !pushTokenTag.isEmpty else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CleverTap.launchActivity: pushTokenTag must not be empty.")
            return nil
        }
        liveActivityManager.launchActivity(pushTokenTag: pushTokenTag, activity: activity)
        return activity
    }

    /// Re-attaches token monitoring to all currently running activities of a given type.
    ///
    /// Call this in `application(_:didFinishLaunchingWithOptions:)` so the SDK resumes
    /// observing activities that were active when the app was previously terminated.
    ///
    /// ## Example
    ///
    /// ```swift
    /// if #available(iOS 16.2, *) {
    ///     CleverTap.sharedInstance()?.resumeActivities(Activity<OrderAttributes>.self)
    /// }
    /// ```
    ///
    /// - Parameter activityType: The `Activity<Attributes>.Type` whose running instances
    ///   should be resumed (e.g. `Activity<OrderAttributes>.self`).
    @available(iOS 16.2, *)
    func resumeActivities<Attributes: ActivityAttributes>(_ activityType: Activity<Attributes>.Type) {
        liveActivityManager.resumeActivities(activityType: activityType)
    }

    // MARK: - Push-to-Start (Remote) Flow

    /// Registers a Push-to-Start capability with CleverTap.
    ///
    /// The SDK monitors `Activity<Attributes>.pushToStartTokenUpdates`. When a token
    /// is available (or rotates), it is sent immediately to the CT backend so the backend
    /// can start activities on this device without the user opening the app.
    ///
    /// **Call as early as possible** in `application(_:didFinishLaunchingWithOptions:)` —
    /// iOS only generates PTS tokens on the first launch after a device restart.
    ///
    /// The app's `ActivityAttributes` struct **must** conform to `CleverTapLiveActivityAttributes`
    /// and include the `cleverTapActivityId: String?` property. After iOS creates the activity
    /// remotely, the SDK reads this ID to map the update token back to the CT campaign.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // AppDelegate.swift
    /// if #available(iOS 17.2, *) {
    ///     CleverTap.sharedInstance()?.registerPushToStart(
    ///         Activity<OrderAttributes>.self,
    ///         name: "OrderAttributes"
    ///     )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - activityType: The `Activity<Attributes>.Type` to register PTS capability for.
    ///   - name: A stable string name for this activity type sent to the CT backend
    ///     (typically the struct name, e.g. `"OrderAttributes"`).
    @available(iOS 17.2, *)
    func registerPushToStart<Attributes: ActivityAttributes>(
        _ activityType: Activity<Attributes>.Type,
        name: String
    ) {
        guard !name.isEmpty else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CleverTap.registerPushToStart: name must not be empty.")
            return
        }
        liveActivityManager.registerPushToStart(activityType: activityType, name: name)
    }

    // MARK: - Click Tracking

    /// Records a `"Live Activity Clicked"` event and sends it to the CleverTap backend.
    ///
    /// This is the Swift implementation backing the ObjC declaration in
    /// `CleverTap+LiveActivities.h`. Keeping the implementation in Swift avoids
    /// importing the Swift-generated bridging header from the `.m` file.
    ///
    /// - Parameters:
    ///   - pushTokenTag: The same tag passed to `launchActivity(_:activity:)`.
    ///   - activityType: A string identifying the activity type (e.g. `"OrderAttributes"`).
    @objc func recordLiveActivityClicked(withTag pushTokenTag: String, activityType: String) {
        guard !pushTokenTag.isEmpty else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue,
                                  message: "CleverTap.recordLiveActivityClicked: pushTokenTag must not be empty.")
            return
        }
        guard !activityType.isEmpty else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue,
                                  message: "CleverTap.recordLiveActivityClicked: activityType must not be empty.")
            return
        }
        if #available(iOS 16.2, *) {
            liveActivityManager.recordLiveActivityClicked(pushTokenTag: pushTokenTag, activityType: activityType)
        } else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue,
                                  message: "CleverTap.recordLiveActivityClicked: Live Activities require iOS 16.2+.")
        }
    }
}
