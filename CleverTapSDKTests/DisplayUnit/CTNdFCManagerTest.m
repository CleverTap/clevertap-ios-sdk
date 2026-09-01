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
static NSString *const kTargetId = @"70001";
/// The same campaign's wzrk_id. Nothing should ever be stored under this.
static NSString *const kWzrkId = @"70001_20260810";
/// A second campaign, for filling up the account caps without touching the first.
static NSString *const kOtherTargetId = @"70002";

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

/// canShowTarget with no caps set, so a test only has to pass the one value it cares about.
- (BOOL)canShow:(NSString *)targetId {
    return [self.fcManager canShowTarget:targetId
                         excludeFromCaps:NO
                       excludeGlobalCaps:NO
                      totalLifetimeCount:-1
                         totalDailyCount:-1
                           maxPerSession:-1];
}

- (void)show:(NSString *)targetId times:(int)times {
    for (int i = 0; i < times; i++) {
        [self.fcManager didShowTarget:targetId storeTimestamp:YES];
    }
}

#pragma mark isFcapManaged

- (void)testIsFcapManagedRecognisesEachMarkerOnItsOwn {
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
        NSDictionary *unit = @{ CLTAP_INAPP_ID: kTargetId, marker: @1 };
        XCTAssertTrue([CTNdFCManager isFcapManaged:unit],
                      @"%@ on its own should be enough to make a unit capped", marker);
    }
}

- (void)testIsFcapManagedIsFalseForAUnitWithNoMarkers {
    // Display units that already exist have none of these and must keep working untouched. They
    // must also not add to the account's daily and session totals.
    NSDictionary *unit = @{ CLTAP_INAPP_ID: kTargetId, @"type": @"banner", @"msg": @{} };
    XCTAssertFalse([CTNdFCManager isFcapManaged:unit]);
}

- (void)testIsFcapManagedIsFalseForANonDictionary {
    XCTAssertFalse([CTNdFCManager isFcapManaged:nil]);
    XCTAssertFalse([CTNdFCManager isFcapManaged:(NSDictionary *)@"not a dictionary"]);
}

#pragma mark efc and excludeGlobalFCaps are not the same flag

- (void)testExcludeFromCapsSkipsEveryCap {
    // Every cap set as tight as it goes, and both account caps already used up.
    [self.fcManager updateGlobalLimitsPerDay:1 andPerSession:1];
    [self show:kOtherTargetId times:1];
    [self show:kTargetId times:1];

    XCTAssertTrue([self.fcManager canShowTarget:kTargetId
                                excludeFromCaps:YES
                              excludeGlobalCaps:NO
                             totalLifetimeCount:1
                                totalDailyCount:1
                                  maxPerSession:1]);
}

- (void)testExcludeGlobalCapsSkipsTheAccountDailyMaxButNotTheTargetsOwnCaps {
    // The two flags skip different amounts. In-app treats them as one flag. This must not. Both
    // halves of the test start the same way, and only the flag changes.
    [self.fcManager updateGlobalLimitsPerDay:1 andPerSession:-1];
    [self show:kOtherTargetId times:1];

    // The account daily cap is used up, so without the flag the campaign cannot show.
    XCTAssertFalse([self canShow:kTargetId]);

    // With the flag it can, because that cap belongs to the account.
    XCTAssertTrue([self.fcManager canShowTarget:kTargetId
                                excludeFromCaps:NO
                              excludeGlobalCaps:YES
                             totalLifetimeCount:-1
                                totalDailyCount:-1
                                  maxPerSession:-1]);

    // But its own lifetime cap still applies. This is the check both existing versions fail,
    // because they treat this flag as if it were efc.
    [self show:kTargetId times:1];
    XCTAssertFalse([self.fcManager canShowTarget:kTargetId
                                 excludeFromCaps:NO
                               excludeGlobalCaps:YES
                              totalLifetimeCount:1
                                 totalDailyCount:-1
                                   maxPerSession:-1]);
}

- (void)testExcludeGlobalCapsStillRespectsTotalDailyCount {
    [self.fcManager updateGlobalLimitsPerDay:-1 andPerSession:-1];
    [self show:kTargetId times:2];

    XCTAssertFalse([self.fcManager canShowTarget:kTargetId
                                 excludeFromCaps:NO
                               excludeGlobalCaps:YES
                              totalLifetimeCount:-1
                                 totalDailyCount:2
                                   maxPerSession:-1]);
}

