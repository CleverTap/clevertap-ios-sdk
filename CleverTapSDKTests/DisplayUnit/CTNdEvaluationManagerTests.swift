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

    @Test("An entry with no limits arrives every time, and its trigger is still counted")
    func anEntryWithNoLimitsArrivesEveryTime() {
        // Most App-Launched campaigns set no limits. The trigger is counted for them all the same.
        // The count is a lifetime total of the launches this campaign matched. A limit added to the
        // campaign later reads that total. A count that skipped the launches before the edit would
        // make onEvery and onExactly match at the wrong time.
        let entry = entry(ti: kCampaignId)

        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(triggerCount(kCampaignId) == 2)
    }

    @Test("Empty limit lists count as no limits")
    func emptyLimitListsCountAsNoLimits() {
        let entry = entry(ti: kCampaignId, extras: [
            CLTAP_INAPP_FC_LIMITS: [],
            CLTAP_INAPP_OCCURRENCE_LIMITS: []
        ])

        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(triggerCount(kCampaignId) == 1)
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

    // MARK: - Matching the triggers against the launch

    @Test("An entry whose triggers do not match this launch is dropped")
    func anEntryWhoseTriggersDoNotMatchIsDropped() {
        // The server sends this content before the launch happens. It cannot know what the launch
        // will look like. A campaign aimed at one app version must not arrive on every other one.
        let entry = entry(ti: kCampaignId, extras: [
            CLTAP_INAPP_TRIGGERS: [[
                "eventName": CLTAP_APP_LAUNCHED_EVENT,
                "eventProperties": [["propertyName": "appVersion", "operator": 1, "propertyValue": "5.2"]]
            ]]
        ])

        evaluationManager.evaluate(onEvent: CLTAP_APP_LAUNCHED_EVENT, withProps: ["appVersion": "4.0"])

        #expect(appLaunched([entry]) == [])
        // The trigger did not match. Nothing is counted for a launch the campaign did not qualify
        // for. onEvery reads this count.
        #expect(triggerCount(kCampaignId) == 0)
    }

    @Test("An entry whose triggers match this launch arrives")
    func anEntryWhoseTriggersMatchArrives() {
        let entry = entry(ti: kCampaignId, extras: [
            CLTAP_INAPP_TRIGGERS: [[
                "eventName": CLTAP_APP_LAUNCHED_EVENT,
                "eventProperties": [["propertyName": "appVersion", "operator": 1, "propertyValue": "5.2"]]
            ]]
        ])

        evaluationManager.evaluate(onEvent: CLTAP_APP_LAUNCHED_EVENT, withProps: ["appVersion": "5.2"])

        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(triggerCount(kCampaignId) == 1)
    }

    @Test("An entry with no triggers arrives, the launch itself is the trigger")
    func anEntryWithNoTriggersArrives() {
        // The matcher reads an empty list as no match. An entry without triggers must not go through
        // it. Most App-Launched campaigns are this shape.
        #expect(appLaunched([entry(ti: kCampaignId)]) == [kCampaignId])
    }

    @Test("The triggers are matched before the limits are read")
    func theTriggersAreMatchedBeforeTheLimitsAreRead() {
        // onEvery reads the trigger count. A launch the campaign did not qualify for must not move
        // that count. The campaign below qualifies on the second launch only. onEvery 2 then lets it
        // through on that same launch, because that is its first match.
        let entry = entry(ti: kCampaignId, extras: [
            CLTAP_INAPP_TRIGGERS: [[
                "eventName": CLTAP_APP_LAUNCHED_EVENT,
                "eventProperties": [["propertyName": "appVersion", "operator": 1, "propertyValue": "5.2"]]
            ]],
            CLTAP_INAPP_OCCURRENCE_LIMITS: [["type": "onEvery", "limit": 1]]
        ])

        evaluationManager.evaluate(onEvent: CLTAP_APP_LAUNCHED_EVENT, withProps: ["appVersion": "4.0"])
        #expect(appLaunched([entry]) == [])
        #expect(triggerCount(kCampaignId) == 0)

        evaluationManager.evaluate(onEvent: CLTAP_APP_LAUNCHED_EVENT, withProps: ["appVersion": "5.2"])
        #expect(appLaunched([entry]) == [kCampaignId])
        #expect(triggerCount(kCampaignId) == 1)
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

    // MARK: - Picking the top priority band

    /// One entry at the given priority. A nil priority leaves the key out, the way the server does
    /// when the campaign was saved without one.
    private func banded(_ ti: String, _ priority: Int?) -> [AnyHashable: Any] {
        guard let priority else { return entry(ti: ti) }
        return entry(ti: ti, extras: [CLTAP_INAPP_PRIORITY: NSNumber(value: priority)])
    }

    private func ids(_ entries: [[AnyHashable: Any]]) -> [String] {
        return entries.map { CTNdFCManager.campaignId(from: $0) }
    }

    @Test("Only the highest band is delivered")
    func onlyTheHighestBandIsDelivered() {
        let selection = evaluationManager.selectTopPriorityBand(
            content: [banded("70001", 3), banded("70002", 10), banded("70003", 5)],
            stubs: [])

        #expect(ids(selection.winners) == ["70002"])
        #expect(selection.controlGroupAcknowledgements.isEmpty)
    }

    @Test("Every entry in the highest band is delivered")
    func everyEntryInTheHighestBandIsDelivered() {
        // Two campaigns can hold the same priority. Neither one beats the other. Both arrive. Only
        // the band below them is dropped.
        let selection = evaluationManager.selectTopPriorityBand(
            content: [banded("70001", 10), banded("70002", 5), banded("70003", 10)],
            stubs: [])

        #expect(ids(selection.winners) == ["70001", "70003"])
    }

    @Test("A missing priority reads as one")
    func aMissingPriorityReadsAsOne() {
        // In-app uses the same default. An entry without the key must not beat an entry that set a
        // real priority.
        let selection = evaluationManager.selectTopPriorityBand(
            content: [banded("70001", nil), banded("70002", 2)],
            stubs: [])

        #expect(ids(selection.winners) == ["70002"])
    }

    @Test("Two entries in one band are ordered by ti, oldest first")
    func twoEntriesInOneBandAreOrderedByTiOldestFirst() {
        // A campaign id is an epoch timestamp. The smaller value is the older campaign. It goes
        // first. The order only shows when the account caps have room for one of the two.
        let selection = evaluationManager.selectTopPriorityBand(
            content: [banded("1791823174", 4), banded("1791788032", 4)],
            stubs: [])

        #expect(ids(selection.winners) == ["1791788032", "1791823174"])
    }

    @Test("A band holding only stubs does not end the walk")
    func aBandHoldingOnlyStubsDoesNotEndTheWalk() {
        // The user is in the control group for the top campaign. Nothing can be shown from that
        // band. The next band down is then read. Its content arrives.
        let selection = evaluationManager.selectTopPriorityBand(
            content: [banded("70002", 5)],
            stubs: [banded("70001", 10)])

        #expect(ids(selection.winners) == ["70002"])
        // The stub is still acknowledged. The campaign would have been shown to a user outside its
        // control group.
        #expect(ids(selection.controlGroupAcknowledgements) == ["70001"])
    }

    @Test("A stub below the winning band is not acknowledged")
    func aStubBelowTheWinningBandIsNotAcknowledged() {
        // The walk stops at the winning band. A campaign below it never had a turn. It would not
        // have been shown to a user outside its control group either. There is nothing to report.
        let selection = evaluationManager.selectTopPriorityBand(
            content: [banded("70001", 10)],
            stubs: [banded("70002", 3)])

        #expect(ids(selection.winners) == ["70001"])
        #expect(selection.controlGroupAcknowledgements.isEmpty)
    }

    @Test("A stub inside the winning band is acknowledged")
    func aStubInsideTheWinningBandIsAcknowledged() {
        let selection = evaluationManager.selectTopPriorityBand(
            content: [banded("70001", 10)],
            stubs: [banded("70002", 10)])

        #expect(ids(selection.winners) == ["70001"])
        #expect(ids(selection.controlGroupAcknowledgements) == ["70002"])
    }

    @Test("A response of nothing but stubs acknowledges them all")
    func aResponseOfNothingButStubsAcknowledgesThemAll() {
        // No band holds content. The walk reaches the end. Every stub is acknowledged.
        let selection = evaluationManager.selectTopPriorityBand(
            content: [],
            stubs: [banded("70001", 10), banded("70002", 3)])

        #expect(selection.winners.isEmpty)
        #expect(ids(selection.controlGroupAcknowledgements) == ["70001", "70002"])
    }

    @Test("Two empty lists come back empty")
    func twoEmptyListsComeBackEmpty() {
        let selection = evaluationManager.selectTopPriorityBand(content: [], stubs: [])

        #expect(selection.winners.isEmpty)
        #expect(selection.controlGroupAcknowledgements.isEmpty)
    }
}
