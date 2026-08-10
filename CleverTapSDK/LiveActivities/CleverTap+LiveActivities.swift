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
    /// The app's `ActivityAttributes` struct only needs to include a `wzrk` object (populated by
    /// the backend in `aps.attributes`) — no CleverTap protocol conformance is required. The SDK
    /// reads `wzrk` from the activity's attributes via `Codable` for event attribution.
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

    // MARK: - Client-side event APIs (impression & click)
    //
    // Push impression and notification-click are front-end events the customer raises when
    // appropriate (e.g. from the Live Activity's deep-link handler / widget interaction).
    // They are opt-in: if the app does not call them, the events are not raised.

    /// Records a Live Activity push impression. Behaves exactly like a push "Notification
    /// Viewed" event — the `wzrk` dictionary from the activity payload becomes the event data.
    ///
    /// - Parameter wzrk: The `wzrk` campaign dictionary present in the activity payload
    ///   (e.g. `activityId`, `activityType`, `campaignId`, `milestoneId`).
    @objc func recordLiveActivityImpression(wzrk: [AnyHashable: Any]) {
        guard !wzrk.isEmpty else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue,
                                  message: "CleverTap.recordLiveActivityImpression: wzrk must not be empty.")
            return
        }
        if #available(iOS 16.2, *) {
            liveActivityManager.recordLiveActivityImpression(wzrk: wzrk)
        } else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue,
                                  message: "CleverTap.recordLiveActivityImpression: Live Activities require iOS 16.2+.")
        }
    }

    /// Records a Live Activity click. Behaves exactly like a push "Notification Clicked" event —
    /// the `wzrk` dictionary from the activity payload becomes the event data.
    ///
    /// - Parameter wzrk: The `wzrk` campaign dictionary present in the activity payload.
    @objc func recordLiveActivityClicked(wzrk: [AnyHashable: Any]) {
        guard !wzrk.isEmpty else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue,
                                  message: "CleverTap.recordLiveActivityClicked: wzrk must not be empty.")
            return
        }
        if #available(iOS 16.2, *) {
            liveActivityManager.recordLiveActivityClicked(wzrk: wzrk)
        } else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue,
                                  message: "CleverTap.recordLiveActivityClicked: Live Activities require iOS 16.2+.")
        }
    }

    // MARK: - Convenience overloads (extract wzrk from the activity automatically)
    //
    // The SDK reads the `wzrk` object from the activity's attributes (via Codable) — the app's
    // `ActivityAttributes` does NOT need to conform to any CleverTap protocol; it only needs a
    // `wzrk` field the backend populates in `aps.attributes`.

    /// Records a Live Activity push impression, reading the `wzrk` data from the activity itself.
    @available(iOS 16.2, *)
    func recordLiveActivityImpression<Attributes: ActivityAttributes>(_ activity: Activity<Attributes>) {
        liveActivityManager.recordLiveActivityImpression(activity: activity)
    }

    /// Records a Live Activity click, reading the `wzrk` data from the activity itself.
    @available(iOS 16.2, *)
    func recordLiveActivityClicked<Attributes: ActivityAttributes>(_ activity: Activity<Attributes>) {
        liveActivityManager.recordLiveActivityClicked(activity: activity)
    }
}
