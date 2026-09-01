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

/// The campaign id, the thing every store must key by.
static NSString *const kTargetId = @"70001";
/// The same campaign's wzrk_id. Nothing should ever be stored under this.
static NSString *const kWzrkId = @"70001_20260810";
/// A second campaign, for filling up the account-wide caps without touching the first.
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

    // Both account-wide caps default to 1, which would block almost everything. The per-target tests
    // are not about those, so switch them off and let the tests that do care set them.
    [self.fcManager updateGlobalLimitsPerDay:-1 andPerSession:-1];
}

- (void)tearDown {
    [self.helper tearDown];
    [super tearDown];
}

#pragma mark Helpers

/// canShowTarget with nothing capped, so a test only has to pass the one value it is about.
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
        // Built outside the assert, because a literal's commas would be read as macro arguments.
        NSDictionary *unit = @{ CLTAP_INAPP_ID: kTargetId, marker: @1 };
        XCTAssertTrue([CTNdFCManager isFcapManaged:unit],
                      @"%@ on its own should make a unit cap managed", marker);
    }
}

- (void)testIsFcapManagedIsFalseForAUnitWithNoMarkers {
    // Display units that exist today have none of these, and must keep working untouched. They also
    // must not add to the account's daily and session totals.
    NSDictionary *unit = @{ CLTAP_INAPP_ID: kTargetId, @"type": @"banner", @"msg": @{} };
    XCTAssertFalse([CTNdFCManager isFcapManaged:unit]);
}

- (void)testIsFcapManagedIsFalseForANonDictionary {
    XCTAssertFalse([CTNdFCManager isFcapManaged:nil]);
    XCTAssertFalse([CTNdFCManager isFcapManaged:(NSDictionary *)@"not a dictionary"]);
}

#pragma mark efc and excludeGlobalFCaps are not the same flag

- (void)testExcludeFromCapsSkipsEveryCap {
    // Every cap set to its most restrictive, and both account-wide ones already used up.
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
    // efc and excludeGlobalFCaps are different widths. In-app folds them into one flag; this must
    // not. Same starting state for both halves of this test, only the flag changes.
    [self.fcManager updateGlobalLimitsPerDay:1 andPerSession:-1];
    [self show:kOtherTargetId times:1];

    // The account daily max is used up, so without the flag the target cannot show.
    XCTAssertFalse([self canShow:kTargetId]);

    // With the flag it can, because that cap is account-wide.
    XCTAssertTrue([self.fcManager canShowTarget:kTargetId
                                excludeFromCaps:NO
                              excludeGlobalCaps:YES
                             totalLifetimeCount:-1
                                totalDailyCount:-1
                                  maxPerSession:-1]);

    // But its own lifetime cap still applies. This is the assertion both existing implementations
    // would fail, because they treat the flag as if it were efc.
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

    // Used up by a different target, which is the point of an account-wide cap.
    XCTAssertFalse([self canShow:kTargetId]);
}

#pragma mark Fail open

- (void)testATargetWithNoIdIsAllowedThrough {
    // Nothing to key a count by, so there is no cap to check. Holding it back would hide a campaign
    // for a reason nobody could see.
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
    // A product decision, not an oversight. One call from the app is one impression, and the SDK
    // does not de-duplicate, because it has no way to tell a genuine second view from a repeat call.
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

#pragma mark Which displays get a saved timestamp

- (void)testATargetWithNoLimitsGetsNoSavedTimestamp {
    // Only frequencyLimits and occurrenceLimits ever read the saved timestamps. Writing one for a
    // target that has neither would grow a list nothing reads, and app-driven impressions have no
    // upper bound.
    [self.fcManager didShowTarget:kTargetId storeTimestamp:NO];

    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);

    // The counts that do not depend on timestamps still had to happen.
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
    // The session counts live in memory, so turning timestamps off must not weaken mdc.
    [self.fcManager didShowTarget:kTargetId storeTimestamp:NO];
    XCTAssertFalse([self.fcManager canShowTarget:kTargetId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:-1 totalDailyCount:-1 maxPerSession:1]);
}

#pragma mark The daily rollover

- (void)testTheDailyResetZeroesTodayAndKeepsLifetime {
    [self show:kTargetId times:3];

    [self.fcManager resetDailyCounters:@"20990101"];

    XCTAssertEqual(0, [self.fcManager todayCountForTarget:kTargetId]);
    XCTAssertEqual(3, [self.fcManager lifetimeCountForTarget:kTargetId]);
    XCTAssertEqual(0, [self.fcManager shownTodayCount]);
}

