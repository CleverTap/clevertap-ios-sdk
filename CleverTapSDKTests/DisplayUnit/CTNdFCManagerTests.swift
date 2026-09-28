// CTNdFCManagerTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTNdFCManager.
//
// It replaces CTNdFCManagerTest.m. The old file needed CTNdFCManager+Tests.h to reach the counts and
// the two account limits. CTNdFCManager is written in Swift now, so @testable import reaches them
// instead. That category header is gone.
//
// The suite is a class and not a struct. Swift Testing makes one instance per test and runs deinit
// after it. NdHelper writes to NSUserDefaults, and tearDown is what removes those keys again.

import Testing
@testable import CleverTapSDK

/// The campaign id. Every store must use this as its key.
private let kCampaignId = "70001"
/// The same campaign's wzrk_id. Nothing should ever be stored under this.
private let kWzrkId = "70001_20260810"
/// A second campaign, for filling up the account caps without touching the first.
private let kOtherCampaignId = "70002"

@Suite("CTNdFCManager", .serialized)
final class CTNdFCManagerTests {

    private let helper: NdHelper
    private let fcManager: CTNdFCManager

    init() {
        // Nothing is set here. Each test gets its own account id, so both account limits start at
        // their default, which is off. A test that needs a limit sets it itself.
        helper = NdHelper()
        fcManager = helper.ndFCManager
    }

    deinit {
        helper.tearDown()
    }

    // MARK: - Helpers

    /// canShowCampaign with no caps set. A test then passes only the one value it cares about.
    private func canShow(_ campaignId: String) -> Bool {
        return fcManager.canShowCampaign(campaignId,
                                         excludeFromCaps: false,
                                         excludeGlobalCaps: false,
                                         totalLifetimeCount: -1,
                                         totalDailyCount: -1,
                                         maxPerSession: -1)
    }

    private func show(_ campaignId: String, times: Int) {
        for _ in 0..<times {
            fcManager.didShowCampaign(campaignId, storeTimestamp: true)
        }
    }

    // MARK: - The account limits are off until the server sends them

    @Test("Both account limits start off")
    func bothAccountLimitsStartOff() {
        // Read straight from storage, before anything has written to it. In-app defaults these to 1.
        // In-app gets away with it because imc and imp are on every response. ndmc and ndmp are not.
        #expect(fcManager.globalSessionMax() == -1)
        #expect(fcManager.maxPerDayCount() == -1)
    }

    @Test("An account with no limits sent shows as many units as it likes")
    func anAccountWithNoLimitsSentShowsAsManyUnitsAsItLikes() {
        // ndmc and ndmp are new keys. A response may not carry them. Nothing may be capped then.
        // A default of 1 here would hold every existing Display Units customer to one unit a session.
        show(kCampaignId, times: 50)
        show(kOtherCampaignId, times: 50)

        #expect(canShow(kCampaignId))
        #expect(canShow(kOtherCampaignId))
        #expect(fcManager.hasAccountCaps() == false)
    }

    @Test("The account limits apply to a unit that carries no cap settings")
    func theAccountLimitsApplyToAUnitThatCarriesNoCapSettings() {
        // This is the bug the marker check caused. The content the server sends for Native Display
        // carries no tlc, tdc, mdc or efc. The old code read that as "not capped" and skipped the
        // account limits too. The account limits belong to the account. The unit says nothing about
        // them.
        fcManager.updateGlobalLimits(perDay: -1, andPerSession: 2)
        show(kOtherCampaignId, times: 2)

        #expect(canShow(kCampaignId) == false)
        #expect(fcManager.hasAccountCaps())
    }

    @Test("hasAccountCaps is true when only one of the two is set")
    func hasAccountCapsIsTrueWhenOnlyOneOfTheTwoIsSet() {
        fcManager.updateGlobalLimits(perDay: 5, andPerSession: -1)
        #expect(fcManager.hasAccountCaps())

        fcManager.updateGlobalLimits(perDay: -1, andPerSession: 5)
        #expect(fcManager.hasAccountCaps())
    }

    // MARK: - efc and excludeGlobalFCaps are not the same flag