- (void)testExcludeGlobalCapsStillRespectsMaxPerSession {
    [self show:kTargetId times:1];

    XCTAssertFalse([self.fcManager canShowTarget:kTargetId
                                 excludeFromCaps:NO
                               excludeGlobalCaps:YES
                              totalLifetimeCount:-1
                                 totalDailyCount:-1
                                   maxPerSession:1]);
}

- (void)testExcludeGlobalCapsSkipsTheAccountSessionMax {
    [self.fcManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:kOtherTargetId times:1];

    XCTAssertFalse([self canShow:kTargetId]);
    XCTAssertTrue([self.fcManager canShowTarget:kTargetId
                                excludeFromCaps:NO
                              excludeGlobalCaps:YES
                             totalLifetimeCount:-1
                                totalDailyCount:-1
                                  maxPerSession:-1]);
}

#pragma mark The counting caps

- (void)testTotalLifetimeCountBlocksOnceReached {
    XCTAssertTrue([self.fcManager canShowTarget:kTargetId excludeFromCaps:NO excludeGlobalCaps:NO
                             totalLifetimeCount:2 totalDailyCount:-1 maxPerSession:-1]);
    [self show:kTargetId times:2];
    XCTAssertFalse([self.fcManager canShowTarget:kTargetId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:2 totalDailyCount:-1 maxPerSession:-1]);
}

- (void)testMinusOneMeansNoLimit {
    [self show:kTargetId times:20];
    XCTAssertTrue([self canShow:kTargetId]);
}

- (void)testTheAccountDailyMaxBlocksEveryTarget {
    [self.fcManager updateGlobalLimitsPerDay:2 andPerSession:-1];
    [self show:kOtherTargetId times:2];

    // Used up by a different campaign, which is the whole point of an account cap.
    XCTAssertFalse([self canShow:kTargetId]);
}

#pragma mark What happens when we cannot check

- (void)testATargetWithNoIdIsAllowedThrough {
    // No id means nothing to store a count under, so there is no cap to check. Holding it back
    // would hide a campaign for a reason nobody could see.
    XCTAssertTrue([self canShow:@""]);
}

#pragma mark Counting a display

- (void)testDidShowCountsTodayLifetimeAndTheDayTotal {
    [self.fcManager didShowTarget:kTargetId storeTimestamp:YES];

    XCTAssertEqual(1, [self.fcManager todayCountForTarget:kTargetId]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForTarget:kTargetId]);
    XCTAssertEqual(1, [self.fcManager shownTodayCount]);
    XCTAssertEqual(1, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);
}

- (void)testTwoViewedCallsForTheSameUnitCountTwice {
    // This is on purpose, not a bug. One call from the app is one impression. The SDK does not
    // remove repeats, because it cannot tell a real second view from the same view reported twice.
    [self.fcManager didShowTarget:kTargetId storeTimestamp:YES];
    [self.fcManager didShowTarget:kTargetId storeTimestamp:YES];

    XCTAssertEqual(2, [self.fcManager todayCountForTarget:kTargetId]);
    XCTAssertEqual(2, [self.fcManager lifetimeCountForTarget:kTargetId]);
    XCTAssertEqual(2, [self.fcManager shownTodayCount]);
    XCTAssertEqual(2, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);
}

- (void)testDidShowIgnoresAnEmptyTargetId {
    [self.fcManager didShowTarget:@"" storeTimestamp:YES];
    XCTAssertEqual(0, [self.fcManager shownTodayCount]);
}

#pragma mark Which displays get their time saved

- (void)testATargetWithNoLimitsGetsNoSavedTimestamp {
    // Only frequencyLimits and occurrenceLimits ever read saved times. Saving one for a campaign
    // with neither would grow a list nobody reads, and the app can report as many views as it likes.
    [self.fcManager didShowTarget:kTargetId storeTimestamp:NO];

    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);

    // The counts that do not need saved times still had to happen.
    XCTAssertEqual(1, [self.fcManager todayCountForTarget:kTargetId]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForTarget:kTargetId]);
    XCTAssertEqual(1, [self.fcManager shownTodayCount]);
    XCTAssertEqual(1, [self.fcManager.impressionManager perSession:kTargetId]);
    XCTAssertEqual(1, [self.fcManager.impressionManager perSessionTotal]);
}

- (void)testATargetWithLimitsGetsASavedTimestamp {
    [self.fcManager didShowTarget:kTargetId storeTimestamp:YES];
    XCTAssertEqual(1, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);
}

