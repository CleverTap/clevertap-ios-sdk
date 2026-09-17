//
//  CTNdFCManager.swift
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//
//  Swift replacement for CTNdFCManager.h and CTNdFCManager.m.
//

import Foundation

// See the note at the top of CTNdStore.swift for why this import is guarded.
#if canImport(CleverTapSDK.Private)
@_implementationOnly import CleverTapSDK.Private
#endif

/// The server sends -1 to mean no limit. That is true for every count here, per campaign and
/// account-wide.
private let kCTNdUncapped: Int32 = -1

/// Frequency caps for Native Display. The Native Display version of `CTInAppFCManager`.
///
/// It handles the caps that work by counting how many times a campaign was shown. Each campaign has
/// a lifetime cap (`tlc`), a daily cap (`tdc`) and a session cap (`mdc`). The account has two more,
/// `ndmp` for the day and `ndmc` for the session.
///
/// Two flags can skip caps. They skip different amounts. `efc` skips every cap.
/// `excludeGlobalFCaps` skips only the two account caps. The campaign still has to obey `tlc`,
/// `tdc` and `mdc`. In-app treats both flags the same. Native Display does not.
///
/// `frequencyLimits` and `occurrenceLimits` are not checked here. The SDK checks them earlier. It
/// then sends the campaigns that pass in `adUnit_eval`. The server sends content only for those.
/// `CTInAppFCManager` does check them a second time. This is the one place the two differ on
/// purpose.
///
/// The class is internal on purpose. `@objc` is what puts it in the generated header, so
/// Objective-C inside the SDK still sees it. Clients that write `import CleverTapSDK` do not.
@objcMembers
final class CTNdFCManager: NSObject {

    let config: CleverTapInstanceConfig

    /// Guarded by `lock`. The Objective-C version marked this property `atomic`.
    private(set) var deviceId: String

    let impressionManager: CTImpressionManager
    let triggerManager: CTInAppTriggerManager

    /// campaign id -> a two item array, today's count then the lifetime count.
    ///
    /// Every entry has exactly two items. `initCampaignCounts` drops an entry that does not, and
    /// nothing else writes an entry of another shape.
    private(set) var campaignCounts: [String: [Int]] = [:]

    /// Guards `deviceId` and `campaignCounts`. The Objective-C version used
    /// `@synchronized (self.campaignCounts)`, which is recursive, so the recursive lock is the exact
    /// match.
    private let lock = NSRecursiveLock()

    /// Receives the user switch and batch header callbacks on this manager's behalf. See
    /// CTNdDelegateObserver for why the manager does not receive them directly.
    /// CTMultiDelegateManager keeps a weak reference to its delegates, so the manager has to be the
    /// one that owns this object.
    private let delegateObserver = CTNdDelegateObserver()

    @objc(initWithConfig:delegateManager:deviceId:impressionManager:triggerManager:)
    init(config: CleverTapInstanceConfig,
         delegateManager: CTMultiDelegateManager,
         deviceId: String,
         impressionManager: CTImpressionManager,
         triggerManager: CTInAppTriggerManager) {
        self.config = config
        self.deviceId = deviceId
        self.impressionManager = impressionManager
        self.triggerManager = triggerManager
        super.init()

        // The manager owns the observer. So the captures below are unowned. That stops the two from
        // keeping each other alive.
        delegateObserver.deviceIdDidChangeHandler = { [unowned self] newDeviceId in
            self.deviceIdDidChange(newDeviceId)
        }
        delegateObserver.batchHeaderHandler = { [unowned self] queueType in
            self.onBatchHeaderCreation(for: queueType)
        }
        delegateObserver.register(with: delegateManager)

        initCampaignCounts()
        checkUpdateDailyLimits()
    }

    private func initCampaignCounts() {
        lock.lock()
        defer { lock.unlock() }

        let saved = CTPreferences.getObjectForKey(storageKey(withSuffix: CLTAP_PREFS_ND_COUNTS_PER_CAMPAIGN_KEY))
        guard let savedCounts = saved as? [String: Any] else {
            campaignCounts = [:]
            return
        }

        // An entry needs both counts to mean anything. A broken entry is dropped here. The
        // Objective-C version kept it and read it as zero at every use. Both hide it the same way.
        var loaded: [String: [Int]] = [:]
        for (campaignId, value) in savedCounts {
            if let counts = value as? [Int], counts.count == 2 {
                loaded[campaignId] = counts
            }
        }
        campaignCounts = loaded
    }

