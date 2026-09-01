//
//  CTNdFCManagerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTConstants.h"
#import "CTImpressionManager.h"
#import "CTInAppTriggerManager.h"
#import "CTNdFCManager.h"
#import "CTNdEvaluationManager.h"
#import "CTNdStore.h"
#import "NdHelper.h"
#import "CTNdFCManager+Tests.h"

/// The campaign id. Every store must use this as its key.
static NSString *const kCampaignId = @"70001";
/// The same campaign's wzrk_id. Nothing should ever be stored under this.
static NSString *const kWzrkId = @"70001_20260810";
/// A second campaign, for filling up the account caps without touching the first.
static NSString *const kOtherCampaignId = @"70002";

@interface CTNdFCManagerTest : XCTestCase
@property (nonatomic, strong) NdHelper *helper;
@property (nonatomic, strong) CTNdFCManager *fcManager;
@end

@implementation CTNdFCManagerTest

- (void)setUp {
    [super setUp];
    self.helper = [NdHelper new];
    self.fcManager = self.helper.ndFCManager;

    // Both account caps start at 1, which would block almost everything. Most tests here are about
    // the per campaign caps, so turn these off and let the tests that need them set them.
    [self.fcManager updateGlobalLimitsPerDay:-1 andPerSession:-1];
}

- (void)tearDown {
    [self.helper tearDown];
    [super tearDown];
}

#pragma mark Helpers

/// canShowCampaign with no caps set, so a test only has to pass the one value it cares about.
- (BOOL)canShow:(NSString *)campaignId {
    return [self.fcManager canShowCampaign:campaignId
                         excludeFromCaps:NO
                       excludeGlobalCaps:NO
                      totalLifetimeCount:-1
                         totalDailyCount:-1
                           maxPerSession:-1];
}

- (void)show:(NSString *)campaignId times:(int)times {
    for (int i = 0; i < times; i++) {
        [self.fcManager didShowCampaign:campaignId storeTimestamp:YES];
    }
}

#pragma mark hasFrequencyCaps

- (void)testHasFrequencyCapsRecognisesEachMarkerOnItsOwn {
    NSArray *markers = @[
        CLTAP_INAPP_EXCLUDE_FROM_CAPS,
        CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS,
        CLTAP_INAPP_TOTAL_LIFETIME_COUNT,
        CLTAP_INAPP_TOTAL_DAILY_COUNT,
        CLTAP_INAPP_MAX_PER_SESSION
    ];
    for (NSString *marker in markers) {
        // Built outside the assert. Inside it, the commas in the literal would be read as extra
        // arguments to the macro.
        NSDictionary *unit = @{ CLTAP_INAPP_ID: kCampaignId, marker: @1 };
        XCTAssertTrue([CTNdFCManager hasFrequencyCaps:unit],
                      @"%@ on its own should be enough to make a unit capped", marker);
    }
}

- (void)testHasFrequencyCapsIsFalseForAUnitWithNoMarkers {
    // Display units that already exist have none of these and must keep working untouched. They
    // must also not add to the account's daily and session totals.
    NSDictionary *unit = @{ CLTAP_INAPP_ID: kCampaignId, @"type": @"banner", @"msg": @{} };
    XCTAssertFalse([CTNdFCManager hasFrequencyCaps:unit]);
}

- (void)testHasFrequencyCapsIsFalseForANonDictionary {
    XCTAssertFalse([CTNdFCManager hasFrequencyCaps:nil]);
    XCTAssertFalse([CTNdFCManager hasFrequencyCaps:(NSDictionary *)@"not a dictionary"]);
}

#pragma mark efc and excludeGlobalFCaps are not the same flag

- (void)testExcludeFromCapsSkipsEveryCap {
    // Every cap set as tight as it goes, and both account caps already used up.
    [self.fcManager updateGlobalLimitsPerDay:1 andPerSession:1];
    [self show:kOtherCampaignId times:1];
    [self show:kCampaignId times:1];

    XCTAssertTrue([self.fcManager canShowCampaign:kCampaignId
                                excludeFromCaps:YES
                              excludeGlobalCaps:NO
                             totalLifetimeCount:1
                                totalDailyCount:1
                                  maxPerSession:1]);
}

