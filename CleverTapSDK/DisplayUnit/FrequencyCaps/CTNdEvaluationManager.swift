//
//  CTNdEvaluationManager.swift
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation
import CoreLocation

// See the note at the top of CTNdStore.swift for why this import is guarded.
#if canImport(CleverTapSDK.Private)
@_implementationOnly import CleverTapSDK.Private
#endif

/// Profile fields that never start an evaluation.
///
/// `CTConstants.h` holds this list as `CLTAP_SKIP_KEYS_USER_ATTRIBUTE_EVALUATION`. That one is a
/// macro with an Objective-C array literal in it. Swift imports a macro that holds a single number
/// or a single string. It does not import one that holds an array. So the list is repeated here.
/// Change both together.
private let kCTNdSkipKeysUserAttributeEvaluation: Set<String> = ["cc", "tz", "Carrier"]

/// Works out which Native Display campaigns the user is eligible for. The Native Display version of
/// `CTInAppEvaluationManager`.
///
/// On each event it goes through the rules saved in `CTNdStore`. For each campaign it does three
/// things. First it checks whether the event matches `whenTriggers`. Then it adds one to that
/// campaign's trigger count. Then it checks `frequencyLimits` and `occurrenceLimits` against Native
/// Display's own impression and trigger counts. Every campaign that passes has its `ti` added to
/// `adUnit_eval`. That list goes out with the next request. The server sends content only for the ids
/// in it. That is why `CTNdFCManager` does not check those two limits again when the unit is shown.
///
/// This class also holds the `adUnit_suppressed` list. Those are not made here. They are control
/// group acknowledgements. The server picked this user to see nothing. We tell it we noticed. Response
/// handling adds them through `recordSuppressedNativeDisplay(_:)`. Both lists live here because that
/// is where in-app keeps its versions. Both survive an app restart.
///
/// Native Display is server side only. Nothing here decides what to show. It only reports what the
/// user qualifies for.
@objc
@objcMembers
public final class CTNdEvaluationManager: NSObject {

    /// Passed to each event so location based triggers can be matched. Set by `CleverTap`.
    ///
    /// The property is marked `@nonobjc` on purpose. `CLLocationCoordinate2D` is a C struct, not a
    /// pointer. Swift cannot forward declare a C struct in the generated header. It has to name the
    /// module that owns the struct instead. On recent SDKs that module is `_LocationEssentials`, which
    /// older SDKs do not have. The generated header ships inside the xcframework. A client on an older
    /// Xcode would then fail to compile it. Objective-C inside the SDK sets the value through
    /// `setLocationWithLatitude:longitude:` below. That method takes two doubles, so the header stays
    /// free of CoreLocation.
    @nonobjc var location: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid

