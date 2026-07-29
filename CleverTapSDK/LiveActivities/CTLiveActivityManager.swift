#if canImport(ActivityKit)
import ActivityKit
#endif
import Foundation

// MARK: - UserDefaults key for persisting tracked activities across launches
// Stores [activityID: { cleverTapActivityId, activityName, wzrk(JSON), started }] so that, on
// the next launch, activities that vanished while the app was terminated (dismissed / ended /
// expired) can be reported, and so the "Started" state is not re-raised for an already-reported one.
private let kCTLAActivityStoreKey = "CLTAP_LA_ACTIVITY_STORE"

// Keys used inside each persisted activity record.
private let kCTLAStoreCleverTapActivityId = "cleverTapActivityId"
private let kCTLAStoreActivityName = "activityName"
private let kCTLAStoreWzrk = "wzrk"
private let kCTLAStoreStarted = "started"

// MARK: - Live Activity lifecycle event
// The four lifecycle stages are sent as a SINGLE event named "Live Activity"; the stage is carried
// in a `state` field inside evtData. Sent through the internal "Notification Viewed" pipeline
// (CleverTapEventTypeNotificationViewed), NOT the public recordEvent: API. (Impression & click reuse
// the push "Notification Viewed" / "Notification Clicked" events — see recordLiveActivityImpression/Clicked.)
private let kCTLAEventName = "Live Activity"
private let kCTLAStateStarted = "Started"
private let kCTLAStateUpdated = "Updated"
private let kCTLAStateEnded = "Ended"
private let kCTLAStateDismissed = "Dismissed"

/// Internal manager responsible for all Live Activity token observation, lifecycle events,
/// and backend communication.
///
/// One `CTLiveActivityManager` instance is created per `CleverTap` instance and stored via
/// an associated object. All ActivityKit observation runs in Swift `Task`s so the manager
/// requires iOS 16.2+; the associated-object accessor guards against older OS versions.
///
/// Every Live Activity event (lifecycle, impression, click) carries the same `wzrk` dictionary
/// (activityId, activityType, milestoneId, campaignId) assembled from the activity's attributes.
@available(iOS 16.2, *)
final class CTLiveActivityManager: NSObject {

    // MARK: - State

    private weak var cleverTap: CleverTap?
    private weak var dataQueue: (any CTLiveActivityDataQueue)?

    /// Active observation tasks keyed by `"act_<id>"`, `"__pts__<name>"`, `"__updates__<name>"`.
    private var tasks: [String: Task<Void, Never>] = [:]
    private let lock = NSLock()

    /// Latest push-to-start token per activity-type name (for resend on user switch).
    private var ptsTokens: [String: String] = [:]

    /// Latest per-activity update token + attribution, keyed by `activity.id`.
    private struct ActivityTokenEntry {
        let cleverTapActivityId: String
        let activityName: String
        let wzrk: [String: Any]
        var tokenHex: String?
    }
    private var activityTokens: [String: ActivityTokenEntry] = [:]

    /// Handlers that end (dismiss) a specific activity's UI — captured at attach time so the
    /// non-generic user-switch path can terminate the previous user's activities.
    private var endHandlers: [String: () -> Void] = [:]

    // MARK: - Init

    init(cleverTap: CleverTap) {
        self.cleverTap = cleverTap
        self.dataQueue = cleverTap as? CTLiveActivityDataQueue
        super.init()
        dataQueue?.registerLiveActivitySwitchUserDelegate(self)
    }

    deinit { cancelAllTasks() }

    // MARK: - Push-to-Start Flow (production)

    @available(iOS 17.2, *)
    func registerPushToStart<Attributes: ActivityAttributes>(
        activityType: Activity<Attributes>.Type,
        name: String
    ) {
        let ptsKey = "__pts__\(name)"
        let ptsTask = Task { [weak self] in
            for await token in Activity<Attributes>.pushToStartTokenUpdates {
                guard let self = self, !Task.isCancelled else { break }
                self.sendPushToStartToken(token, activityType: name)
            }
        }
        setTask(ptsTask, for: ptsKey)

        observeActivities(activityType: activityType, name: name)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: registered push-to-start monitoring for type '\(name)'")
    }

    func observeActivities<Attributes: ActivityAttributes>(
        activityType: Activity<Attributes>.Type,
        name: String
    ) {
        reconcileDismissedWhileTerminated(activityType: activityType, name: name)

        for activity in Activity<Attributes>.activities {
            attach(to: activity, activityName: name)
        }

        let key = "__updates__\(name)"
        let task = Task { [weak self] in
            for await activity in Activity<Attributes>.activityUpdates {
                guard let self = self, !Task.isCancelled else { break }
                self.attach(to: activity, activityName: name)
            }
        }
        setTask(task, for: key)
    }