    /// Writes `campaignCounts` to storage. The caller must already hold `lock`.
    private func saveCampaignCounts() {
        CTPreferences.put(campaignCounts,
                          forKey: storageKey(withSuffix: CLTAP_PREFS_ND_COUNTS_PER_CAMPAIGN_KEY))
    }

    // Same key order as CTInAppFCManager. That order is accountId:suffix:deviceId. CTNdStore uses a
    // different order. Each class copies the one it is based on.
    @objc(storageKeyWithSuffix:)
    func storageKey(withSuffix suffix: String) -> String {
        lock.lock()
        defer { lock.unlock() }

        return "\(config.accountId):\(suffix):\(deviceId)"
    }

    override var description: String {
        lock.lock()
        defer { lock.unlock() }

        return "\(type(of: self)):\(config.accountId):\(deviceId)"
    }

    private func log(_ message: String) {
        CTLogger.logWithLevel(Int32(config.logLevel.rawValue),
                              type: CTLogType.debug.rawValue,
                              message: message)
    }

    // MARK: - Which accounts have caps

    /// Whether the server has set either account limit, `ndmp` for the day or `ndmc` for the
    /// session.
    ///
    /// Neither is set until a response carries `ndmc`. An account that never receives it has no
    /// account limit of any kind. Only the log line that warns about missing view reports reads
    /// this. The caps themselves do not need it. `canShowCampaign` already lets an unset limit
    /// through.
    func hasAccountCaps() -> Bool {
        return globalSessionMax() != kCTNdUncapped || maxPerDayCount() != kCTNdUncapped
    }

    /// The campaign id this unit's counts are stored under. Empty string if the unit has none.
    ///
    /// Always `ti`, which is the campaign. Never `wzrk_id`.
    ///
    /// Every store keys on what this returns. They match only as long as they all ask here.
    ///
    /// The argument is `Any` and not a dictionary on purpose. It carries whatever the server sent.
    /// A value of another shape gives an empty string.
    @objc(campaignIdFrom:)
    static func campaignId(from unit: Any?) -> String {
        guard let unit = unit as? [AnyHashable: Any] else { return "" }

        let campaignId = unit[CLTAP_INAPP_ID]
        if let campaignId = campaignId as? String { return campaignId }
        // The server sends ti as a number in the content payload and as a string in other payloads.
        if let campaignId = campaignId as? NSNumber { return campaignId.stringValue }
        return ""
    }

    // MARK: - Session, daily and global limits

    /// Resets the daily counts if the date has changed. Lifetime counts are not touched.
    func checkUpdateDailyLimits() {
        let today = todaysFormattedDate()
        if shouldResetDailyCounters(today) {
            resetDailyCounters(today)
        }
    }

    // No limit until the server sends one. ndmc and ndmp are new keys. A response may not carry them
    // at all. A default of 1 would then hold every account to one unit per session and one per day.
    // In-app defaults these to 1. In-app can do that because imc and imp are on every response.
    func globalSessionMax() -> Int32 {
        return Int32(CTPreferences.getIntForKey(storageKey(withSuffix: CLTAP_PREFS_ND_SESSION_MAX_KEY),
                                                withResetValue: Int(kCTNdUncapped)))
    }

    func maxPerDayCount() -> Int32 {
        return Int32(CTPreferences.getIntForKey(storageKey(withSuffix: CLTAP_PREFS_ND_MAX_PER_DAY_KEY),
                                                withResetValue: Int(kCTNdUncapped)))
    }

    /// How many Native Display units the SDK showed today. Sent to the server as `ndmp`.
    func shownTodayCount() -> Int32 {
        return Int32(CTPreferences.getIntForKey(storageKey(withSuffix: CLTAP_PREFS_ND_COUNTS_SHOWN_TODAY_KEY),
                                                withResetValue: 0))
    }

    // Each of the three checks below returns nil when the campaign still has room. It returns a
    // short sentence when a cap is full. See reasonCampaignIsHeldBack below.

