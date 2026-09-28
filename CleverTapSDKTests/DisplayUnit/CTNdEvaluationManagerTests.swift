// CTNdEvaluationManagerTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTNdEvaluationManager.
//
// It covers retainAppLaunchedWithinLimits. App-Launched campaigns are not listed in
// adUnit_notifs_ss. Each entry carries its own frequencyLimits and occurrenceLimits. The SDK never
// reports them in adUnit_eval. That method is the only place those limits are applied.
//
// The suite is a class and not a struct, for the reason given on CTNdFCManagerTests.

import Testing
@testable import CleverTapSDK

/// The campaign id. This is `ti`. Triggers and impressions are both keyed on it.
private let kCampaignId = "70001"
/// The same campaign's wzrk_id. It is `ti` plus a suffix that changes on every send.
private let kWzrkId = "70001_20260810"
/// A second campaign, for checking that one entry's limits do not reach the others.
private let kOtherCampaignId = "70002"

@Suite("CTNdEvaluationManager", .serialized)
final class CTNdEvaluationManagerTests {

    private let helper: NdHelper
    private let evaluationManager: CTNdEvaluationManager

    init() {
        helper = NdHelper()
        evaluationManager = helper.evaluationManager
    }

    deinit {
        helper.tearDown()
    }

    // MARK: - Helpers

    /// One raw entry, in the shape the server sends inside `adUnit_notifs_applaunched`. The limits
    /// are added through the extras argument. The filter reads entries, not display units.
    private func entry(ti: String, extras: [AnyHashable: Any] = [:]) -> [AnyHashable: Any] {
        var entry: [AnyHashable: Any] = [
            CLTAP_INAPP_ID: NSNumber(value: Int(ti) ?? 0),
            CLTAP_NOTIFICATION_ID_TAG: "\(ti)_20260810",
            "type": "simple"
        ]
        entry.merge(extras) { _, fromExtras in fromExtras }
        return entry
    }

    private func onEvery(_ limit: Int) -> [AnyHashable: Any] {
        return [CLTAP_INAPP_OCCURRENCE_LIMITS: [["type": "onEvery", "limit": limit]]]
    }

    /// Runs the filter. Returns the campaign ids that came through, in the order they came through.
    private func appLaunched(_ entries: [[AnyHashable: Any]]) -> [String] {
        return evaluationManager.retainAppLaunchedWithinLimits(entries).map {
            CTNdFCManager.campaignId(from: $0)
        }
    }

    private func triggerCount(_ campaignId: String) -> Int {
        return Int(helper.triggerManager.getTriggers(campaignId))
    }

    // MARK: - Entries that set no limits

    @Test("An entry with no limits arrives every time")
    func anEntryWithNoLimitsArrivesEveryTime() {
        // Most App-Launched campaigns set no limits. Counting a trigger for them would cost a write
        // on every launch. Nothing would ever read it.
        let entry = entry(ti: kCampaignId)

        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(triggerCount(kCampaignId) == 0)
    }

    @Test("Empty limit lists count as no limits")
    func emptyLimitListsCountAsNoLimits() {
        let entry = entry(ti: kCampaignId, extras: [
            CLTAP_INAPP_FC_LIMITS: [],
            CLTAP_INAPP_OCCURRENCE_LIMITS: []
        ])

        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(triggerCount(kCampaignId) == 0)
    }

    @Test("An entry with no ti arrives, and nothing is counted for it")
    func anEntryWithNoTiArrives() {
        // No ti means there is no key to count a trigger under. Two campaigns with no ti would share
        // one count. No limit can be checked. Letting the entry through is the safer mistake.
        let noTi: [AnyHashable: Any] = [
            CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
            "type": "simple",
            CLTAP_INAPP_OCCURRENCE_LIMITS: [["type": "onEvery", "limit": 2]]
        ]

        #expect(evaluationManager.retainAppLaunchedWithinLimits([noTi]).count == 1)
        #expect(triggerCount("") == 0)
    }

    // MARK: - Limits counted in triggers

    @Test("An onEvery limit of two lets every second arrival through")
    func anOnEveryLimitOfTwoLetsEverySecondArrivalThrough() {
        // The bug this filter fixes. The SDK never reports an App-Launched campaign in adUnit_eval.
        // Nothing else applies these limits. Before the filter the entry arrived on all four
        // launches.
        let entry = entry(ti: kCampaignId, extras: onEvery(2))

        // onEvery reads the trigger count. It is not the view count. It goes up on every arrival.
        #expect(appLaunched([entry]) == [])
        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(appLaunched([entry]) == [])
        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(triggerCount(kCampaignId) == 4)
    }

    @Test("The trigger count is kept under ti and not under wzrk_id")
    func theTriggerCountIsKeptUnderTi() {
        // A wzrk_id is the ti plus a suffix. The suffix changes on every send. A count under it
        // would go back to zero every time the campaign runs again. onEvery would never match.
        _ = appLaunched([entry(ti: kCampaignId, extras: onEvery(2))])

        #expect(triggerCount(kCampaignId) == 1)
        #expect(triggerCount(kWzrkId) == 0)
    }

    // MARK: - Limits counted in saved view times

    @Test("A time window limit reads the saved view times")
    func aTimeWindowLimitReadsTheSavedViewTimes() {
        // A frequencyLimits of type hours is matched against the times saved for the campaign. Those
        // times are saved when the app reports a view. The arrival itself saves nothing.
        let entry = entry(ti: kCampaignId, extras: [
            CLTAP_INAPP_FC_LIMITS: [["type": "hours", "limit": 2, "frequency": 1]]
        ])

        helper.impressionManager.recordImpression(kCampaignId, storeTimestamp: true)
        #expect(appLaunched([entry]) == [kCampaignId])

        helper.impressionManager.recordImpression(kCampaignId, storeTimestamp: true)
        #expect(appLaunched([entry]) == [])
    }

    // MARK: - One entry does not reach the others

    @Test("Only the entry over its limit is dropped, and the order is kept")
    func onlyTheEntryOverItsLimitIsDropped() {
        let overLimit = entry(ti: kCampaignId, extras: [
            CLTAP_INAPP_OCCURRENCE_LIMITS: [["type": "onExactly", "limit": 9]]
        ])
        let noLimits = entry(ti: kOtherCampaignId)
        let thirdEntry = entry(ti: "70003")

        #expect(appLaunched([overLimit, noLimits, thirdEntry]) == [kOtherCampaignId, "70003"])
    }

    @Test("An empty list comes back empty")
    func anEmptyListComesBackEmpty() {
        #expect(evaluationManager.retainAppLaunchedWithinLimits([]).isEmpty)
    }
}