- (void)testALifetimeCapSurvivesTheDailyReset {
    // The whole point of keeping lifetime counts across the rollover.
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

#pragma mark Stale targets

- (void)testRemoveStaleTargetCountsClearsCountsImpressionsAndTriggers {
    [self show:kTargetId times:2];
    [self.fcManager.triggerManager incrementTrigger:kTargetId];

    // The server sends these ids as numbers, so pass one to lock in the conversion.
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

    // ndtlc is [[targetId, todayCount, lifetimeCount], ...].
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

#pragma mark Keying

- (void)testTargetIdComesFromTiAndNeverFromWzrkId {
    // The single assertion that would have caught the Android bug. Its gate reads the unit id, which
    // is the wzrk_id, so it counts under a key that changes on every send of the campaign.
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
    // Empty rather than falling back to wzrk_id. An empty id makes the gate fail open, which is the
    // safer of the two mistakes; a wzrk_id fallback would silently miscount instead.
    NSDictionary *noTi = @{ CLTAP_NOTIFICATION_ID_TAG: kWzrkId };
    XCTAssertEqualObjects(@"", [CTNdFCManager targetIdFrom:noTi]);
    XCTAssertEqualObjects(@"", [CTNdFCManager targetIdFrom:nil]);
    XCTAssertEqualObjects(@"", [CTNdFCManager targetIdFrom:(NSDictionary *)@"not a dictionary"]);
}

- (void)testAUnitWithNoTiIsNotCapped {
    // The two halves of failing open, joined up: no ti means an empty key, and an empty key shows.
    NSDictionary *unit = @{ CLTAP_NOTIFICATION_ID_TAG: kWzrkId, CLTAP_INAPP_TOTAL_LIFETIME_COUNT: @0 };
    NSString *targetId = [CTNdFCManager targetIdFrom:unit];

    XCTAssertTrue([self.fcManager canShowTarget:targetId excludeFromCaps:NO excludeGlobalCaps:NO
                             totalLifetimeCount:0 totalDailyCount:0 maxPerSession:0]);
}

- (void)testEvaluateThenGateThenCountAllUseTheSameTargetId {
    // The test the Android suite does not have. Its NdFcapGateTest mocks the unit id and never
    // checks that the three stores agree on a key, which is how the gate ended up reading counters
    // under wzrk_id while the evaluator wrote triggers under ti.
    //
    // wzrk_id is the campaign id plus a per-send suffix, so it differs on every run of a repeating
    // campaign. Any count kept under it starts again from zero on the next run.
    NSDictionary *rule = @{
        CLTAP_INAPP_ID: @70001,
        CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
        CLTAP_INAPP_TRIGGERS: @[@{ @"eventName": @"Product Viewed" }]
    };
    [self.helper.ndStore storeServerSideNativeDisplays:@[rule]];

    // Taken off the unit the way the gate takes it, so the chain is tested end to end rather than
    // from a constant the test picked itself.
    NSString *targetId = [CTNdFCManager targetIdFrom:rule];
    XCTAssertEqualObjects(kTargetId, targetId);

    // 1. Evaluate. Writes a trigger and adds the id to adUnit_eval.
    [self.helper.evaluationManager evaluateOnEvent:@"Product Viewed" withProps:nil];

    XCTAssertEqual(1, [self.helper.triggerManager getTriggers:kTargetId]);
    NSDictionary *evalHeader = [self.helper.evaluationManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];
    XCTAssertEqualObjects(@[@70001], evalHeader[CLTAP_ND_SS_EVAL_META_KEY]);

    // 2. Gate. Reads the counters the next step will write.
    XCTAssertTrue([self canShow:targetId]);

    // 3. Count.
    [self.fcManager didShowTarget:targetId storeTimestamp:YES];

    // All three stores hold the campaign id.
    XCTAssertEqual(1, [self.helper.triggerManager getTriggers:kTargetId]);
    XCTAssertEqual(1, [[self.fcManager.impressionManager getImpressions:kTargetId] count]);
    XCTAssertEqual(1, [self.fcManager lifetimeCountForTarget:kTargetId]);

    // And none of them holds the wzrk_id. This is the assertion that fails on the Android gate.
    XCTAssertEqual(0, [self.helper.triggerManager getTriggers:kWzrkId]);
    XCTAssertEqual(0, [[self.fcManager.impressionManager getImpressions:kWzrkId] count]);
    XCTAssertEqual(0, [self.fcManager lifetimeCountForTarget:kWzrkId]);
    XCTAssertNil(self.fcManager.targetCounts[kWzrkId]);
}

- (void)testACapCountedUnderTheCampaignIdIsReachedAcrossSends {
    // The consequence of the test above, stated as behaviour. Two sends of the same campaign share
    // a ti and differ in wzrk_id, and a lifetime cap of 1 has to stop the second one.
    [self.fcManager didShowTarget:kTargetId storeTimestamp:NO];

    XCTAssertFalse([self.fcManager canShowTarget:kTargetId excludeFromCaps:NO excludeGlobalCaps:NO
                              totalLifetimeCount:1 totalDailyCount:-1 maxPerSession:-1]);
}

#pragma mark Channel separation

- (void)testNativeDisplayCountsDoNotTouchTheInAppStores {
    // The two channels share these two classes and are kept apart only by their storage namespace.
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