    private func fullSessionCap(for campaignId: String,
                                maxPerSession: Int32,
                                excludeGlobalCaps: Bool) -> String? {
        // 1. Has this campaign hit its own session cap? excludeGlobalFCaps does not skip this one.
        // Native Display never sends mdc, so this check is skipped every time today. The parameter is
        // kept for a caller that does send one.
        if maxPerSession != kCTNdUncapped {
            let shownThisSession = Int32(impressionManager.perSession(campaignId))
            if shownThisSession >= maxPerSession {
                return "Its own session cap mdc is full at \(shownThisSession) of \(maxPerSession)"
            }
        }

        // 2. Has the account hit its session cap? excludeGlobalFCaps skips this one.
        if excludeGlobalCaps { return nil }
        let globalSessionMax = globalSessionMax()
        if globalSessionMax == kCTNdUncapped { return nil }
        let accountShownThisSession = Int32(impressionManager.perSessionTotal())
        if accountShownThisSession >= globalSessionMax {
            return "The account session cap ndmc is full at \(accountShownThisSession) of \(globalSessionMax)"
        }
        return nil
    }

    private func fullLifetimeCap(for campaignId: String, totalLifetimeCount: Int32) -> String? {
        if totalLifetimeCount == kCTNdUncapped { return nil }
        let shownEver = lifetimeCount(forCampaign: campaignId)
        if shownEver >= totalLifetimeCount {
            return "Its own lifetime cap tlc is full at \(shownEver) of \(totalLifetimeCount)"
        }
        return nil
    }

    private func fullDailyCap(for campaignId: String,
                              totalDailyCount: Int32,
                              excludeGlobalCaps: Bool) -> String? {
        // 1. Has the account hit its daily cap? This one is account-wide. excludeGlobalFCaps skips it.
        if !excludeGlobalCaps {
            let maxPerDayCount = maxPerDayCount()
            if maxPerDayCount != kCTNdUncapped {
                let accountShownToday = shownTodayCount()
                if accountShownToday >= maxPerDayCount {
                    return "The account daily cap ndmp is full at \(accountShownToday) of \(maxPerDayCount)"
                }
            }
        }

        // 2. Has this campaign hit its own daily cap? excludeGlobalFCaps does not skip this one.
        if totalDailyCount == kCTNdUncapped { return nil }
        let shownToday = todayCount(forCampaign: campaignId)
        if shownToday >= totalDailyCount {
            return "Its own daily cap tdc is full at \(shownToday) of \(totalDailyCount)"
        }
        return nil
    }

    /// Whether this campaign can be shown right now, under all the counting caps.
    ///
    /// - Parameters:
    ///   - campaignId: the `ti`. See `campaignId(from:)`.
    ///   - excludeFromCaps: `efc`. Skips every cap.
    ///   - excludeGlobalCaps: `excludeGlobalFCaps`. Skips only the two account caps. See the class
    ///     doc above for how the two flags differ.
    ///   - totalLifetimeCount: `tlc`, or -1 for no limit.
    ///   - totalDailyCount: `tdc`, or -1 for no limit.
    ///   - maxPerSession: `mdc`, or -1 for no limit.
    ///
    /// - Note: Native Display never sends `efc`, `tlc`, `tdc` or `mdc`. Those four belong to in-app.
    ///   A Native Display campaign puts its own cap in `frequencyLimits` or `occurrenceLimits`. The
    ///   gate in `CleverTap.m` passes these four parameters unset.
    @objc(canShowCampaign:excludeFromCaps:excludeGlobalCaps:totalLifetimeCount:totalDailyCount:maxPerSession:)
    func canShowCampaign(_ campaignId: String,
                         excludeFromCaps: Bool,
                         excludeGlobalCaps: Bool,
                         totalLifetimeCount: Int32,
                         totalDailyCount: Int32,
                         maxPerSession: Int32) -> Bool {
        return reasonCampaignIsHeldBack(campaignId,
                                        excludeFromCaps: excludeFromCaps,
                                        excludeGlobalCaps: excludeGlobalCaps,
                                        totalLifetimeCount: totalLifetimeCount,
                                        totalDailyCount: totalDailyCount,
                                        maxPerSession: maxPerSession) == nil
    }