- (void)testSessionCapsStillWorkWithoutSavedTimestamps {
    // The session counts live in memory, so turning off saved times must not weaken mdc.
    [self.fcManager didShowTarget:kTargetId storeTimestamp:NO];
    XCTAssertFalse([self.fcManager canShowTarget:kTargetId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:-1 totalDailyCount:-1 maxPerSession:1]);
}

#pragma mark The change of day

- (void)testTheDailyResetZeroesTodayAndKeepsLifetime {
    [self show:kTargetId times:3];

    [self.fcManager resetDailyCounters:@"20990101"];

    XCTAssertEqual(0, [self.fcManager todayCountForTarget:kTargetId]);
    XCTAssertEqual(3, [self.fcManager lifetimeCountForTarget:kTargetId]);
    XCTAssertEqual(0, [self.fcManager shownTodayCount]);
}

- (void)testALifetimeCapSurvivesTheDailyReset {
    // The whole reason lifetime counts are kept when the day changes.
    [self show:kTargetId times:1];
    [self.fcManager resetDailyCounters:@"20990101"];

    XCTAssertFalse([self.fcManager canShowTarget:kTargetId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:1 totalDailyCount:-1 maxPerSession:-1]);
}

- (void)testCheckUpdateDailyLimitsDoesNothingTwiceInADay {
    [self show:kTargetId times:2];
    [self.fcManager checkUpdateDailyLimits];

    XCTAssertEqual(2, [self.fcManager todayCountForTarget:kTargetId]);
    XCTAssertEqual(2, [self.fcManager shownTodayCount]);
}

#pragma mark Campaigns the server has finished with

- (void)testRemoveStaleTargetCountsClearsCountsImpressionsAndTriggers {
    [self show:kTargetId times:2];
    [self.fcManager.triggerManager incrementTrigger:kTargetId];

    // The server sends these ids as numbers, so pass one here to check we convert it.
    [self.fcManager removeStaleTargetCounts:@[@70001]];

    XCTAssertEqual(0, [self.fcManager todayCountForTarget:kTargetId]);
    XCTAssertEqual(0, [self.fcManager lifetimeCountForTarget:kTargetId]);
    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);
    XCTAssertEqual(0, [self.fcManager.triggerManager getTriggers:kTargetId]);
}

- (void)testRemoveStaleTargetCountsLeavesOtherTargetsAlone {
    [self show:kTargetId times:1];
    [self show:kOtherTargetId times:1];

    [self.fcManager removeStaleTargetCounts:@[kTargetId]];

    XCTAssertEqual(0, [self.fcManager lifetimeCountForTarget:kTargetId]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForTarget:kOtherTargetId]);
}

#pragma mark The batch header

- (void)testTheBatchHeaderCarriesTheDayTotalAndThePerTargetCounts {
    [self show:kTargetId times:2];
    [self.fcManager resetDailyCounters:@"20990101"];
    [self show:kTargetId times:1];

    NSDictionary *header = [self.fcManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];

    // ndmp is how many Native Display units were shown today.
    XCTAssertEqualObjects(@1, header[CLTAP_ND_SHOWN_TODAY_META_KEY]);

    // ndtlc is [[campaign id, today's count, lifetime count], ...].
    NSArray *counts = header[CLTAP_ND_COUNTS_META_KEY];
    XCTAssertEqual(1, counts.count);
    NSArray *expected = @[kTargetId, @1, @3];
    XCTAssertEqualObjects(expected, counts[0]);
}

- (void)testTheBatchHeaderIsStillWellFormedWithNothingShown {
    NSDictionary *header = [self.fcManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];

    XCTAssertEqualObjects(@0, header[CLTAP_ND_SHOWN_TODAY_META_KEY]);
    XCTAssertEqualObjects(@[], header[CLTAP_ND_COUNTS_META_KEY]);
}

#pragma mark Which id the counts are stored under

- (void)testTargetIdComesFromTiAndNeverFromWzrkId {
    // The one check that would have caught the Android bug. Android reads the unit id, which is the
    // wzrk_id, so it saves counts under a key that changes on every send of the campaign.
    NSDictionary *unit = @{ CLTAP_INAPP_ID: @70001, CLTAP_NOTIFICATION_ID_TAG: kWzrkId };
    XCTAssertEqualObjects(kTargetId, [CTNdFCManager targetIdFrom:unit]);
}