- (void)testExcludeGlobalCapsSkipsTheAccountDailyMaxButNotTheCampaignsOwnCaps {
    // The two flags skip different amounts. In-app treats them as one flag. This must not. Both
    // halves of the test start the same way, and only the flag changes.
    [self.fcManager updateGlobalLimitsPerDay:1 andPerSession:-1];
    [self show:kOtherCampaignId times:1];

    // The account daily cap is used up, so without the flag the campaign cannot show.
    XCTAssertFalse([self canShow:kCampaignId]);

    // With the flag it can, because that cap belongs to the account.
    XCTAssertTrue([self.fcManager canShowCampaign:kCampaignId
                                excludeFromCaps:NO
                              excludeGlobalCaps:YES
                             totalLifetimeCount:-1
                                totalDailyCount:-1
                                  maxPerSession:-1]);

    // But its own lifetime cap still applies. This is the check both existing versions fail,
    // because they treat this flag as if it were efc.
    [self show:kCampaignId times:1];
    XCTAssertFalse([self.fcManager canShowCampaign:kCampaignId
                                 excludeFromCaps:NO
                               excludeGlobalCaps:YES
                              totalLifetimeCount:1
                                 totalDailyCount:-1
                                   maxPerSession:-1]);
}

- (void)testExcludeGlobalCapsStillRespectsTotalDailyCount {
    [self.fcManager updateGlobalLimitsPerDay:-1 andPerSession:-1];
    [self show:kCampaignId times:2];

    XCTAssertFalse([self.fcManager canShowCampaign:kCampaignId
                                 excludeFromCaps:NO
                               excludeGlobalCaps:YES
                              totalLifetimeCount:-1
                                 totalDailyCount:2
                                   maxPerSession:-1]);
}

- (void)testExcludeGlobalCapsStillRespectsMaxPerSession {
    [self show:kCampaignId times:1];

    XCTAssertFalse([self.fcManager canShowCampaign:kCampaignId
                                 excludeFromCaps:NO
                               excludeGlobalCaps:YES
                              totalLifetimeCount:-1
                                 totalDailyCount:-1
                                   maxPerSession:1]);
}

- (void)testExcludeGlobalCapsSkipsTheAccountSessionMax {
    [self.fcManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:kOtherCampaignId times:1];

    XCTAssertFalse([self canShow:kCampaignId]);
    XCTAssertTrue([self.fcManager canShowCampaign:kCampaignId
                                excludeFromCaps:NO
                              excludeGlobalCaps:YES
                             totalLifetimeCount:-1
                                totalDailyCount:-1
                                  maxPerSession:-1]);
}

#pragma mark The counting caps

- (void)testTotalLifetimeCountBlocksOnceReached {
    XCTAssertTrue([self.fcManager canShowCampaign:kCampaignId excludeFromCaps:NO excludeGlobalCaps:NO
                             totalLifetimeCount:2 totalDailyCount:-1 maxPerSession:-1]);
    [self show:kCampaignId times:2];
    XCTAssertFalse([self.fcManager canShowCampaign:kCampaignId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:2 totalDailyCount:-1 maxPerSession:-1]);
}

- (void)testMinusOneMeansNoLimit {
    [self show:kCampaignId times:20];
    XCTAssertTrue([self canShow:kCampaignId]);
}

- (void)testTheAccountDailyMaxBlocksEveryCampaign {
    [self.fcManager updateGlobalLimitsPerDay:2 andPerSession:-1];
    [self show:kOtherCampaignId times:2];

    // Used up by a different campaign, which is the whole point of an account cap.
    XCTAssertFalse([self canShow:kCampaignId]);
}

#pragma mark What happens when we cannot check

- (void)testACampaignWithNoIdIsAllowedThrough {
    // No id means nothing to store a count under, so there is no cap to check. Holding it back
    // would hide a campaign for a reason nobody could see.
    XCTAssertTrue([self canShow:@""]);
}

#pragma mark Counting a display

- (void)testDidShowCountsTodayLifetimeAndTheDayTotal {
    [self.fcManager didShowCampaign:kCampaignId storeTimestamp:YES];

    XCTAssertEqual(1, [self.fcManager todayCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.fcManager shownTodayCount]);
    XCTAssertEqual(1, [[self.fcManager.impressionManager getImpressions:kCampaignId] count]);
}