    /// The same check as `canShowCampaign`, with the cap that blocked the campaign named.
    ///
    /// Returns nil when the campaign can still be shown. Returns a short sentence when a cap is
    /// full. The sentence names the cap and prints the count against the limit. It is written for a
    /// log line. Do not parse it. A caller that only needs a yes or no should use `canShowCampaign`.
    ///
    /// The parameters mean what they mean in `canShowCampaign`.
    @objc(reasonCampaignIsHeldBack:excludeFromCaps:excludeGlobalCaps:totalLifetimeCount:totalDailyCount:maxPerSession:)
    func reasonCampaignIsHeldBack(_ campaignId: String,
                                  excludeFromCaps: Bool,
                                  excludeGlobalCaps: Bool,
                                  totalLifetimeCount: Int32,
                                  totalDailyCount: Int32,
                                  maxPerSession: Int32) -> String? {
        if campaignId.isEmpty { return nil }

        // efc skips every cap. It can be answered here. excludeGlobalFCaps skips less. It is passed
        // down to each check instead.
        if excludeFromCaps { return nil }

        if let reason = fullSessionCap(for: campaignId,
                                       maxPerSession: maxPerSession,
                                       excludeGlobalCaps: excludeGlobalCaps) {
            return reason
        }

        if let reason = fullLifetimeCap(for: campaignId, totalLifetimeCount: totalLifetimeCount) {
            return reason
        }

        return fullDailyCap(for: campaignId,
                            totalDailyCount: totalDailyCount,
                            excludeGlobalCaps: excludeGlobalCaps)
    }

    /// Records one display: the impression, the campaign's daily and lifetime counts, and the day
    /// total.
    ///
    /// - Parameter storeTimestamp: whether to save the impression time on disk. Pass `true` only for
    ///   a campaign that has `frequencyLimits` or `occurrenceLimits`. See `CTImpressionManager`
    ///   `recordImpression:storeTimestamp:` for why.
    @objc(didShowCampaign:storeTimestamp:)
    func didShowCampaign(_ campaignId: String, storeTimestamp: Bool) {
        if campaignId.isEmpty { return }

        // Session counts always go up. The time is saved only when asked for.
        impressionManager.recordImpression(campaignId, storeTimestamp: storeTimestamp)

        // Add to the total shown today.
        incrementShownToday()

        // Add to this campaign's own daily and lifetime counts.
        lock.lock()
        // The two values are today's count then the lifetime count.
        if let counts = campaignCounts[campaignId] {
            campaignCounts[campaignId] = [counts[0] + 1, counts[1] + 1]
        } else {
            campaignCounts[campaignId] = [1, 1]
        }
        saveCampaignCounts()
        lock.unlock()

        // The app is the only source of these counts. No count changes until the app calls
        // recordDisplayUnitViewedEventForID:. This line is the proof that the call arrived. It also
        // prints the ndtlc and ndmp values the next request will carry.
        let campaignThisSession = impressionManager.perSession(campaignId)
        let campaignToday = todayCount(forCampaign: campaignId)
        let campaignSinceInstall = lifetimeCount(forCampaign: campaignId)
        let accountThisSession = impressionManager.perSessionTotal()
        let accountToday = shownTodayCount()
        log("""
            \(self): Counted a view of Native Display campaign \(campaignId). \
            This campaign has \(campaignThisSession) view(s) this session, \(campaignToday) today, \
            \(campaignSinceInstall) since install. \
            The whole account has \(accountThisSession) view(s) this session, \(accountToday) today. \
            The next request carries ndtlc ["\(campaignId)", \(campaignToday), \(campaignSinceInstall)] \
            for this campaign. The next request carries ndmp \(accountToday) for the account.
            """)
    }

    /// Saves the account limits the server sends with each response. Pass -1 for no limit.
    @objc(updateGlobalLimitsPerDay:andPerSession:)
    func updateGlobalLimits(perDay: Int32, andPerSession perSession: Int32) {
        CTPreferences.put(Int(perDay), forKey: storageKey(withSuffix: CLTAP_PREFS_ND_MAX_PER_DAY_KEY))
        CTPreferences.put(Int(perSession), forKey: storageKey(withSuffix: CLTAP_PREFS_ND_SESSION_MAX_KEY))

        // Which caps the account has is the first question to ask when Native Display stops
        // appearing.
        log("\(self): Native Display account caps set by the server. ndmc allows \(perSession) per session. ndmp allows \(perDay) per day. -1 means no limit.")
    }