    @Test("excludeFromCaps skips every cap")
    func excludeFromCapsSkipsEveryCap() {
        // Every cap set as tight as it goes. Both account caps already used up.
        fcManager.updateGlobalLimits(perDay: 1, andPerSession: 1)
        show(kOtherCampaignId, times: 1)
        show(kCampaignId, times: 1)

        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: true,
                                          excludeGlobalCaps: false,
                                          totalLifetimeCount: 1,
                                          totalDailyCount: 1,
                                          maxPerSession: 1))
    }

    @Test("excludeGlobalCaps skips the account daily max but not the campaign's own caps")
    func excludeGlobalCapsSkipsTheAccountDailyMaxButNotTheCampaignsOwnCaps() {
        // The two flags skip different amounts. In-app treats them as one flag. This must not. Both
        // halves of the test start the same way. Only the flag changes.
        fcManager.updateGlobalLimits(perDay: 1, andPerSession: -1)
        show(kOtherCampaignId, times: 1)

        // The account daily cap is used up. Without the flag the campaign cannot show.
        #expect(canShow(kCampaignId) == false)

        // With the flag it can. That cap belongs to the account.
        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: true,
                                          totalLifetimeCount: -1,
                                          totalDailyCount: -1,
                                          maxPerSession: -1))

        // But its own lifetime cap still applies. This is the check both existing versions fail. They
        // treat this flag as if it were efc.
        show(kCampaignId, times: 1)
        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: true,
                                          totalLifetimeCount: 1,
                                          totalDailyCount: -1,
                                          maxPerSession: -1) == false)
    }

    @Test("excludeGlobalCaps still respects totalDailyCount")
    func excludeGlobalCapsStillRespectsTotalDailyCount() {
        fcManager.updateGlobalLimits(perDay: -1, andPerSession: -1)
        show(kCampaignId, times: 2)

        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: true,
                                          totalLifetimeCount: -1,
                                          totalDailyCount: 2,
                                          maxPerSession: -1) == false)
    }

    @Test("excludeGlobalCaps still respects maxPerSession")
    func excludeGlobalCapsStillRespectsMaxPerSession() {
        show(kCampaignId, times: 1)

        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: true,
                                          totalLifetimeCount: -1,
                                          totalDailyCount: -1,
                                          maxPerSession: 1) == false)
    }

    @Test("excludeGlobalCaps skips the account session max")
    func excludeGlobalCapsSkipsTheAccountSessionMax() {
        fcManager.updateGlobalLimits(perDay: -1, andPerSession: 1)
        show(kOtherCampaignId, times: 1)

        #expect(canShow(kCampaignId) == false)
        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: true,
                                          totalLifetimeCount: -1,
                                          totalDailyCount: -1,
                                          maxPerSession: -1))
    }

    // MARK: - The counting caps

    @Test("totalLifetimeCount blocks once reached")
    func totalLifetimeCountBlocksOnceReached() {
        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: false,
                                          totalLifetimeCount: 2,
                                          totalDailyCount: -1,
                                          maxPerSession: -1))
        show(kCampaignId, times: 2)
        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: false,
                                          totalLifetimeCount: 2,
                                          totalDailyCount: -1,
                                          maxPerSession: -1) == false)
    }

    @Test("Minus one means no limit")
    func minusOneMeansNoLimit() {
        show(kCampaignId, times: 20)
        #expect(canShow(kCampaignId))
    }

    /// An unset mdc used to fall back to a ceiling of 1000. That number was copied from in-app.
    /// Native Display never sends mdc, so the ceiling had no source. It is gone now. An unset mdc
    /// means no session limit at all. This count is above the old ceiling. The test would have
    /// failed before.
    @Test("An unset maxPerSession puts no ceiling on the session")
    func anUnsetMaxPerSessionPutsNoCeilingOnTheSession() {
        show(kCampaignId, times: 1001)
        #expect(canShow(kCampaignId))
    }

    @Test("The account daily max blocks every campaign")
    func theAccountDailyMaxBlocksEveryCampaign() {
        fcManager.updateGlobalLimits(perDay: 2, andPerSession: -1)
        show(kOtherCampaignId, times: 2)

        // Used up by a different campaign. That is the whole point of an account cap.
        #expect(canShow(kCampaignId) == false)
    }

    // MARK: - What happens when we cannot check

    @Test("A campaign with no id is allowed through")
    func aCampaignWithNoIdIsAllowedThrough() {
        // No id means nothing to store a count under. There is no cap to check. Holding it back
        // would hide a campaign for a reason nobody could see.
        #expect(canShow(""))
    }

    // MARK: - Counting a display

    @Test("didShowCampaign counts today, lifetime and the day total")
    func didShowCountsTodayLifetimeAndTheDayTotal() {
        fcManager.didShowCampaign(kCampaignId, storeTimestamp: true)

        #expect(fcManager.todayCount(forCampaign: kCampaignId) == 1)
        #expect(fcManager.lifetimeCount(forCampaign: kCampaignId) == 1)
        #expect(fcManager.shownTodayCount() == 1)
        #expect(fcManager.impressionManager.getImpressions(kCampaignId).count == 1)
    }

    @Test("Two viewed calls for the same unit count twice")
    func twoViewedCallsForTheSameUnitCountTwice() {
        // This is on purpose, not a bug. One call from the app is one impression. The SDK does not
        // remove repeats. It cannot tell a real second view from the same view reported twice.
        fcManager.didShowCampaign(kCampaignId, storeTimestamp: true)
        fcManager.didShowCampaign(kCampaignId, storeTimestamp: true)

        #expect(fcManager.todayCount(forCampaign: kCampaignId) == 2)
        #expect(fcManager.lifetimeCount(forCampaign: kCampaignId) == 2)
        #expect(fcManager.shownTodayCount() == 2)
        #expect(fcManager.impressionManager.getImpressions(kCampaignId).count == 2)
    }

    @Test("didShowCampaign ignores an empty campaign id")
    func didShowIgnoresAnEmptyCampaignId() {
        fcManager.didShowCampaign("", storeTimestamp: true)
        #expect(fcManager.shownTodayCount() == 0)
    }

    // MARK: - Which displays get their time saved

    @Test("A campaign with no limits gets no saved timestamp")
    func aCampaignWithNoLimitsGetsNoSavedTimestamp() {
        // Only frequencyLimits and occurrenceLimits ever read saved times. Saving one for a campaign
        // with neither would grow a list nobody reads. The app can report as many views as it likes.
        fcManager.didShowCampaign(kCampaignId, storeTimestamp: false)

        #expect(fcManager.impressionManager.getImpressions(kCampaignId).count == 0)

        // The counts that do not need saved times still had to happen.
        #expect(fcManager.todayCount(forCampaign: kCampaignId) == 1)
        #expect(fcManager.lifetimeCount(forCampaign: kCampaignId) == 1)
        #expect(fcManager.shownTodayCount() == 1)
        #expect(fcManager.impressionManager.perSession(kCampaignId) == 1)
        #expect(fcManager.impressionManager.perSessionTotal() == 1)
    }

    @Test("A campaign with limits gets a saved timestamp")
    func aCampaignWithLimitsGetsASavedTimestamp() {
        fcManager.didShowCampaign(kCampaignId, storeTimestamp: true)
        #expect(fcManager.impressionManager.getImpressions(kCampaignId).count == 1)
    }

    @Test("Session caps still work without saved timestamps")
    func sessionCapsStillWorkWithoutSavedTimestamps() {
        // The session counts live in memory. Saved times are off here. mdc must still hold.
        fcManager.didShowCampaign(kCampaignId, storeTimestamp: false)
        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: false,
                                          totalLifetimeCount: -1,
                                          totalDailyCount: -1,
                                          maxPerSession: 1) == false)
    }

    // MARK: - The change of day

    @Test("The daily reset zeroes today and keeps lifetime")
    func theDailyResetZeroesTodayAndKeepsLifetime() {
        show(kCampaignId, times: 3)

        fcManager.resetDailyCounters("20990101")

        #expect(fcManager.todayCount(forCampaign: kCampaignId) == 0)
        #expect(fcManager.lifetimeCount(forCampaign: kCampaignId) == 3)
        #expect(fcManager.shownTodayCount() == 0)
    }

    @Test("A lifetime cap survives the daily reset")
    func aLifetimeCapSurvivesTheDailyReset() {
        // The whole reason lifetime counts are kept when the day changes.
        show(kCampaignId, times: 1)
        fcManager.resetDailyCounters("20990101")

        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: false,
                                          totalLifetimeCount: 1,
                                          totalDailyCount: -1,
                                          maxPerSession: -1) == false)
    }

    @Test("checkUpdateDailyLimits does nothing twice in a day")
    func checkUpdateDailyLimitsDoesNothingTwiceInADay() {
        show(kCampaignId, times: 2)
        fcManager.checkUpdateDailyLimits()

        #expect(fcManager.todayCount(forCampaign: kCampaignId) == 2)
        #expect(fcManager.shownTodayCount() == 2)
    }

    // MARK: - Campaigns the server has finished with

    @Test("removeStaleCampaignCounts clears counts, impressions and triggers")
    func removeStaleCampaignCountsClearsCountsImpressionsAndTriggers() {
        show(kCampaignId, times: 2)
        fcManager.triggerManager.incrementTrigger(kCampaignId)

        // The server sends these ids as numbers. Pass one here to check we convert it.
        fcManager.removeStaleCampaignCounts([NSNumber(value: 70001)])

        #expect(fcManager.todayCount(forCampaign: kCampaignId) == 0)
        #expect(fcManager.lifetimeCount(forCampaign: kCampaignId) == 0)
        #expect(fcManager.impressionManager.getImpressions(kCampaignId).count == 0)
        #expect(fcManager.triggerManager.getTriggers(kCampaignId) == 0)
    }

    @Test("removeStaleCampaignCounts leaves other campaigns alone")
    func removeStaleCampaignCountsLeavesOtherCampaignsAlone() {
        show(kCampaignId, times: 1)
        show(kOtherCampaignId, times: 1)

        fcManager.removeStaleCampaignCounts([kCampaignId])

        #expect(fcManager.lifetimeCount(forCampaign: kCampaignId) == 0)
        #expect(fcManager.lifetimeCount(forCampaign: kOtherCampaignId) == 1)
    }

    // MARK: - The batch header

    @Test("The batch header carries the day total and the per campaign counts")
    func theBatchHeaderCarriesTheDayTotalAndThePerCampaignCounts() {
        show(kCampaignId, times: 2)
        // Stamp today. The header must not treat these counts as yesterday's and zero them.
        fcManager.resetDailyCounters(fcManager.todaysFormattedDate())
        show(kCampaignId, times: 1)

        let header = fcManager.onBatchHeaderCreation(for: CTQueueType.events)

        // ndmp is how many Native Display units were shown today.
        #expect(header[CLTAP_ND_SHOWN_TODAY_META_KEY] as? NSNumber == NSNumber(value: 1))

        // ndtlc is [[campaign id, today's count, lifetime count], ...].
        let counts = header[CLTAP_ND_COUNTS_META_KEY] as? [[Any]]
        #expect(counts?.count == 1)
        #expect(counts?.first as? NSArray == [kCampaignId, NSNumber(value: 1), NSNumber(value: 3)] as NSArray)
    }

    @Test("The batch header reports zero today when the day changed since the last count")
    func theBatchHeaderReportsZeroTodayWhenTheDayChangedSinceTheLastCount() {
        // Stamp an old day, then count under it. This is a batch sent just after midnight. No unit
        // was gated or counted after the day changed. That is the only way to reach the header
        // before the date is checked.
        fcManager.resetDailyCounters("20250101")
        show(kCampaignId, times: 2)

        let header = fcManager.onBatchHeaderCreation(for: CTQueueType.events)

        // The server applies the caps from these numbers. Yesterday's total must not go out.
        #expect(header[CLTAP_ND_SHOWN_TODAY_META_KEY] as? NSNumber == NSNumber(value: 0))

        let counts = header[CLTAP_ND_COUNTS_META_KEY] as? [[Any]]
        #expect(counts?.count == 1)
        #expect(counts?.first as? NSArray == [kCampaignId, NSNumber(value: 0), NSNumber(value: 2)] as NSArray)
    }

    @Test("The batch header is still well formed with nothing shown")
    func theBatchHeaderIsStillWellFormedWithNothingShown() {
        let header = fcManager.onBatchHeaderCreation(for: CTQueueType.events)

        #expect(header[CLTAP_ND_SHOWN_TODAY_META_KEY] as? NSNumber == NSNumber(value: 0))
        #expect((header[CLTAP_ND_COUNTS_META_KEY] as? [[Any]])?.isEmpty == true)
    }

    // MARK: - Which id the counts are stored under

    @Test("The campaign id comes from ti and never from wzrk_id")
    func campaignIdComesFromTiAndNeverFromWzrkId() {
        // The one check that would have caught the Android bug. Android reads the unit id. The unit
        // id is the wzrk_id. That key changes on every send of the campaign.
        let unit: [String: Any] = [CLTAP_INAPP_ID: NSNumber(value: 70001),
                                   CLTAP_NOTIFICATION_ID_TAG: kWzrkId]
        #expect(CTNdFCManager.campaignId(from: unit) == kCampaignId)
    }

    @Test("The campaign id accepts ti as a number or a string")
    func campaignIdAcceptsTiAsANumberOrAString() {
        // The content payload sends ti as a number, other payloads send it as a string.
        let asNumber: [String: Any] = [CLTAP_INAPP_ID: NSNumber(value: 70001)]
        let asString: [String: Any] = [CLTAP_INAPP_ID: "70001"]
        #expect(CTNdFCManager.campaignId(from: asNumber) == kCampaignId)
        #expect(CTNdFCManager.campaignId(from: asString) == kCampaignId)
    }

    @Test("The campaign id is empty when there is no ti")
    func campaignIdIsEmptyWhenThereIsNoTi() {
        // Empty, and not the wzrk_id instead. An empty id makes the check let the unit through. That
        // is the safer mistake. Using the wzrk_id would count under the wrong key without telling
        // anyone.
        let noTi: [String: Any] = [CLTAP_NOTIFICATION_ID_TAG: kWzrkId]
        #expect(CTNdFCManager.campaignId(from: noTi) == "")
        #expect(CTNdFCManager.campaignId(from: nil) == "")
        #expect(CTNdFCManager.campaignId(from: "not a dictionary") == "")
    }

    @Test("A unit with no ti is not capped")
    func aUnitWithNoTiIsNotCapped() {
        // The two rules above, put together. No ti gives an empty id. An empty id lets the unit show.
        let unit: [String: Any] = [CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
                                   CLTAP_INAPP_TOTAL_LIFETIME_COUNT: NSNumber(value: 0)]
        let campaignId = CTNdFCManager.campaignId(from: unit)

        #expect(fcManager.canShowCampaign(campaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: false,
                                          totalLifetimeCount: 0,
                                          totalDailyCount: 0,
                                          maxPerSession: 0))
    }

    @Test("Evaluate, gate and count all use the same campaign id")
    func evaluateThenGateThenCountAllUseTheSameCampaignId() {
        // Android does not have this test. Its NdFcapGateTest fakes the unit id. It never notices
        // that the three stores use different keys. That is how the Android check ended up reading
        // counts under wzrk_id while the evaluator saved triggers under ti.
        //
        // A wzrk_id changes on every send of the same campaign. A count saved under it goes back to
        // zero each time the campaign runs again.
        let rule: [String: Any] = [
            CLTAP_INAPP_ID: NSNumber(value: 70001),
            CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
            CLTAP_INAPP_TRIGGERS: [["eventName": "Product Viewed"]]
        ]
        helper.ndStore.storeServerSideNativeDisplays([rule])

        // Read the id off the unit the same way the check reads it. The whole chain is then tested. A
        // value the test made up would prove less.
        let campaignId = CTNdFCManager.campaignId(from: rule)
        #expect(campaignId == kCampaignId)

        // 1. Evaluate. Saves a trigger and adds the id to adUnit_eval.
        helper.evaluationManager.evaluate(onEvent: "Product Viewed", withProps: nil)

        #expect(helper.triggerManager.getTriggers(kCampaignId) == 1)
        let evalHeader = helper.evaluationManager.onBatchHeaderCreation(for: CTQueueType.events)
        #expect(evalHeader[CLTAP_ND_SS_EVAL_META_KEY] as? [NSNumber] == [NSNumber(value: 70001)])

        // 2. Check the caps. This reads the counts that the next step writes.
        #expect(canShow(campaignId))

        // 3. Count.
        fcManager.didShowCampaign(campaignId, storeTimestamp: true)

        // All three stores saved under the campaign id.
        #expect(helper.triggerManager.getTriggers(kCampaignId) == 1)
        #expect(fcManager.impressionManager.getImpressions(kCampaignId).count == 1)
        #expect(fcManager.lifetimeCount(forCampaign: kCampaignId) == 1)

        // And none of them saved under the wzrk_id. This is the check that fails on Android.
        #expect(helper.triggerManager.getTriggers(kWzrkId) == 0)
        #expect(fcManager.impressionManager.getImpressions(kWzrkId).count == 0)
        #expect(fcManager.lifetimeCount(forCampaign: kWzrkId) == 0)
        #expect(fcManager.campaignCounts[kWzrkId] == nil)
    }

    @Test("A cap counted under the campaign id is reached across sends")
    func aCapCountedUnderTheCampaignIdIsReachedAcrossSends() {
        // What the test above means in practice. Two sends of one campaign have the same ti but
        // different wzrk_ids. A lifetime cap of 1 has to stop the second send.
        fcManager.didShowCampaign(kCampaignId, storeTimestamp: false)

        #expect(fcManager.canShowCampaign(kCampaignId,
                                          excludeFromCaps: false,
                                          excludeGlobalCaps: false,
                                          totalLifetimeCount: 1,
                                          totalDailyCount: -1,
                                          maxPerSession: -1) == false)
    }

    // MARK: - Only one helper builds the id

    // The evaluator used to have its own copy of campaignIdFrom:. The two agreed on a normal ti and
    // disagreed on everything else. Triggers and impressions are written under the id one of them
    // returns and read back under the id the other returns. Any disagreement would stop the caps
    // matching, with nothing logged and nothing failing. The two tests below cover the cases where
    // the old copy behaved differently.

    @Test("A rule with an unusable ti is skipped instead of counted under a junk key")
    func aRuleWithAnUnusableTiIsSkippedInsteadOfCountedUnderAJunkKey() {
        // The old copy built the id with stringWithFormat:. That turns anything into a string. A ti
        // of an unexpected shape became a key like "{ ... }" and got a trigger saved under it.
        // campaignId(from:) checks the type instead. The rule is skipped. Nothing is written.
        let unusableTi: [String: Any] = ["unexpected": "shape"]
        let rule: [String: Any] = [
            CLTAP_INAPP_ID: unusableTi,
            CLTAP_INAPP_TRIGGERS: [["eventName": "Product Viewed"]]
        ]
        helper.ndStore.storeServerSideNativeDisplays([rule])

        helper.evaluationManager.evaluate(onEvent: "Product Viewed", withProps: nil)

        let junkKey = "\(unusableTi as NSDictionary)"
        #expect(helper.triggerManager.getTriggers(junkKey) == 0)

        let header = helper.evaluationManager.onBatchHeaderCreation(for: CTQueueType.events)
        #expect(header[CLTAP_ND_SS_EVAL_META_KEY] == nil)
    }

    @Test("A rule with no ti saves no trigger under an empty key")
    func aRuleWithNoTiSavesNoTriggerUnderAnEmptyKey() {
        // campaignId(from:) returns an empty string where the old copy returned nil. The evaluator
        // has to test the length. A plain nil check would never fire and every rule with no ti would
        // pile up on one shared empty key.
        let rule: [String: Any] = [
            CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
            CLTAP_INAPP_TRIGGERS: [["eventName": "Product Viewed"]]
        ]
        helper.ndStore.storeServerSideNativeDisplays([rule])

        helper.evaluationManager.evaluate(onEvent: "Product Viewed", withProps: nil)

        #expect(helper.triggerManager.getTriggers("") == 0)
        #expect(helper.triggerManager.getTriggers(kWzrkId) == 0)
    }

    // MARK: - Keeping Native Display and in-app apart

    @Test("Native Display counts do not touch the in-app stores")
    func nativeDisplayCountsDoNotTouchTheInAppStores() {
        // Both channels use these two classes. The storage name is the only thing keeping them apart.
        show(kCampaignId, times: 1)

        let inAppImpressions = CTImpressionManager(accountId: helper.accountId,
                                                  deviceId: helper.deviceId,
                                                  delegateManager: helper.delegateManager)
        let inAppTriggers = CTInAppTriggerManager(accountId: helper.accountId,
                                                 deviceId: helper.deviceId,
                                                 delegateManager: helper.delegateManager)

        #expect(inAppImpressions.getImpressions(kCampaignId).count == 0)
        #expect(inAppTriggers.getTriggers(kCampaignId) == 0)
    }
}