    private func reconcileDismissedWhileTerminated<Attributes: ActivityAttributes>(
        activityType: Activity<Attributes>.Type,
        name: String
    ) {
        let runningIDs = Set(Activity<Attributes>.activities.map { $0.id })
        for (activityID, info) in persistedActivities() {
            guard info[kCTLAStoreActivityName] == name else { continue }
            if !runningIDs.contains(activityID) {
                let ctId = info[kCTLAStoreCleverTapActivityId] ?? activityID
                var wzrk = Self.wzrkFromJSON(info[kCTLAStoreWzrk])
                if wzrk.isEmpty { wzrk = ["wzrk_activityId": ctId] }
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: activity '\(activityID)' vanished while terminated; reporting dismissal on relaunch.")
                sendActivityDismissed(cleverTapActivityId: ctId, activityName: name, wzrk: wzrk)
                removePersistedActivity(activityID: activityID)
            }
        }
    }

    // MARK: - Per-activity observation

    private func attach<Attributes: ActivityAttributes>(
        to activity: Activity<Attributes>,
        activityName: String
    ) {
        let attrs = activity.attributes as? CleverTapLiveActivityAttributes
        let ctActivityId = attrs?.cleverTapActivityId ?? activity.id
        let wzrk = Self.buildWzrk(activityId: ctActivityId, attrs: attrs)

        let key = "act_\(activity.id)"

        lock.lock()
        let alreadyHadToken = activityTokens[activity.id]?.tokenHex != nil
        lock.unlock()

        setActivityEntry(activityID: activity.id, entry: ActivityTokenEntry(
            cleverTapActivityId: ctActivityId, activityName: activityName, wzrk: wzrk, tokenHex: nil))
        persistTrackedActivity(activityID: activity.id, cleverTapActivityId: ctActivityId,
                               activityName: activityName, wzrk: wzrk)

        // Capture an end handler so a later user switch can dismiss this activity.
        setEndHandler(activityID: activity.id) {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }

        // The "Started" state fires when the activity is displayed OR its token is received.
        if activity.activityState == .active {
            reportActivityStartedIfNeeded(activityID: activity.id, wzrk: wzrk)
        }

        // Send the initial token if iOS already has one and we haven't sent it before.
        if !alreadyHadToken, let token = activity.pushToken {
            sendActivityToken(token, activityID: activity.id, cleverTapActivityId: ctActivityId,
                              activityName: activityName, wzrk: wzrk)
        }

        let task = Task { [weak self] in
            guard let self = self else { return }
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await token in activity.pushTokenUpdates {
                        guard let self = self, !Task.isCancelled else { break }
                        self.sendActivityToken(token, activityID: activity.id, cleverTapActivityId: ctActivityId,
                                               activityName: activityName, wzrk: wzrk)
                    }
                }

                // Content updates → "Live Activity" event with state "Updated".
                // `contentUpdates` emits the CURRENT content when observation begins (right after
                // the activity starts). That initial content is already represented by "Started",
                // so we baseline on it and only emit "Updated" when the state actually changes.
                group.addTask { [weak self] in
                    var lastState = activity.content.state
                    for await content in activity.contentUpdates {
                        guard let self = self, !Task.isCancelled else { break }
                        guard content.state != lastState else { continue }
                        lastState = content.state
                        // An `end` push carries a final content-state, which arrives here as a
                        // content change. Skip it — the activity is no longer `.active`, and the
                        // terminal "Ended"/"Dismissed" event already covers that transition.
                        guard activity.activityState == .active else { continue }
                        self.recordLifecycleEvent(state: kCTLAStateUpdated, wzrk: wzrk)
                    }
                }

                // State updates → ended / dismissed.
                group.addTask { [weak self] in
                    for await state in activity.activityStateUpdates {
                        guard let self = self, !Task.isCancelled else { break }
                        if state == .ended {
                            self.recordLifecycleEvent(state: kCTLAStateEnded, wzrk: wzrk)
                            self.sendActivityDeactivate(cleverTapActivityId: ctActivityId, activityName: activityName)
                            self.removePersistedActivity(activityID: activity.id)
                        } else if state == .dismissed {
                            self.sendActivityDismissed(cleverTapActivityId: ctActivityId, activityName: activityName, wzrk: wzrk)
                            self.cancelTask(for: key)
                            self.removeActivityEntry(activityID: activity.id)
                            self.removeEndHandler(activityID: activity.id)
                            self.removePersistedActivity(activityID: activity.id)
                            break
                        }
                    }
                }
            }
        }
        setTask(task, for: key)
    }

    // MARK: - Client-side APIs (customer-invoked): impression & click
    //
    // These behave EXACTLY like push impression / click: a "Notification Viewed" event
    // (NotificationViewed queue) and a "Notification Clicked" event (Raised queue), whose
    // `evtData` is the `wzrk` dictionary from the activity payload.

    func recordLiveActivityImpression(wzrk: [AnyHashable: Any]) {
        dataQueue?.recordLiveActivityViewedEvent(withData: wzrk)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: recorded Live Activity impression (Notification Viewed).")
    }

    func recordLiveActivityClicked(wzrk: [AnyHashable: Any]) {
        dataQueue?.recordLiveActivityClickedEvent(withData: wzrk)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: recorded Live Activity click (Notification Clicked).")
    }

    // MARK: - Switch-user (CTSwitchUserDelegate)

    /// On login / device-id change: end the previous user's active activities, raise
    /// "Live Activity" (state "Ended"), deactivate their tokens, then re-send the PTS token for the new user.
    @objc func deviceIdDidChange(_ newDeviceId: String) {
        lock.lock()
        let entries = activityTokens
        let handlers = endHandlers
        let pts = ptsTokens
        lock.unlock()

        for (activityID, entry) in entries {
            recordLifecycleEvent(state: kCTLAStateEnded, wzrk: entry.wzrk)
            sendActivityDeactivate(cleverTapActivityId: entry.cleverTapActivityId, activityName: entry.activityName)
            cancelTask(for: "act_\(activityID)")
            handlers[activityID]?()             // end the visible activity
            removeActivityEntry(activityID: activityID)
            removeEndHandler(activityID: activityID)
            removePersistedActivity(activityID: activityID)
        }

        // Reassign: re-send the PTS token(s) for the new user.
        for (name, hex) in pts {
            sendPushToStartTokenHex(hex, activityType: name)
        }
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: device id changed; ended \(entries.count) activity(ies) for old user and re-sent \(pts.count) PTS token(s).")
    }

    // MARK: - Private: lifecycle events (via Notification Viewed pipeline)

    private func reportActivityStartedIfNeeded(activityID: String, wzrk: [String: Any]) {
        guard !isStartedReported(activityID: activityID) else { return }
        recordLifecycleEvent(state: kCTLAStateStarted, wzrk: wzrk)
        setStartedReported(activityID: activityID)
    }

    /// Sends the single "Live Activity" event. `evtData` is the `wzrk` dictionary plus a `state`
    /// field ("Started" / "Updated" / "Ended" / "Dismissed").
    private func recordLifecycleEvent(state: String, wzrk: [String: Any]) {
        var props = wzrk
        props["state"] = state
        // Sent through the Notification Viewed pipeline, not the public recordEvent: API.
        dataQueue?.recordLiveActivityEventNamed(kCTLAEventName, data: props)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: recorded 'Live Activity' (\(state)) for id '\(wzrk["wzrk_activityId"] ?? "?")'")
    }

    private func sendActivityDismissed(cleverTapActivityId: String, activityName: String, wzrk: [String: Any]) {
        recordLifecycleEvent(state: kCTLAStateDismissed, wzrk: wzrk)
        sendActivityDeactivate(cleverTapActivityId: cleverTapActivityId, activityName: activityName)
    }

    // MARK: - Private: backend communication (data channel — token BE contract)

    private func sendActivityToken(_ tokenData: Data, activityID: String, cleverTapActivityId: String,
                                   activityName: String, wzrk: [String: Any]) {
        let tokenHex = Self.hex(from: tokenData)
        updateActivityToken(activityID: activityID, tokenHex: tokenHex)
        dataQueue?.enqueueLiveActivityData([
            "id": tokenHex,
            "type": "la",
            "action": "register",
            "activityId": cleverTapActivityId,
            "activityName": activityName
        ])
        // The "Started" state also fires on token receipt.
        reportActivityStartedIfNeeded(activityID: activityID, wzrk: wzrk)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent activity token for id '\(cleverTapActivityId)'")
    }

    private func sendActivityDeactivate(cleverTapActivityId: String, activityName: String) {
        dataQueue?.enqueueLiveActivityData([
            "type": "la",
            "action": "unregister",
            "activityId": cleverTapActivityId,
            "activityName": activityName
        ])
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent token-deactivation for id '\(cleverTapActivityId)'")
    }

    private func sendPushToStartToken(_ tokenData: Data, activityType: String) {
        let tokenHex = Self.hex(from: tokenData)
        lock.lock(); ptsTokens[activityType] = tokenHex; lock.unlock()
        sendPushToStartTokenHex(tokenHex, activityType: activityType)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent push-to-start token for type '\(activityType)'")
    }

    private func sendPushToStartTokenHex(_ tokenHex: String, activityType: String) {
        dataQueue?.enqueueLiveActivityData([
            "id": tokenHex,
            "type": "pts",
            "action": "register",
            "activityName": activityType
        ])
    }

    // MARK: - Private: helpers

    private static func hex(from data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }

    /// Assembles the `wzrk` dictionary the backend expects on every Live Activity event.
    private static func buildWzrk(activityId: String, attrs: CleverTapLiveActivityAttributes?) -> [String: Any] {
        var wzrk: [String: Any] = ["wzrk_activityId": activityId]
        if let type = attrs?.cleverTapActivityType { wzrk["wzrk_activityType"] = type }
        if let milestoneId = attrs?.cleverTapMilestoneId { wzrk["wzrk_milestoneId"] = milestoneId }
        if let campaignId = attrs?.cleverTapCampaignId { wzrk["wzrk_id"] = campaignId }  // wzrk_id = campaign id
        return wzrk
    }

    private static func wzrkJSON(_ wzrk: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(wzrk),
              let data = try? JSONSerialization.data(withJSONObject: wzrk),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    private static func wzrkFromJSON(_ json: String?) -> [String: Any] {
        guard let json = json, let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return obj
    }

    // MARK: - Private: task lifecycle

    private func setTask(_ task: Task<Void, Never>, for key: String) {
        lock.lock(); tasks[key]?.cancel(); tasks[key] = task; lock.unlock()
    }

    private func cancelTask(for key: String) {
        lock.lock(); tasks[key]?.cancel(); tasks.removeValue(forKey: key); lock.unlock()
    }

    private func cancelAllTasks() {
        lock.lock(); tasks.values.forEach { $0.cancel() }; tasks.removeAll(); lock.unlock()
    }

    // MARK: - Private: in-memory caches

    private func setActivityEntry(activityID: String, entry: ActivityTokenEntry) {
        lock.lock()
        var newEntry = entry
        newEntry.tokenHex = activityTokens[activityID]?.tokenHex ?? entry.tokenHex
        activityTokens[activityID] = newEntry
        lock.unlock()
    }

    private func updateActivityToken(activityID: String, tokenHex: String) {
        lock.lock(); activityTokens[activityID]?.tokenHex = tokenHex; lock.unlock()
    }

    private func removeActivityEntry(activityID: String) {
        lock.lock(); activityTokens.removeValue(forKey: activityID); lock.unlock()
    }

    private func setEndHandler(activityID: String, _ handler: @escaping () -> Void) {
        lock.lock(); endHandlers[activityID] = handler; lock.unlock()
    }

    private func removeEndHandler(activityID: String) {
        lock.lock(); endHandlers.removeValue(forKey: activityID); lock.unlock()
    }

    // MARK: - Private: persisted activity store

    private func persistTrackedActivity(activityID: String, cleverTapActivityId: String,
                                        activityName: String, wzrk: [String: Any]) {
        lock.lock()
        var store = storedActivityMap()
        var record = store[activityID] ?? [:]
        record[kCTLAStoreCleverTapActivityId] = cleverTapActivityId
        record[kCTLAStoreActivityName] = activityName
        if let wzrkJSON = Self.wzrkJSON(wzrk) { record[kCTLAStoreWzrk] = wzrkJSON }
        store[activityID] = record
        UserDefaults.standard.set(store, forKey: kCTLAActivityStoreKey)
        lock.unlock()
    }

    private func removePersistedActivity(activityID: String) {
        lock.lock()
        var store = storedActivityMap()
        if store[activityID] != nil {
            store.removeValue(forKey: activityID)
            UserDefaults.standard.set(store, forKey: kCTLAActivityStoreKey)
        }
        lock.unlock()
    }

    private func persistedActivities() -> [String: [String: String]] {
        lock.lock(); defer { lock.unlock() }
        return storedActivityMap()
    }

    private func isStartedReported(activityID: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return storedActivityMap()[activityID]?[kCTLAStoreStarted] == "1"
    }

    private func setStartedReported(activityID: String) {
        lock.lock()
        var store = storedActivityMap()
        if var record = store[activityID] {
            record[kCTLAStoreStarted] = "1"
            store[activityID] = record
            UserDefaults.standard.set(store, forKey: kCTLAActivityStoreKey)
        }
        lock.unlock()
    }

    /// Reads the raw store. Callers must hold `lock`.
    private func storedActivityMap() -> [String: [String: String]] {
        return UserDefaults.standard.dictionary(forKey: kCTLAActivityStoreKey) as? [String: [String: String]] ?? [:]
    }
}