- (void)testTwoViewedCallsForTheSameUnitCountTwice {
    // This is on purpose, not a bug. One call from the app is one impression. The SDK does not
    // remove repeats, because it cannot tell a real second view from the same view reported twice.
    [self.fcManager didShowCampaign:kCampaignId storeTimestamp:YES];
    [self.fcManager didShowCampaign:kCampaignId storeTimestamp:YES];

    XCTAssertEqual(2, [self.fcManager todayCountForCampaign:kCampaignId]);
    XCTAssertEqual(2, [self.fcManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(2, [self.fcManager shownTodayCount]);
    XCTAssertEqual(2, [[self.fcManager.impressionManager getImpressions:kCampaignId] count]);
}

- (void)testDidShowIgnoresAnEmptyCampaignId {
    [self.fcManager didShowCampaign:@"" storeTimestamp:YES];
    XCTAssertEqual(0, [self.fcManager shownTodayCount]);
}

#pragma mark Which displays get their time saved

- (void)testACampaignWithNoLimitsGetsNoSavedTimestamp {
    // Only frequencyLimits and occurrenceLimits ever read saved times. Saving one for a campaign
    // with neither would grow a list nobody reads, and the app can report as many views as it likes.
    [self.fcManager didShowCampaign:kCampaignId storeTimestamp:NO];

    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kCampaignId] count]);

    // The counts that do not need saved times still had to happen.
    XCTAssertEqual(1, [self.fcManager todayCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.fcManager shownTodayCount]);
    XCTAssertEqual(1, [self.fcManager.impressionManager perSession:kCampaignId]);
    XCTAssertEqual(1, [self.fcManager.impressionManager perSessionTotal]);
}

- (void)testACampaignWithLimitsGetsASavedTimestamp {
    [self.fcManager didShowCampaign:kCampaignId storeTimestamp:YES];
    XCTAssertEqual(1, [[self.fcManager.impressionManager getImpressions:kCampaignId] count]);
}

- (void)testSessionCapsStillWorkWithoutSavedTimestamps {
    // The session counts live in memory, so turning off saved times must not weaken mdc.
    [self.fcManager didShowCampaign:kCampaignId storeTimestamp:NO];
    XCTAssertFalse([self.fcManager canShowCampaign:kCampaignId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:-1 totalDailyCount:-1 maxPerSession:1]);
}

#pragma mark The change of day

