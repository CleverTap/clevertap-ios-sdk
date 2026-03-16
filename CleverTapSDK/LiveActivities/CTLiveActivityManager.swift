#if canImport(ActivityKit)
import ActivityKit
#endif
import Foundation

// MARK: - UserDefaults key for persisting pushTokenTag ↔ activityID mapping across launches
private let kCTLATagMapKey = "CLTAP_LA_ACTIVITY_TAG_MAP"

// MARK: - Token monitoring timeout (20 minutes per TAN spec)
private let kCTLATokenTimeoutSeconds: TimeInterval = 20 * 60

/// Internal manager responsible for all Live Activity token observation and backend communication.
///
/// One `CTLiveActivityManager` instance is created per `CleverTap` instance and stored via
/// an associated object. All ActivityKit observation runs in Swift `Task`s so the manager
/// requires iOS 16.2+; the associated-object accessor guards against older OS versions.
@available(iOS 16.2, *)
final class CTLiveActivityManager: NSObject {

    // MARK: - State

    /// Weak reference to CleverTap for click-tracking event calls.
    private weak var cleverTap: CleverTap?

    /// Weak reference through the ObjC protocol for internal data event queuing.
    /// `CleverTap` conforms via `CleverTap+LiveActivities.h`/`.m` which can access
    /// the non-public `pushLiveActivityData:` ObjC method.
    private weak var dataQueue: (any CTLiveActivityDataQueue)?

    /// Active observation tasks keyed by `pushTokenTag` (local flow)
    /// or `"__pts__<activityTypeName>"` (push-to-start flow).
    private var tasks: [String: Task<Void, Never>] = [:]
    private let lock = NSLock()

    // MARK: - Init

    init(cleverTap: CleverTap) {
        self.cleverTap = cleverTap
        self.dataQueue = cleverTap as? CTLiveActivityDataQueue
    }

    deinit {
        cancelAllTasks()
    }

    // MARK: - Local Flow: launchActivity

    /// Starts observing push token updates and state changes for a Live Activity.
    ///
    /// - Parameters:
    ///   - pushTokenTag: Developer-supplied string that uniquely identifies this activity
    ///     campaign on the CleverTap backend (e.g. `"order-tracking-12345"`).
    ///   - activity: The `Activity<Attributes>` object returned by `Activity.request(...)`.
    func launchActivity<Attributes: ActivityAttributes>(
        pushTokenTag: String,
        activity: Activity<Attributes>
    ) {
        // Persist pushTokenTag ↔ activityID mapping for resume on next launch
        persistTagMapping(pushTokenTag: pushTokenTag, activityID: activity.id)
        cancelTask(for: pushTokenTag)

        let activityTypeName = String(describing: Attributes.self)

        let task = Task { [weak self] in
            guard let self = self else { return }

            // Send initial token if iOS already has one
            if let token = activity.pushToken {
                self.sendActivityToken(token, pushTokenTag: pushTokenTag, activityType: activityTypeName)
            } else {
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: no initial push token for tag '\(pushTokenTag)', monitoring…")
                // Timeout warning after 20 minutes with no token
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(kCTLATokenTimeoutSeconds * 1_000_000_000))
                    if !Task.isCancelled {
                        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: token timeout (20 min) reached for tag '\(pushTokenTag)'. Token may never have been received.")
                    }
                }
            }