    /// Sets `location` from two doubles. Called by `CleverTap`. See the note on `location`.
    @objc(setLocationWithLatitude:longitude:)
    public func setLocation(latitude: Double, longitude: Double) {
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: - Collaborators

    let impressionManager: CTImpressionManager
    let triggerManager: CTInAppTriggerManager
    private let ndStore: CTNdStore

    // Both matchers hold no state. They take the managers on each call. In-app's could have been
    // shared. Making our own is cheap. It also keeps the two channels apart.
    private let triggersMatcher: CTTriggersMatcher
    private let limitsMatcher: CTLimitsMatcher

    // MARK: - Identity

    private let accountId: String
    /// Guarded by `lock`. The Objective-C version marked this property `atomic`.
    private(set) var deviceId: String

    // MARK: - Pending lists

    /// The ti of every campaign the user qualified for that has not been sent yet.
    ///
    /// The element type is `Any` on purpose. Entries written here are always `NSNumber`. Entries
    /// read back from storage are whatever was stored. The Objective-C version did not check them
    /// either.
    private(set) var evaluatedServerSideNativeDisplayIds: [Any] = []

    /// Control group acknowledgements waiting to be sent. See `recordSuppressedNativeDisplay(_:)`.
    private(set) var suppressedNativeDisplays: [Any] = []

    /// The properties of the last App Launched event, merged into profile change events.
    private var appLaunchedProperties: [AnyHashable: Any] = [:]

    // MARK: - Internals

    private let lock = NSRecursiveLock()
    private let delegateObserver = CTNdDelegateObserver()

    // MARK: - Init

    @objc(initWithAccountId:deviceId:delegateManager:impressionManager:triggerManager:ndStore:localDataStore:)
    public init(accountId: String,
         deviceId: String,
         delegateManager: CTMultiDelegateManager,
         impressionManager: CTImpressionManager,
         triggerManager: CTInAppTriggerManager,
         ndStore: CTNdStore,
         localDataStore dataStore: CTLocalDataStore) {
        self.accountId = accountId
        self.deviceId = deviceId
        self.impressionManager = impressionManager
        self.triggerManager = triggerManager
        self.ndStore = ndStore
        self.triggersMatcher = CTTriggersMatcher(dataStore: dataStore)
        self.limitsMatcher = CTLimitsMatcher()
        super.init()

        loadPendingLists()

        // The manager owns the observer. So the captures below are unowned. That stops the two from
        // keeping each other alive.
        delegateObserver.batchSentHandler = { [unowned self] batch, success, queueType in
            self.onBatchSent(batch, withSuccess: success, with: queueType)
        }
        delegateObserver.batchHeaderHandler = { [unowned self] queueType in
            self.onBatchHeaderCreation(for: queueType)
        }
        delegateObserver.deviceIdDidChangeHandler = { [unowned self] newDeviceId in
            self.deviceIdDidChange(newDeviceId)
        }
        delegateObserver.register(with: delegateManager)
    }

    private func loadPendingLists() {
        evaluatedServerSideNativeDisplayIds = []
        let savedEvaluated = CTPreferences.getObjectForKey(storageKey(withSuffix: CLTAP_ND_SS_EVAL_STORAGE_KEY))
        if let savedEvaluated = savedEvaluated as? [Any] {
            evaluatedServerSideNativeDisplayIds = savedEvaluated
        }

        suppressedNativeDisplays = []
        let savedSuppressed = CTPreferences.getObjectForKey(storageKey(withSuffix: CLTAP_ND_SUPPRESSED_STORAGE_KEY))
        if let savedSuppressed = savedSuppressed as? [Any] {
            suppressedNativeDisplays = savedSuppressed
        }
    }

    // MARK: - Evaluation entry points

    @objc(evaluateOnEvent:withProps:)
    public func evaluate(onEvent eventName: String, withProps properties: [AnyHashable: Any]?) {
        if eventName == CLTAP_APP_LAUNCHED_EVENT {
            // App Launched is not evaluated for Native Display. We keep its properties anyway.
            // Profile change events are matched against them too.
            appLaunchedProperties = properties ?? [:]
            return
        }

        let event = CTEventAdapter(eventName: eventName,
                                   eventProperties: properties ?? [:],
                                   andLocation: location)
        evaluate([event])
    }

    @objc(evaluateOnChargedEvent:andItems:)
    public func evaluate(onChargedEvent chargeDetails: [AnyHashable: Any], andItems items: [Any]?) {
        let event = CTEventAdapter(eventName: CLTAP_CHARGED_EVENT,
                                   eventProperties: chargeDetails,
                                   location: location,
                                   andItems: (items as? [[AnyHashable: Any]]) ?? [])
        evaluate([event])
    }

    @objc(evaluateOnUserAttributeChange:)
    public func evaluate(onUserAttributeChange profile: [String: [AnyHashable: Any]]) {
        let appFields = appLaunchedProperties
        var events: [CTEventAdapter] = []

        for (key, value) in toNestedMap(profile) {
            if kCTNdSkipKeysUserAttributeEvaluation.contains(key) {
                continue
            }
            let eventName = key + CLTAP_USER_ATTRIBUTE_CHANGE
            var eventProperties = value
            eventProperties.merge(appFields) { _, new in new }
            let event = CTEventAdapter(eventName: eventName,
                                       profileAttrName: key,
                                       eventProperties: eventProperties,
                                       andLocation: location)
            events.append(event)
        }

        evaluate(events)
    }

    private func toNestedMap(_ profileChanges: [String: [AnyHashable: Any]]) -> [String: [AnyHashable: Any]] {
        var result: [String: [AnyHashable: Any]] = [:]
        for (key, change) in profileChanges {
            result[key] = [
                "oldValue": change["oldValue"] ?? NSNull(),
                "newValue": change["newValue"] ?? NSNull()
            ]
        }
        return result
    }

    // MARK: - Evaluation

    /// It is `private` on purpose. `CTNdEvaluationManager` is `@objcMembers`, so an internal member
    /// would be written into the generated header. `CTEventAdapter` belongs to the SDK's `Private`
    /// submodule. Nothing outside this class calls this method.
    private func evaluate(_ events: [CTEventAdapter]) {
        let nativeDisplays = ndStore.serverSideNativeDisplays()
        if nativeDisplays.isEmpty { return }

        var updated = false
        for event in events {
            for entry in nativeDisplays {
                guard let nativeDisplay = entry as? [AnyHashable: Any] else { continue }

                // Same helper the cap manager uses. Triggers and impressions must use one id. Two
                // helpers could drift apart. One would then write under a key the other never reads.
                let campaignId = CTNdFCManager.campaignId(from: nativeDisplay)
                if campaignId.isEmpty { continue }

                let whenTriggers = nativeDisplay[CLTAP_INAPP_TRIGGERS] as? [Any] ?? []
                if !triggersMatcher.matchEvent(whenTriggers: whenTriggers, event: event) { continue }

                // The campaign matched the trigger. Its trigger count goes up whether the limits
                // pass or not. occurrenceLimits are counted in triggers. They need this.
                triggerManager.incrementTrigger(campaignId)

                var whenLimits: [Any] = []
                whenLimits.append(contentsOf: nativeDisplay[CLTAP_INAPP_FC_LIMITS] as? [Any] ?? [])
                whenLimits.append(contentsOf: nativeDisplay[CLTAP_INAPP_OCCURRENCE_LIMITS] as? [Any] ?? [])
                let matchesLimits = limitsMatcher.match(whenLimits: whenLimits,
                                                    forCampaignId: campaignId,
                                                    with: impressionManager,
                                                    andTriggerManager: triggerManager)
                if !matchesLimits {
                    // Every limit in the list has to pass. The trigger count is printed next to the
                    // list. onEvery and onExactly are read from that count. It is a lifetime total
                    // for this campaign. It is not a count of views.
                    log("Native Display campaign \(campaignId) matched event \(event.eventName), but its limits did not pass. Limits: \(whenLimits). This campaign has now matched a trigger \(triggerManager.getTriggers(campaignId)) time(s) in total since install.")
                    continue
                }

                guard let ti = CTUtils.number(from: campaignId) else { continue }

                // Added even if the same id is already in the list. A campaign can qualify again
                // during a send. A send removes only what it sent. A dropped repeat would be lost.
                // The server ignores repeats.
                lock.lock()
                evaluatedServerSideNativeDisplayIds.append(ti)
                lock.unlock()
                updated = true
                log("Native Display campaign \(ti) is eligible for event \(event.eventName)")
            }
        }

        if updated {
            saveEvaluatedServerSideNativeDisplayIds()
        }
    }

    /// Returns the App-Launched entries that are still eligible.
    ///
    /// App-Launched campaigns are not listed in `adUnit_notifs_ss`. Each entry carries its own
    /// `whenTriggers`, `frequencyLimits` and `occurrenceLimits`. The SDK never reports them in
    /// `adUnit_eval`. This is the only place those rules are applied.
    ///
    /// The server sends this content before the launch happens. A condition that is only known at the
    /// moment of the launch has to be checked here. `firstTimeOnly` is one. The user location is
    /// another. The app sets that at run time.
    ///
    /// The steps are in the same order as the event path in `evaluate(_:)` above. `whenTriggers` is
    /// matched first. The trigger count goes up on a match. `whenLimits` is read last. `onEvery` and
    /// `onExactly` read that count.
    ///
    /// An entry with no campaign id passes through. An entry with no `whenTriggers` passes that step.
    /// The launch itself is the trigger for it.
    public func retainAppLaunchedWithinLimits(_ content: [[AnyHashable: Any]]) -> [[AnyHashable: Any]] {
        if content.isEmpty { return content }

        // The same event the in-app side builds for its App Launched pass. The properties were kept
        // when the App Launched event was recorded. See `evaluate(onEvent:withProps:)` above.
        let event = CTEventAdapter(eventName: CLTAP_APP_LAUNCHED_EVENT,
                                   eventProperties: appLaunchedProperties,
                                   andLocation: location)

        return content.filter { entry in
            // Same helper the cap manager uses. Triggers and impressions must use one id. Two
            // helpers could drift apart. One would then write under a key the other never reads.
            let campaignId = CTNdFCManager.campaignId(from: entry)
            if campaignId.isEmpty { return true }

            // An empty list is not passed to the matcher. The matcher reads an empty list as no
            // match. An entry without triggers has to reach the limits below.
            let whenTriggers = entry[CLTAP_INAPP_TRIGGERS] as? [Any] ?? []
            if !whenTriggers.isEmpty,
               !triggersMatcher.matchEvent(whenTriggers: whenTriggers, event: event) {
                log("App-Launched Native Display campaign \(campaignId) arrived, but its triggers did not match this launch. Triggers: \(whenTriggers)")
                return false
            }

            // The campaign matched the trigger. Its trigger count goes up whether the limits pass or
            // not. occurrenceLimits are counted in triggers. They need this.
            triggerManager.incrementTrigger(campaignId)

            var whenLimits: [Any] = []
            whenLimits.append(contentsOf: entry[CLTAP_INAPP_FC_LIMITS] as? [Any] ?? [])
            whenLimits.append(contentsOf: entry[CLTAP_INAPP_OCCURRENCE_LIMITS] as? [Any] ?? [])
            if whenLimits.isEmpty { return true }

            let withinLimits = limitsMatcher.match(whenLimits: whenLimits,
                                                   forCampaignId: campaignId,
                                                   with: impressionManager,
                                                   andTriggerManager: triggerManager)
            if !withinLimits {
                // Every limit in the list has to pass. The trigger count is printed next to the
                // list. onEvery and onExactly are read from that count. It is a lifetime total for
                // this campaign. It is not a count of views.
                log("App-Launched Native Display campaign \(campaignId) arrived, but its limits did not pass. Limits: \(whenLimits). This campaign has now matched a trigger \(triggerManager.getTriggers(campaignId)) time(s) in total since install.")
            }
            return withinLimits
        }
    }

    // MARK: - App-Launched priority arbitration

    /// Picks the App-Launched entries to deliver. Every entry in the highest priority band wins.
    ///
    /// Campaigns that answer the same event compete with each other. The server does that comparison
    /// for every other event. It cannot do it for App Launched. It does not know when the launch will
    /// happen. It does not know the counts held on the device. So it sends every candidate and the
    /// device compares them here.
    ///
    /// A band is one priority value. Bands are read from the highest value down. The first band that
    /// holds content wins. Every entry in that band is delivered, so two campaigns at priority 10 are
    /// both delivered. Every band below it is dropped.
    ///
    /// Both lists must already be checked against `whenTriggers` and `whenLimits`. See
    /// `retainAppLaunchedWithinLimits(_:)`. An entry that failed those checks would not be shown. It
    /// must not take the top band from an entry that would be.
    ///
    /// A control group stub in a band that is reached is acknowledged. Reaching that band means the
    /// campaign would have been shown to a user outside the control group. A band that holds nothing
    /// but stubs does not end the walk. Nothing is delivered from it. Its stubs are still
    /// acknowledged. The walk carries on to the next band.
    ///
    /// - Parameters:
    ///   - content: the entries that carry content.
    ///   - stubs: the control group entries. They carry no content.
    @objc(selectTopPriorityBandWithContent:stubs:)
    public func selectTopPriorityBand(content: [[AnyHashable: Any]],
                                      stubs: [[AnyHashable: Any]]) -> CTNdAppLaunchedSelection {
        if content.isEmpty && stubs.isEmpty {
            return CTNdAppLaunchedSelection(winners: [], controlGroupAcknowledgements: [])
        }

        // The flag marks an entry that carries content. A stub reads as false. Both kinds take part
        // in the order. A stub holds a priority like any other entry.
        let candidates = content.map { ($0, true) } + stubs.map { ($0, false) }
        let sorted = candidates.enumerated().sorted { left, right in
            let leftPriority = Self.priority(of: left.element.0)
            let rightPriority = Self.priority(of: right.element.0)
            if leftPriority != rightPriority { return leftPriority > rightPriority }

            // The campaign id breaks a tie on priority. It is compared as text. A campaign id is an
            // epoch timestamp, and every one of them has the same number of digits. Text order and
            // number order are the same for values of one length. The smaller value is the older
            // campaign. The older campaign goes first.
            let leftId = CTNdFCManager.campaignId(from: left.element.0)
            let rightId = CTNdFCManager.campaignId(from: right.element.0)
            if leftId != rightId { return leftId < rightId }

            // Two entries can match on both values. The position they arrived in then decides. Swift
            // does not promise to keep the order of equal elements. This line keeps the result the
            // same on every run.
            return left.offset < right.offset
        }.map { $0.element }

        var winners: [[AnyHashable: Any]] = []
        var acknowledgements: [[AnyHashable: Any]] = []
        var droppedIds: [String] = []
        var winningPriority = 0
        var index = 0

        while index < sorted.count {
            let bandPriority = Self.priority(of: sorted[index].0)
            var bandContent: [[AnyHashable: Any]] = []

            while index < sorted.count, Self.priority(of: sorted[index].0) == bandPriority {
                let (entry, hasContent) = sorted[index]
                if hasContent {
                    bandContent.append(entry)
                } else {
                    acknowledgements.append(entry)
                }
                index += 1
            }

            if !bandContent.isEmpty {
                winners = bandContent
                winningPriority = bandPriority
                break
            }
        }

        // Everything left over sits below the winning band. Those entries are dropped.
        while index < sorted.count {
            let (entry, hasContent) = sorted[index]
            if hasContent { droppedIds.append(CTNdFCManager.campaignId(from: entry)) }
            index += 1
        }

        if !droppedIds.isEmpty {
            log("App-Launched Native Display delivered \(winners.count) campaign(s) at priority \(winningPriority). \(droppedIds.count) campaign(s) at a lower priority were held back: \(droppedIds.joined(separator: ", ")). Campaigns that answer the same event compete on priority.")
        }

        return CTNdAppLaunchedSelection(winners: winners, controlGroupAcknowledgements: acknowledgements)
    }

    /// The priority of one entry. A missing value reads as 1. In-app uses the same default.
    ///
    /// The server sends this as a number. A string that holds a number is read too.
    private static func priority(of entry: [AnyHashable: Any]) -> Int {
        let raw = entry[CLTAP_INAPP_PRIORITY]
        if let number = raw as? NSNumber { return number.intValue }
        if let text = raw as? String, let value = Int(text) { return value }
        return 1
    }

    // MARK: - Control group acknowledgements

    /// Records that a campaign was not shown because the user is in its control group.
    ///
    /// The server sends these inside `adUnit_notifs_applaunched` as stubs. They carry `wzrk_id` and
    /// `wzrk_cgId` but no content. The SDK sends the acknowledgement. The server does not work it out
    /// on its own. The control group event then happens at the same moment the unit would have been
    /// shown.
    ///
    /// A stub with no `wzrk_id` is logged and dropped. There is nothing to acknowledge.
    ///
    /// The parameter is `Any?` so that a caller passing something other than a dictionary is handled
    /// the same way the Objective-C version handled it.
    @objc(recordSuppressedNativeDisplay:)
    public func recordSuppressedNativeDisplay(_ suppressedUnit: Any?) {
        guard let suppressedUnit = suppressedUnit as? [AnyHashable: Any] else { return }

        guard let wzrkId = suppressedUnit[CLTAP_NOTIFICATION_ID_TAG] as? String, !wzrkId.isEmpty else {
            // The server always sends wzrk_id on these stubs. This should not happen. Without one
            // there is nothing to acknowledge. Log it instead of dropping it silently.
            log("Dropping Native Display control group acknowledgement, no wzrk_id on \(suppressedUnit)")
            return
        }

        var acknowledgement: [String: Any] = [:]
        acknowledgement[CLTAP_NOTIFICATION_ID_TAG] = wzrkId
        acknowledgement[CLTAP_NOTIFICATION_PIVOT] = suppressedUnit[CLTAP_NOTIFICATION_PIVOT] ?? CLTAP_NOTIFICATION_PIVOT_DEFAULT
        // wzrk_cgId is always part of the acknowledgement. The stub may not have one. 0 is sent in
        // that case. The acknowledgement keeps the same shape every time. The value is always a
        // number. A string value is converted to one.
        let rawControlGroupId = suppressedUnit[CLTAP_NOTIFICATION_CONTROL_GROUP_ID]
        acknowledgement[CLTAP_NOTIFICATION_CONTROL_GROUP_ID] = (rawControlGroupId as? NSNumber)?.intValue
            ?? Int(rawControlGroupId as? String ?? "")
            ?? 0

        lock.lock()
        suppressedNativeDisplays.append(acknowledgement)
        lock.unlock()
        saveSuppressedNativeDisplays()
        log("Recorded Native Display control group acknowledgement for \(wzrkId)")
    }

    // MARK: - AttachToBatchHeader delegate

    /// It is `@nonobjc` on purpose. `CTQueueType` belongs to the SDK's `Private` submodule, and the
    /// generated header cannot name a type from there. An `@objc` method that takes one would break
    /// every Objective-C file in the target. See the comment on CTNdDelegateObserver.
    @nonobjc
    func onBatchHeaderCreation(for queueType: CTQueueType) -> [String: Any] {
        var header: [String: Any] = [:]
        // Both lists go out on the events batch, even entries that came from a profile change.
        // In-app sends its versions there too. The server reads them from the same place.
        if queueType != CTQueueType.events { return header }

        lock.lock()
        if !evaluatedServerSideNativeDisplayIds.isEmpty {
            header[CLTAP_ND_SS_EVAL_META_KEY] = evaluatedServerSideNativeDisplayIds
        }
        if !suppressedNativeDisplays.isEmpty {
            header[CLTAP_ND_SUPPRESSED_META_KEY] = suppressedNativeDisplays
        }
        lock.unlock()
        return header
    }

    // MARK: - BatchSent delegate

    /// It is `@nonobjc` for the same reason as `onBatchHeaderCreation(for:)`.
    @nonobjc
    func onBatchSent(_ batchWithHeader: [Any], withSuccess success: Bool, with queueType: CTQueueType) {
        if !success || queueType != CTQueueType.events { return }
        guard let header = batchWithHeader.first as? [AnyHashable: Any] else { return }

        if removeSent(header[CLTAP_ND_SS_EVAL_META_KEY], from: &evaluatedServerSideNativeDisplayIds) {
            saveEvaluatedServerSideNativeDisplayIds()
            // The server stops sending a campaign once it knows the SDK found it eligible. A
            // campaign that keeps arriving is a sign that never reached the server. This line shows
            // it did reach the server.
            lock.lock()
            let stillWaiting = evaluatedServerSideNativeDisplayIds.count
            lock.unlock()
            // Cast before printing. The value arrives as an NSArray. Printing that gives the
            // Objective-C form, which runs over several lines.
            let sentIds = header[CLTAP_ND_SS_EVAL_META_KEY] as? [Any] ?? []
            log("The server received the Native Display campaigns the SDK found eligible. Campaign ids: \(sentIds). They were sent in \(CLTAP_ND_SS_EVAL_META_KEY). \(stillWaiting) more campaign id(s) are still waiting to be sent.")
        }
        if removeSent(header[CLTAP_ND_SUPPRESSED_META_KEY], from: &suppressedNativeDisplays) {
            saveSuppressedNativeDisplays()
            lock.lock()
            let stillWaiting = suppressedNativeDisplays.count
            lock.unlock()
            log("The server received the Native Display control group acknowledgements. They were sent in \(CLTAP_ND_SUPPRESSED_META_KEY). \(stillWaiting) more acknowledgement(s) are still waiting to be sent.")
        }
    }

    /// Removes as many entries from the front of the list as the batch carried, and no more. New
    /// entries arriving during the send sit behind them. Those go out next time.
    ///
    /// Returns true when it removed something. The caller saves the list in that case.
    private func removeSent(_ sent: Any?, from list: inout [Any]) -> Bool {
        guard let sent = sent as? [Any], !sent.isEmpty else { return false }

        lock.lock()
        defer { lock.unlock() }
        let toRemove = min(list.count, sent.count)
        if toRemove == 0 { return false }
        list.removeFirst(toRemove)
        return true
    }

    // MARK: - Storage

    func saveEvaluatedServerSideNativeDisplayIds() {
        lock.lock()
        defer { lock.unlock() }
        CTPreferences.put(evaluatedServerSideNativeDisplayIds,
                          forKey: storageKey(withSuffix: CLTAP_ND_SS_EVAL_STORAGE_KEY))
    }

    func saveSuppressedNativeDisplays() {
        lock.lock()
        defer { lock.unlock() }
        CTPreferences.put(suppressedNativeDisplays,
                          forKey: storageKey(withSuffix: CLTAP_ND_SUPPRESSED_STORAGE_KEY))
    }

    /// Same key order as CTInAppEvaluationManager. That order is accountId:suffix:deviceId.
    @objc(storageKeyWithSuffix:)
    func storageKey(withSuffix suffix: String) -> String {
        return "\(accountId):\(suffix):\(deviceId)"
    }

    // MARK: - SwitchUser delegate

    func deviceIdDidChange(_ newDeviceId: String) {
        lock.lock()
        defer { lock.unlock() }

        let leftBehind = evaluatedServerSideNativeDisplayIds.count + suppressedNativeDisplays.count
        deviceId = newDeviceId
        // Anything still waiting belongs to the old user. We leave it under their key. It must not
        // be sent under the new user's key.
        loadPendingLists()

        let loaded = evaluatedServerSideNativeDisplayIds.count + suppressedNativeDisplays.count
        if leftBehind > 0 || loaded > 0 {
            // An entry that has not been sent yet stops here. The server keeps sending that
            // campaign until the entry arrives. Without this line the entries appear to vanish.
            log("A user switch changed the Native Display storage key. \(leftBehind) pending entry(ies) stay with the previous user. \(loaded) entry(ies) saved earlier for the new user were loaded.")
        }
    }

    // MARK: - Logging

    /// Matches the CleverTapLogStaticDebug macro. That macro reads the level from CTLogger, because
    /// this class holds no config object. The prefix is added here. Every line this class writes
    /// then carries it.
    private func log(_ message: String) {
        let level = CTLogger.getDebugLevel()
        if level > 0 {
            CTLogger.logWithLevel(level, type: CTLogType.debug.rawValue, message: "\(CLTAP_ND_LOG_PREFIX) \(message)")
        }
    }

    public override var description: String {
        return "\(type(of: self)):\(accountId):\(deviceId)"
    }
}

/// What `selectTopPriorityBand(content:stubs:)` decided.
///
/// The two lists are separate because they are used in different ways. A winner is shown to the
/// user. An acknowledgement is only reported to the server.
@objc(CTNdAppLaunchedSelection)
public final class CTNdAppLaunchedSelection: NSObject {
    /// The entries to deliver. They all hold the same priority.
    @objc public let winners: [[AnyHashable: Any]]

    /// The control group stubs to acknowledge. They sit in the winning band, or in a band above it
    /// that held nothing else.
    @objc public let controlGroupAcknowledgements: [[AnyHashable: Any]]

    init(winners: [[AnyHashable: Any]], controlGroupAcknowledgements: [[AnyHashable: Any]]) {
        self.winners = winners
        self.controlGroupAcknowledgements = controlGroupAcknowledgements
        super.init()
    }
}