    /// Deletes the counts, impressions and triggers for campaigns the server says are gone.
    ///
    /// The argument is `Any` and not an array on purpose. It carries whatever the server sent. A
    /// value of another shape is ignored.
    @objc(removeStaleCampaignCounts:)
    func removeStaleCampaignCounts(_ staleCampaigns: Any?) {
        guard let staleCampaigns = staleCampaigns as? [Any] else { return }

        lock.lock()
        defer { lock.unlock() }

        for stale in staleCampaigns {
            // The server sends these ids as numbers. Turn one into the string the stores key on.
            let campaignId = "\(stale)"
            // Counts, impressions and triggers are all stored under the campaign id. All three go.
            // Removing only the counts would leave the other two on disk forever.
            campaignCounts.removeValue(forKey: campaignId)
            impressionManager.removeImpressions(campaignId)
            triggerManager.removeTriggers(campaignId)
            log("\(self): Removed counts, triggers and impressions for Native Display campaign \(campaignId)")
        }
        saveCampaignCounts()
    }

    // MARK: - Counts

    @objc(todayCountForCampaign:)
    func todayCount(forCampaign campaignId: String) -> Int32 {
        lock.lock()
        defer { lock.unlock() }

        guard let counts = campaignCounts[campaignId], counts.count == 2 else { return 0 }
        return Int32(counts[0])
    }

    @objc(lifetimeCountForCampaign:)
    func lifetimeCount(forCampaign campaignId: String) -> Int32 {
        lock.lock()
        defer { lock.unlock() }

        guard let counts = campaignCounts[campaignId], counts.count == 2 else { return 0 }
        return Int32(counts[1])
    }

    private func incrementShownToday() {
        CTPreferences.put(Int(shownTodayCount()) + 1,
                             forKey: storageKey(withSuffix: CLTAP_PREFS_ND_COUNTS_SHOWN_TODAY_KEY))
    }

    // MARK: - Daily reset

    func todaysFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = CLTAP_DATE_FORMAT
        return formatter.string(from: Date())
    }

    private func shouldResetDailyCounters(_ today: String) -> Bool {
        let lastUpdate = CTPreferences.getStringForKey(storageKey(withSuffix: CLTAP_PREFS_ND_LAST_DATE_KEY),
                                                       withResetValue: "20140428")
        return today != lastUpdate
    }

    func resetDailyCounters(_ today: String) {
        CTPreferences.put(today, forKey: storageKey(withSuffix: CLTAP_PREFS_ND_LAST_DATE_KEY))

        CTPreferences.put(0, forKey: storageKey(withSuffix: CLTAP_PREFS_ND_COUNTS_SHOWN_TODAY_KEY))

        lock.lock()
        defer { lock.unlock() }

        // The two values are today's count then the lifetime count. Lifetime is not reset.
        campaignCounts = campaignCounts.mapValues { counts in [0, counts[1]] }
        saveCampaignCounts()
    }

    // MARK: - User switch

    private func deviceIdDidChange(_ newDeviceId: String) {
        lock.lock()
        deviceId = newDeviceId
        lock.unlock()

        initCampaignCounts()
        checkUpdateDailyLimits()
    }

    // MARK: - Batch header

    /// Builds the `ndmp` and `ndtlc` keys the next request carries.
    ///
    /// It is `@nonobjc` on purpose. `CTQueueType` belongs to the SDK's `Private` submodule, and the
    /// generated header cannot name a type from there. An `@objc` method that takes one would break
    /// every Objective-C file in the target. See the comment on CTNdDelegateObserver.
    @nonobjc
    func onBatchHeaderCreation(for queueType: CTQueueType) -> [String: Any] {
        // Check the date first. The day may have changed since the last count. The server applies
        // the caps from these numbers. Yesterday's totals would hide units the user should see
        // today.
        checkUpdateDailyLimits()

        var header: [String: Any] = [:]
        header[CLTAP_ND_SHOWN_TODAY_META_KEY] = NSNumber(value: shownTodayCount())

        lock.lock()
        // ndtlc: [[campaign id, today's count, lifetime count], ...]
        let counts: [[Any]] = campaignCounts.map { campaignId, value in
            [campaignId, NSNumber(value: value[0]), NSNumber(value: value[1])]
        }
        lock.unlock()

        header[CLTAP_ND_COUNTS_META_KEY] = counts
        return header
    }
}