            // Observe token updates and state changes concurrently
            await withTaskGroup(of: Void.self) { group in
                // Token rotation (Stories 1.3, 6.4)
                group.addTask { [weak self] in
                    for await token in activity.pushTokenUpdates {
                        guard let self = self, !Task.isCancelled else { break }
                        self.sendActivityToken(token, pushTokenTag: pushTokenTag, activityType: activityTypeName)
                    }
                }

                // Activity end (Story 1.3)
                group.addTask { [weak self] in
                    for await state in activity.activityStateUpdates {
                        guard let self = self, !Task.isCancelled else { break }
                        if state == .ended || state == .dismissed {
                            self.sendActivityEnded(pushTokenTag: pushTokenTag)
                            self.cancelTask(for: pushTokenTag)
                            self.removeTagMapping(for: activity.id)
                            break
                        }
                    }
                }
            }
        }

        setTask(task, for: pushTokenTag)
    }

    // MARK: - Local Flow: resumeActivities

    /// Re-attaches token monitoring to all currently running activities of a given type.
    /// Call this in `didFinishLaunchingWithOptions` to cover the case where the app was
    /// terminated while activities were still running.
    func resumeActivities<Attributes: ActivityAttributes>(activityType: Activity<Attributes>.Type) {
        let storedMap = storedTagMapping()
        for activity in Activity<Attributes>.activities {
            // Look up the original pushTokenTag the developer used when calling launchActivity.
            // Fall back to activity.id if no mapping was persisted.
            let pushTokenTag = storedMap[activity.id] ?? activity.id
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: resuming activity '\(activity.id)' with tag '\(pushTokenTag)'")
            launchActivity(pushTokenTag: pushTokenTag, activity: activity)
        }
    }

    // MARK: - Push-to-Start Flow: registerPushToStart

    /// Registers a Push-to-Start (PTS) capability with CleverTap.
    ///
    /// Starts observing `Activity<Attributes>.pushToStartTokenUpdates`. When a token
    /// arrives (or rotates), it is sent immediately to the CT backend so the backend
    /// can start activities on this device remotely.
    ///
    /// Must be called as early as possible in `didFinishLaunchingWithOptions` because
    /// iOS only generates PTS tokens during the first app launch after a device restart.
    ///
    /// - Parameters:
    ///   - activityType: The `Activity<Attributes>.Type` to register (e.g. `Activity<OrderActivityAttributes>.self`).
    ///   - name: A human-readable name for the activity type sent to the CT backend (e.g. `"OrderActivityAttributes"`).
    @available(iOS 17.2, *)
    func registerPushToStart<Attributes: ActivityAttributes>(
        activityType: Activity<Attributes>.Type,
        name: String
    ) {
        let taskKey = "__pts__\(name)"
        cancelTask(for: taskKey)

        let task = Task { [weak self] in
            for await token in Activity<Attributes>.pushToStartTokenUpdates {
                guard let self = self, !Task.isCancelled else { break }
                self.sendPushToStartToken(token, activityType: name)
            }
        }

        setTask(task, for: taskKey)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: registered push-to-start monitoring for type '\(name)'")
    }

    // MARK: - Click Tracking

    /// Records a `"Live Activity Clicked"` raised event.
    func recordLiveActivityClicked(pushTokenTag: String, activityType: String) {
        cleverTap?.recordEvent("Live Activity Clicked", withProps: [
            "push_token_tag": pushTokenTag,
            "activity_type": activityType,
            "platform": "iOS"
        ])
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: recorded 'Live Activity Clicked' for tag '\(pushTokenTag)'")
    }

    // MARK: - Private: backend communication

    private func sendActivityToken(_ tokenData: Data, pushTokenTag: String, activityType: String) {
        let tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
        let data: [AnyHashable: Any] = [
            "action": "set",
            "push_token_tag": pushTokenTag,
            "id": tokenHex,
            "type": "live_activity"
        ]
        dataQueue?.enqueueLiveActivityData(data)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent activity token for tag '\(pushTokenTag)'")
    }

    private func sendActivityEnded(pushTokenTag: String) {
        let data: [AnyHashable: Any] = [
            "action": "remove",
            "push_token_tag": pushTokenTag,
            "type": "live_activity"
        ]
        dataQueue?.enqueueLiveActivityData(data)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent activity-ended signal for tag '\(pushTokenTag)'")
    }

    private func sendPushToStartToken(_ tokenData: Data, activityType: String) {
        let tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
        let data: [AnyHashable: Any] = [
            "action": "register",
            "activity_type": activityType,
            "id": tokenHex,
            "type": "pts"
        ]
        dataQueue?.enqueueLiveActivityData(data)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent push-to-start token for type '\(activityType)'")
    }

    // MARK: - Private: task lifecycle

    private func setTask(_ task: Task<Void, Never>, for key: String) {
        lock.lock()
        tasks[key] = task
        lock.unlock()
    }

    private func cancelTask(for key: String) {
        lock.lock()
        tasks[key]?.cancel()
        tasks.removeValue(forKey: key)
        lock.unlock()
    }

    private func cancelAllTasks() {
        lock.lock()
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        lock.unlock()
    }

    // MARK: - Private: pushTokenTag ↔ activityID persistence

    private func persistTagMapping(pushTokenTag: String, activityID: String) {
        var map = storedTagMapping()
        map[activityID] = pushTokenTag
        UserDefaults.standard.set(map, forKey: kCTLATagMapKey)
    }

    private func removeTagMapping(for activityID: String) {
        var map = storedTagMapping()
        map.removeValue(forKey: activityID)
        UserDefaults.standard.set(map, forKey: kCTLATagMapKey)
    }

    private func storedTagMapping() -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: kCTLATagMapKey) as? [String: String] ?? [:]
    }
}