- (void)testTheDailyResetZeroesTodayAndKeepsLifetime {
    [self show:kCampaignId times:3];

    [self.fcManager resetDailyCounters:@"20990101"];

    XCTAssertEqual(0, [self.fcManager todayCountForCampaign:kCampaignId]);
    XCTAssertEqual(3, [self.fcManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(0, [self.fcManager shownTodayCount]);
}

- (void)testALifetimeCapSurvivesTheDailyReset {
    // The whole reason lifetime counts are kept when the day changes.
    [self show:kCampaignId times:1];
    [self.fcManager resetDailyCounters:@"20990101"];

    XCTAssertFalse([self.fcManager canShowCampaign:kCampaignId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:1 totalDailyCount:-1 maxPerSession:-1]);
}

- (void)testCheckUpdateDailyLimitsDoesNothingTwiceInADay {
    [self show:kCampaignId times:2];
    [self.fcManager checkUpdateDailyLimits];

    XCTAssertEqual(2, [self.fcManager todayCountForCampaign:kCampaignId]);
    XCTAssertEqual(2, [self.fcManager shownTodayCount]);
}

#pragma mark Campaigns the server has finished with

- (void)testRemoveStaleCampaignCountsClearsCountsImpressionsAndTriggers {
    [self show:kCampaignId times:2];
    [self.fcManager.triggerManager incrementTrigger:kCampaignId];

    // The server sends these ids as numbers, so pass one here to check we convert it.
    [self.fcManager removeStaleCampaignCounts:@[@70001]];

    XCTAssertEqual(0, [self.fcManager todayCountForCampaign:kCampaignId]);
    XCTAssertEqual(0, [self.fcManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kCampaignId] count]);
    XCTAssertEqual(0, [self.fcManager.triggerManager getTriggers:kCampaignId]);
}

- (void)testRemoveStaleCampaignCountsLeavesOtherCampaignsAlone {
    [self show:kCampaignId times:1];
    [self show:kOtherCampaignId times:1];

    [self.fcManager removeStaleCampaignCounts:@[kCampaignId]];

    XCTAssertEqual(0, [self.fcManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForCampaign:kOtherCampaignId]);
}

#pragma mark The batch header

- (void)testTheBatchHeaderCarriesTheDayTotalAndThePerCampaignCounts {
    [self show:kCampaignId times:2];
    [self.fcManager resetDailyCounters:@"20990101"];
    [self show:kCampaignId times:1];

    NSDictionary *header = [self.fcManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];

    // ndmp is how many Native Display units were shown today.
    XCTAssertEqualObjects(@1, header[CLTAP_ND_SHOWN_TODAY_META_KEY]);

    // ndtlc is [[campaign id, today's count, lifetime count], ...].
    NSArray *counts = header[CLTAP_ND_COUNTS_META_KEY];
    XCTAssertEqual(1, counts.count);
    NSArray *expected = @[kCampaignId, @1, @3];
    XCTAssertEqualObjects(expected, counts[0]);
}

- (void)testTheBatchHeaderIsStillWellFormedWithNothingShown {
    NSDictionary *header = [self.fcManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];

    XCTAssertEqualObjects(@0, header[CLTAP_ND_SHOWN_TODAY_META_KEY]);
    XCTAssertEqualObjects(@[], header[CLTAP_ND_COUNTS_META_KEY]);
}

#pragma mark Which id the counts are stored under

- (void)testCampaignIdComesFromTiAndNeverFromWzrkId {
    // The one check that would have caught the Android bug. Android reads the unit id, which is the
    // wzrk_id, so it saves counts under a key that changes on every send of the campaign.
    NSDictionary *unit = @{ CLTAP_INAPP_ID: @70001, CLTAP_NOTIFICATION_ID_TAG: kWzrkId };
    XCTAssertEqualObjects(kCampaignId, [CTNdFCManager campaignIdFrom:unit]);
}

- (void)testCampaignIdAcceptsTiAsANumberOrAString {
    // The content payload sends ti as a number, other payloads send it as a string.
    NSDictionary *asNumber = @{ CLTAP_INAPP_ID: @70001 };
    NSDictionary *asString = @{ CLTAP_INAPP_ID: @"70001" };
    XCTAssertEqualObjects(kCampaignId, [CTNdFCManager campaignIdFrom:asNumber]);
    XCTAssertEqualObjects(kCampaignId, [CTNdFCManager campaignIdFrom:asString]);
}

- (void)testCampaignIdIsEmptyWhenThereIsNoTi {
    // Empty, and not the wzrk_id instead. An empty id makes the check let the unit through, which is
    // the safer mistake. Using the wzrk_id would count under the wrong key without telling anyone.
    NSDictionary *noTi = @{ CLTAP_NOTIFICATION_ID_TAG: kWzrkId };
    XCTAssertEqualObjects(@"", [CTNdFCManager campaignIdFrom:noTi]);
    XCTAssertEqualObjects(@"", [CTNdFCManager campaignIdFrom:nil]);
    XCTAssertEqualObjects(@"", [CTNdFCManager campaignIdFrom:(NSDictionary *)@"not a dictionary"]);
}

- (void)testAUnitWithNoTiIsNotCapped {
    // The two rules above, put together. No ti gives an empty id, and an empty id lets the unit show.
    NSDictionary *unit = @{ CLTAP_NOTIFICATION_ID_TAG: kWzrkId, CLTAP_INAPP_TOTAL_LIFETIME_COUNT: @0 };
    NSString *campaignId = [CTNdFCManager campaignIdFrom:unit];

    XCTAssertTrue([self.fcManager canShowCampaign:campaignId excludeFromCaps:NO excludeGlobalCaps:NO
                             totalLifetimeCount:0 totalDailyCount:0 maxPerSession:0]);
}

- (void)testEvaluateThenGateThenCountAllUseTheSameCampaignId {
    // Android does not have this test. Its NdFcapGateTest fakes the unit id, so it never notices
    // that the three stores use different keys. That is how the Android check ended up reading
    // counts under wzrk_id while the evaluator saved triggers under ti.
    //
    // A wzrk_id changes on every send of the same campaign, so a count saved under it goes back to
    // zero each time the campaign runs again.
    NSDictionary *rule = @{
        CLTAP_INAPP_ID: @70001,
        CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
        CLTAP_INAPP_TRIGGERS: @[@{ @"eventName": @"Product Viewed" }]
    };
    [self.helper.ndStore storeServerSideNativeDisplays:@[rule]];

    // Read off the unit the same way the check reads it, so the whole chain is tested instead of a
    // value the test made up.
    NSString *campaignId = [CTNdFCManager campaignIdFrom:rule];
    XCTAssertEqualObjects(kCampaignId, campaignId);

    // 1. Evaluate. Saves a trigger and adds the id to adUnit_eval.
    [self.helper.evaluationManager evaluateOnEvent:@"Product Viewed" withProps:nil];

    XCTAssertEqual(1, [self.helper.triggerManager getTriggers:kCampaignId]);
    NSDictionary *evalHeader = [self.helper.evaluationManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];
    XCTAssertEqualObjects(@[@70001], evalHeader[CLTAP_ND_SS_EVAL_META_KEY]);

    // 2. Check the caps. This reads the counts that the next step writes.
    XCTAssertTrue([self canShow:campaignId]);

    // 3. Count.
    [self.fcManager didShowCampaign:campaignId storeTimestamp:YES];

    // All three stores saved under the campaign id.
    XCTAssertEqual(1, [self.helper.triggerManager getTriggers:kCampaignId]);
    XCTAssertEqual(1, [[self.fcManager.impressionManager getImpressions:kCampaignId] count]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForCampaign:kCampaignId]);

    // And none of them saved under the wzrk_id. This is the check that fails on Android.
    XCTAssertEqual(0, [self.helper.triggerManager getTriggers:kWzrkId]);
    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kWzrkId] count]);
    XCTAssertEqual(0, [self.fcManager lifetimeCountForCampaign:kWzrkId]);
    XCTAssertNil(self.fcManager.campaignCounts[kWzrkId]);
}

