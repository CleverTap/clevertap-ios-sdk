// Live Activities is an iOS-only (ActivityKit) feature. The whole file compiles to nothing on
// platforms without ActivityKit (e.g. tvOS), so it never leaks into those builds.
#if canImport(ActivityKit)
import ActivityKit
import Foundation

// MARK: - UserDefaults key for persisting tracked activities across launches
// Keyed by `liveActivityId` (the ActivityKit `activity.id`); stores
// { activityName, wzrk(JSON), started } so that, on the next launch, activities that vanished
// while the app was terminated (dismissed / ended / expired) can be reported, and so the
// "Started" state is not re-raised for an already-reported one.
private let kCTLAActivityStoreKey = "CLTAP_LA_ACTIVITY_STORE"

// Keys used inside each persisted activity record.
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
        let activityName: String
        var wzrk: [String: Any]
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
        // Attach to activities already running (re-attach on relaunch) and to any the backend
        // starts while the app is alive. No dismissal reconciliation here.
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

        // Detect activities dismissed while the app was terminated and report them (Dismissed
        // event + token unregister). Polls over a grace window first so ActivityKit's slow/empty
        // cold-launch doesn't cause a misfire on a still-live activity.
        let reconcileKey = "__reconcile__\(name)"
        let reconcileTask = Task { [weak self] in
            guard let self = self else { return }
            await self.reportDismissedWhileTerminated(activityType: activityType, name: name)
        }
        setTask(reconcileTask, for: reconcileKey)
    }

    /// Reports activities that vanished while the app was terminated as `Dismissed` (event +
    /// token `unregister`, same as a live dismissal).
    ///
    /// Polls `Activity.activities` over a grace window and attaches to any restored activity that
    /// appears (ActivityKit can be empty/slow at cold launch), so only activities that stay absent
    /// the whole window are reported. This minimizes — but cannot fully eliminate — the chance of a
    /// false positive (a live activity iOS never surfaces within the window), which would send a
    /// spurious `unregister`.
    private func reportDismissedWhileTerminated<Attributes: ActivityAttributes>(
        activityType: Activity<Attributes>.Type,
        name: String
    ) async {
        let persistedForType = persistedActivities().filter { $0.value[kCTLAStoreActivityName] == name }
        guard !persistedForType.isEmpty else { return }

        var seen = trackedActivityIDs()
        let scans = 5
        for attempt in 0..<scans {   // ~ up to 12s (5 scans, 3s apart)
            let running = Activity<Attributes>.activities
            for activity in running where !trackedActivityIDs().contains(activity.id) {
                attach(to: activity, activityName: name)   // restored activity is alive — track it
            }
            seen.formUnion(running.map { $0.id })
            seen.formUnion(trackedActivityIDs())
            if persistedForType.keys.allSatisfy({ seen.contains($0) }) { break }
            if attempt < scans - 1 {
                try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3s between scans
            }
        }

        for (activityID, info) in persistedForType {
            if seen.contains(activityID) { continue }
            let wzrk = Self.wzrkFromJSON(info[kCTLAStoreWzrk])
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: activity '\(activityID)' absent across reconcile window; reporting Dismissed + unregister.")
            // Raise the "Dismissed" event AND unregister the LA token (same as a live dismissal).
            sendActivityDismissed(liveActivityId: activityID, wzrk: wzrk)
            removePersistedActivity(activityID: activityID)
        }
    }

    // MARK: - Per-activity observation

    private func attach<Attributes: ActivityAttributes>(
        to activity: Activity<Attributes>,
        activityName: String
    ) {
        let liveActivityId = activity.id   // ActivityKit per-activity id
        // wzrk is rebuilt fresh at each event from the CURRENT content-state (so a changing
        // milestone is always current); `startWzrk` is the value at attach/start.
        let startWzrk = Self.buildWzrk(attributes: activity.attributes, contentState: activity.content.state)

        let key = "act_\(activity.id)"

        lock.lock()
        let alreadyHadToken = activityTokens[activity.id]?.tokenHex != nil
        lock.unlock()

        setActivityEntry(activityID: activity.id, entry: ActivityTokenEntry(
            activityName: activityName, wzrk: startWzrk, tokenHex: nil))
        persistTrackedActivity(activityID: activity.id, activityName: activityName, wzrk: startWzrk)

        // Capture an end handler so a later user switch can dismiss this activity.
        setEndHandler(activityID: activity.id) {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }

        // The "Started" state fires when the activity is displayed OR its token is received.
        if activity.activityState == .active {
            reportActivityStartedIfNeeded(activityID: activity.id, wzrk: startWzrk)
        }

        // Send the initial token if iOS already has one and we haven't sent it before.
        if !alreadyHadToken, let token = activity.pushToken {
            sendActivityToken(token, liveActivityId: liveActivityId, wzrk: startWzrk)
        }

        let task = Task { [weak self] in
            guard let self = self else { return }
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await token in activity.pushTokenUpdates {
                        guard let self = self, !Task.isCancelled else { break }
                        let w = Self.buildWzrk(attributes: activity.attributes, contentState: activity.content.state)
                        self.sendActivityToken(token, liveActivityId: liveActivityId, wzrk: w)
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
                        // Rebuild wzrk from THIS content-state (milestone may have changed) and
                        // ALWAYS track it as the latest — even the final content of an `end` push
                        // arrives here, and the terminal "Ended"/"Dismissed" event must use that
                        // (not the possibly-stale `activity.content.state` property).
                        let w = Self.buildWzrk(attributes: activity.attributes, contentState: content.state)
                        self.updateTrackedWzrk(activityID: activity.id, wzrk: w)
                        // Only emit "Updated" while the activity is still live — the `end` push's
                        // final content is represented by the terminal "Ended" event, not "Updated".
                        guard activity.activityState == .active else { continue }
                        self.recordLifecycleEvent(state: kCTLAStateUpdated, wzrk: w)
                    }
                }

                // State updates → ended / dismissed. Use the latest tracked wzrk (fed by the
                // contentUpdates stream above), which reflects the `end` push's final milestone —
                // reading `activity.content.state` here can be stale when the state notification
                // arrives before the content is surfaced on the property.
                group.addTask { [weak self] in
                    for await state in activity.activityStateUpdates {
                        guard let self = self, !Task.isCancelled else { break }
                        if state == .ended {
                            // The end push's final content-state can surface AFTER the .ended
                            // notification, so wait briefly for it to settle before reading.
                            let w = await self.settledWzrk(for: activity)
                            self.updateTrackedWzrk(activityID: activity.id, wzrk: w)
                            self.recordLifecycleEvent(state: kCTLAStateEnded, wzrk: w)
                            self.sendActivityDeactivate(liveActivityId: liveActivityId, wzrk: w)
                            self.removePersistedActivity(activityID: activity.id)
                        } else if state == .dismissed {
                            let w = await self.settledWzrk(for: activity)
                            self.sendActivityDismissed(liveActivityId: liveActivityId, wzrk: w)
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

    // Convenience: extract the `wzrk` dict from the activity (attributes + current content-state) —
    // no manual dict-building.
    func recordLiveActivityImpression<Attributes: ActivityAttributes>(activity: Activity<Attributes>) {
        recordLiveActivityImpression(wzrk: Self.buildWzrk(attributes: activity.attributes, contentState: activity.content.state))
    }

    func recordLiveActivityClicked<Attributes: ActivityAttributes>(activity: Activity<Attributes>) {
        recordLiveActivityClicked(wzrk: Self.buildWzrk(attributes: activity.attributes, contentState: activity.content.state))
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
            sendActivityDeactivate(liveActivityId: activityID, wzrk: entry.wzrk)
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

    private func sendActivityDismissed(liveActivityId: String, wzrk: [String: Any]) {
        recordLifecycleEvent(state: kCTLAStateDismissed, wzrk: wzrk)
        sendActivityDeactivate(liveActivityId: liveActivityId, wzrk: wzrk)
    }

    // MARK: - Private: backend communication (data channel — token BE contract)

    private func sendActivityToken(_ tokenData: Data, liveActivityId: String, wzrk: [String: Any]) {
        let tokenHex = Self.hex(from: tokenData)
        updateActivityToken(activityID: liveActivityId, tokenHex: tokenHex)
        var payload: [AnyHashable: Any] = [
            "id": tokenHex,
            "type": "la",
            "action": "register",
            "liveActivityId": liveActivityId
        ]
        // `activityId`/`activityType` = the client-supplied wzrk_activityId / wzrk_activityType
        // (from the start payload), added alongside the ActivityKit `liveActivityId`.
        if let activityId = wzrk["wzrk_activityId"] { payload["activityId"] = activityId }
        if let activityType = wzrk["wzrk_activityType"] { payload["activityType"] = activityType }
        dataQueue?.enqueueLiveActivityData(payload)
        // The "Started" state also fires on token receipt.
        reportActivityStartedIfNeeded(activityID: liveActivityId, wzrk: wzrk)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent activity token for liveActivityId '\(liveActivityId)'")
    }

    private func sendActivityDeactivate(liveActivityId: String, wzrk: [String: Any]) {
        var payload: [AnyHashable: Any] = [
            "type": "la",
            "action": "unregister",
            "liveActivityId": liveActivityId
        ]
        if let activityId = wzrk["wzrk_activityId"] { payload["activityId"] = activityId }
        if let activityType = wzrk["wzrk_activityType"] { payload["activityType"] = activityType }
        dataQueue?.enqueueLiveActivityData(payload)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "CTLiveActivityManager: sent token-deactivation for liveActivityId '\(liveActivityId)'")
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
            "action": "register"
        ])
    }

    // MARK: - Private: helpers

    private static func hex(from data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }

    /// Extracts wzrk key/values from any `Encodable` (the activity's attributes or its
    /// content-state) via JSON re-encoding — no protocol conformance required. Reads a nested
    /// `wzrk` object if present, else flat `wzrk_*` keys.
    private static func extractWzrk<T: Encodable>(from value: T) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(value),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        if let nested = dict["wzrk"] as? [String: Any] { return nested }
        return dict.filter { $0.key.hasPrefix("wzrk_") }
    }

    /// Builds the wzrk dict for an event. Fixed fields come from the (immutable) START
    /// `attributes`; per-state fields — e.g. a `wzrk_milestoneId` that changes across
    /// start/update/end — come from the CURRENT `content-state` and override. This is required
    /// because `attributes` are frozen at start, so a changing milestone can only travel in
    /// `content-state` (the only field readable on update/end). Values are used as-is; the
    /// ActivityKit per-activity id is never substituted here (it travels as `liveActivityId`).
    static func buildWzrk<Attributes: ActivityAttributes>(attributes: Attributes,
                                                          contentState: Attributes.ContentState) -> [String: Any] {
        var wzrk = extractWzrk(from: attributes)
        for (key, value) in extractWzrk(from: contentState) { wzrk[key] = value }  // content-state wins
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

    /// IDs of activities attached this session (from `Activity.activities` or `activityUpdates`).
    /// Used by terminated-dismissal reconcile as a signal that an activity is alive.
    private func trackedActivityIDs() -> Set<String> {
        lock.lock(); defer { lock.unlock() }
        return Set(activityTokens.keys)
    }

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

    /// Returns the latest tracked wzrk for an activity (falls back to empty if unknown).
    private func trackedWzrk(activityID: String) -> [String: Any] {
        lock.lock(); defer { lock.unlock() }
        return activityTokens[activityID]?.wzrk ?? [:]
    }

    /// Reads the wzrk for a terminal (`.ended`/`.dismissed`) event.
    ///
    /// ActivityKit delivers the `.ended` state and the end push's final `content-state` on two
    /// independent async streams; the state can arrive first, so `activity.content` may still hold
    /// the previous milestone at that instant. There is no synchronous "content applied" signal,
    /// so we wait for the content to arrive — but event-driven, not by polling:
    /// - If the end content is already applied, return it immediately (the common, content-first case).
    /// - Otherwise await the NEXT `contentUpdates` value (wakes exactly when it lands), with a single
    ///   1s timeout as a safety net (an end push may carry no new content, so we must not wait forever).
    private func settledWzrk<Attributes: ActivityAttributes>(for activity: Activity<Attributes>) async -> [String: Any] {
        let previousMilestone = trackedWzrk(activityID: activity.id)["wzrk_milestoneId"] as? String
        let immediate = Self.buildWzrk(attributes: activity.attributes, contentState: activity.content.state)
        if (immediate["wzrk_milestoneId"] as? String) != previousMilestone {
            return immediate   // end content already applied — no wait needed
        }

        let settled: [String: Any]? = await withTaskGroup(of: [String: Any]?.self) { group in
            group.addTask {
                for await content in activity.contentUpdates {
                    return Self.buildWzrk(attributes: activity.attributes, contentState: content.state)
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // safety timeout
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        return settled ?? Self.buildWzrk(attributes: activity.attributes, contentState: activity.content.state)
    }

    /// Updates the latest wzrk (in-memory + persisted) so a later user switch / terminated-app
    /// dismissal reports the most recent milestone rather than the start-time one.
    private func updateTrackedWzrk(activityID: String, wzrk: [String: Any]) {
        lock.lock(); activityTokens[activityID]?.wzrk = wzrk; lock.unlock()
        lock.lock()
        var store = storedActivityMap()
        if var record = store[activityID] {
            if let json = Self.wzrkJSON(wzrk) { record[kCTLAStoreWzrk] = json }
            store[activityID] = record
            UserDefaults.standard.set(store, forKey: kCTLAActivityStoreKey)
        }
        lock.unlock()
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

    private func persistTrackedActivity(activityID: String, activityName: String, wzrk: [String: Any]) {
        lock.lock()
        var store = storedActivityMap()
        var record = store[activityID] ?? [:]
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

#endif