- (void)testTargetIdAcceptsTiAsANumberOrAString {
    // The content payload sends ti as a number, other payloads send it as a string.
    NSDictionary *asNumber = @{ CLTAP_INAPP_ID: @70001 };
    NSDictionary *asString = @{ CLTAP_INAPP_ID: @"70001" };
    XCTAssertEqualObjects(kTargetId, [CTNdFCManager targetIdFrom:asNumber]);
    XCTAssertEqualObjects(kTargetId, [CTNdFCManager targetIdFrom:asString]);
}

- (void)testTargetIdIsEmptyWhenThereIsNoTi {
    // Empty, and not the wzrk_id instead. An empty id makes the check let the unit through, which is
    // the safer mistake. Using the wzrk_id would count under the wrong key without telling anyone.
    NSDictionary *noTi = @{ CLTAP_NOTIFICATION_ID_TAG: kWzrkId };
    XCTAssertEqualObjects(@"", [CTNdFCManager targetIdFrom:noTi]);
    XCTAssertEqualObjects(@"", [CTNdFCManager targetIdFrom:nil]);
    XCTAssertEqualObjects(@"", [CTNdFCManager targetIdFrom:(NSDictionary *)@"not a dictionary"]);
}

- (void)testAUnitWithNoTiIsNotCapped {
    // The two rules above, put together. No ti gives an empty id, and an empty id lets the unit show.
    NSDictionary *unit = @{ CLTAP_NOTIFICATION_ID_TAG: kWzrkId, CLTAP_INAPP_TOTAL_LIFETIME_COUNT: @0 };
    NSString *targetId = [CTNdFCManager targetIdFrom:unit];

    XCTAssertTrue([self.fcManager canShowTarget:targetId excludeFromCaps:NO excludeGlobalCaps:NO
                             totalLifetimeCount:0 totalDailyCount:0 maxPerSession:0]);
}

- (void)testEvaluateThenGateThenCountAllUseTheSameTargetId {
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
    NSString *targetId = [CTNdFCManager targetIdFrom:rule];
    XCTAssertEqualObjects(kTargetId, targetId);

    // 1. Evaluate. Saves a trigger and adds the id to adUnit_eval.
    [self.helper.evaluationManager evaluateOnEvent:@"Product Viewed" withProps:nil];

    XCTAssertEqual(1, [self.helper.triggerManager getTriggers:kTargetId]);
    NSDictionary *evalHeader = [self.helper.evaluationManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];
    XCTAssertEqualObjects(@[@70001], evalHeader[CLTAP_ND_SS_EVAL_META_KEY]);

    // 2. Check the caps. This reads the counts that the next step writes.
    XCTAssertTrue([self canShow:targetId]);

    // 3. Count.
    [self.fcManager didShowTarget:targetId storeTimestamp:YES];

    // All three stores saved under the campaign id.
    XCTAssertEqual(1, [self.helper.triggerManager getTriggers:kTargetId]);
    XCTAssertEqual(1, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForTarget:kTargetId]);

    // And none of them saved under the wzrk_id. This is the check that fails on Android.
    XCTAssertEqual(0, [self.helper.triggerManager getTriggers:kWzrkId]);
    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kWzrkId] count]);
    XCTAssertEqual(0, [self.fcManager lifetimeCountForTarget:kWzrkId]);
    XCTAssertNil(self.fcManager.targetCounts[kWzrkId]);
}

- (void)testACapCountedUnderTheCampaignIdIsReachedAcrossSends {
    // What the test above means in practice. Two sends of one campaign have the same ti but
    // different wzrk_ids, so a lifetime cap of 1 has to stop the second send.
    [self.fcManager didShowTarget:kTargetId storeTimestamp:NO];

    XCTAssertFalse([self.fcManager canShowTarget:kTargetId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:1 totalDailyCount:-1 maxPerSession:-1]);
}

#pragma mark Keeping Native Display and in-app apart

- (void)testNativeDisplayCountsDoNotTouchTheInAppStores {
    // Both channels use these two classes. The storage name is the only thing keeping them apart.
    [self show:kTargetId times:1];

    CTImpressionManager *inAppImpressions =
        [[CTImpressionManager alloc] initWithAccountId:self.helper.accountId
                                              deviceId:self.helper.deviceId
                                       delegateManager:self.helper.delegateManager];
    CTInAppTriggerManager *inAppTriggers =
        [[CTInAppTriggerManager alloc] initWithAccountId:self.helper.accountId
                                                deviceId:self.helper.deviceId
                                         delegateManager:self.helper.delegateManager];

    XCTAssertEqual(0, [[inAppImpressions getImpressions:kTargetId] count]);
    XCTAssertEqual(0, [inAppTriggers getTriggers:kTargetId]);
}

@end