- (void)testACapCountedUnderTheCampaignIdIsReachedAcrossSends {
    // What the test above means in practice. Two sends of one campaign have the same ti but
    // different wzrk_ids, so a lifetime cap of 1 has to stop the second send.
    [self.fcManager didShowCampaign:kCampaignId storeTimestamp:NO];

    XCTAssertFalse([self.fcManager canShowCampaign:kCampaignId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:1 totalDailyCount:-1 maxPerSession:-1]);
}

#pragma mark Only one helper builds the id

// The evaluator used to have its own copy of campaignIdFrom:. The two agreed on a normal ti and
// disagreed on everything else. Triggers and impressions are written under the id one of them
// returns and read back under the id the other returns, so any disagreement would stop the caps
// matching, with nothing logged and nothing failing. The two tests below cover the cases where the
// old copy behaved differently.

- (void)testARuleWithAnUnusableTiIsSkippedInsteadOfCountedUnderAJunkKey {
    // The old copy built the id with stringWithFormat:, which turns anything into a string. A ti of
    // an unexpected shape became a key like "{ ... }" and got a trigger saved under it.
    // campaignIdFrom: checks the type instead, so the rule is skipped and nothing is written.
    NSDictionary *rule = @{
        CLTAP_INAPP_ID: @{ @"unexpected": @"shape" },
        CLTAP_INAPP_TRIGGERS: @[@{ @"eventName": @"Product Viewed" }]
    };
    [self.helper.ndStore storeServerSideNativeDisplays:@[rule]];

    [self.helper.evaluationManager evaluateOnEvent:@"Product Viewed" withProps:nil];

    NSString *junkKey = [NSString stringWithFormat:@"%@", rule[CLTAP_INAPP_ID]];
    XCTAssertEqual(0, [self.helper.triggerManager getTriggers:junkKey]);

    NSDictionary *header = [self.helper.evaluationManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];
    XCTAssertNil(header[CLTAP_ND_SS_EVAL_META_KEY]);
}

- (void)testARuleWithNoTiSavesNoTriggerUnderAnEmptyKey {
    // campaignIdFrom: returns an empty string where the old copy returned nil, so the evaluator has
    // to test the length. A plain nil check would never fire and every rule with no ti would pile up
    // on one shared empty key.
    NSDictionary *rule = @{
        CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
        CLTAP_INAPP_TRIGGERS: @[@{ @"eventName": @"Product Viewed" }]
    };
    [self.helper.ndStore storeServerSideNativeDisplays:@[rule]];

    [self.helper.evaluationManager evaluateOnEvent:@"Product Viewed" withProps:nil];

    XCTAssertEqual(0, [self.helper.triggerManager getTriggers:@""]);
    XCTAssertEqual(0, [self.helper.triggerManager getTriggers:kWzrkId]);
}

#pragma mark Keeping Native Display and in-app apart

- (void)testNativeDisplayCountsDoNotTouchTheInAppStores {
    // Both channels use these two classes. The storage name is the only thing keeping them apart.
    [self show:kCampaignId times:1];

    CTImpressionManager *inAppImpressions =
        [[CTImpressionManager alloc] initWithAccountId:self.helper.accountId
                                              deviceId:self.helper.deviceId
                                       delegateManager:self.helper.delegateManager];
    CTInAppTriggerManager *inAppTriggers =
        [[CTInAppTriggerManager alloc] initWithAccountId:self.helper.accountId
                                                deviceId:self.helper.deviceId
                                         delegateManager:self.helper.delegateManager];

    XCTAssertEqual(0, [[inAppImpressions getImpressions:kCampaignId] count]);
    XCTAssertEqual(0, [inAppTriggers getTriggers:kCampaignId]);
}

@end
