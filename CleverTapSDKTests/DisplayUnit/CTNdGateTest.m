//
//  CTNdGateTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CleverTapSDK/CleverTap.h>
#import "CleverTap+DisplayUnit.h"
#import "CleverTapInternal.h"
#import "CTConstants.h"
#import "CTImpressionManager.h"
#import "CTNdEvaluationManager.h"
#import "CTNdFCManager.h"
#import "CTNdStore.h"
#import "NdHelper.h"
#import "CTNdFCManager+Tests.h"

/**
 The Native Display gate and the helpers it uses. None of them has a header declaration.
 @c CleverTapInstanceTests declares the private selectors it calls the same way.

 The class extension in @c CleverTap.m declares all five properties readwrite. The setters already
 exist. This only makes them visible to the test.
 */
@interface CleverTap (NdGateTests)

@property (nonatomic, strong) CTNdStore *ndStore;
@property (nonatomic, strong) CTNdFCManager *ndFCManager;
@property (nonatomic, strong) CTNdEvaluationManager *ndEvaluationManager;
@property (atomic, assign) BOOL sentCappedNativeDisplaysToApp;
@property (atomic, assign) BOOL appReportedANativeDisplayView;

- (NSArray<CleverTapDisplayUnit *> *)nativeDisplayUnitsStillAllowedToShow:(NSArray<CleverTapDisplayUnit *> *)displayUnits;
- (BOOL)nativeDisplayExcludesGlobalCapsFor:(NSString *)campaignId;
- (BOOL)nativeDisplayCampaignNeedsTimestamps:(NSString *)campaignId;
- (void)countNativeDisplayView:(CleverTapDisplayUnit *)displayUnit;
- (int)nativeDisplayIntFrom:(id)value fallback:(int)fallback;
- (void)saveNativeDisplayRulesAndCaps:(NSDictionary *)jsonResp;

@end

/// The campaign id. This is @c ti. Every store uses it as its key.
static NSString *const kCampaignId = @"70001";
/// The same campaign's wzrk_id. It is @c ti plus a suffix that changes on every send.
static NSString *const kWzrkId = @"70001_20260810";
/// A second campaign, for filling up the account caps without touching the first.
static NSString *const kOtherCampaignId = @"70002";

@interface CTNdGateTest : XCTestCase
@property (nonatomic, strong) NdHelper *helper;
@property (nonatomic, strong) CleverTap *cleverTap;
@end

@implementation CTNdGateTest

- (void)setUp {
    [super setUp];
    self.helper = [NdHelper new];

    // A bare CleverTap object. The real initialiser reads the device, opens the event queue, starts
    // a session and talks to the network. The gate needs none of that. It reads three things:
    // ndFCManager, ndStore and config.logLevel. The first two are set below. config stays nil. A
    // nil config gives a log level of 0. The log lines are then skipped. dealloc only removes
    // notification observers. An object built this way is safe to release.
    self.cleverTap = [[CleverTap alloc] init];
    self.cleverTap.ndStore = self.helper.ndStore;
    self.cleverTap.ndFCManager = self.helper.ndFCManager;
    self.cleverTap.ndEvaluationManager = self.helper.evaluationManager;
}

- (void)tearDown {
    self.cleverTap = nil;
    [self.helper tearDown];
    [super tearDown];
}

#pragma mark Helpers

/// A content unit with the shape the server sends. ti is a number here. It has no cap fields.
/// Native Display content carries none.
- (CleverTapDisplayUnit *)unitWithTi:(NSString *)ti {
    return [self unitWithTi:ti extras:@{}];
}

- (CleverTapDisplayUnit *)unitWithTi:(NSString *)ti extras:(NSDictionary *)extras {
    NSMutableDictionary *json = [@{
        CLTAP_INAPP_ID: @([ti intValue]),
        CLTAP_NOTIFICATION_ID_TAG: [ti stringByAppendingString:@"_20260810"],
        @"type": @"simple"
    } mutableCopy];
    [json addEntriesFromDictionary:extras];
    return [[CleverTapDisplayUnit alloc] initWithJSON:json];
}

/// Runs the gate and returns the campaign ids that came through, in the order they came through.
- (NSArray<NSString *> *)gate:(NSArray<CleverTapDisplayUnit *> *)units {
    NSMutableArray<NSString *> *ids = [NSMutableArray new];
    for (CleverTapDisplayUnit *unit in [self.cleverTap nativeDisplayUnitsStillAllowedToShow:units]) {
        [ids addObject:[CTNdFCManager campaignIdFrom:unit.json]];
    }
    return ids;
}

- (void)show:(NSString *)campaignId times:(int)times {
    for (int i = 0; i < times; i++) {
        [self.helper.ndFCManager didShowCampaign:campaignId storeTimestamp:NO];
    }
}

#pragma mark Every unit goes through the gate

- (void)testAUnitCarryingNoCapFieldsIsStillHeldBackByTheAccountCap {
    // The bug the marker check caused. This time it is checked at the gate. Native Display content
    // has no efc, tlc, tdc or mdc on it. A gate that only checks units with one of those four never
    // runs at all. The account caps belong to the account. The unit says nothing about them.
    [self.helper.ndFCManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:kOtherCampaignId times:1];

    XCTAssertEqualObjects(@[], [self gate:@[[self unitWithTi:kCampaignId]]]);
}

- (void)testAnAccountWithNoLimitsLetsEveryUnitThrough {
    // ndmc and ndmp are new keys. A response may not carry them. An account that never receives
    // them must behave exactly as it did before this feature.
    [self show:kCampaignId times:50];
    [self show:kOtherCampaignId times:50];

    NSArray *expected = @[kCampaignId, kOtherCampaignId];
    XCTAssertEqualObjects(expected, ([self gate:@[[self unitWithTi:kCampaignId],
                                                  [self unitWithTi:kOtherCampaignId]]]));
}

- (void)testAUnitWithNoTiIsLetThroughEvenWhenTheAccountCapIsFull {
    // No ti means nothing to store a count under. There is no cap to check. Showing it is the safer
    // mistake. Holding it back would hide a campaign for a reason nobody can see.
    [self.helper.ndFCManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:kOtherCampaignId times:1];

    CleverTapDisplayUnit *noTi = [[CleverTapDisplayUnit alloc] initWithJSON:@{
        CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
        @"type": @"simple"
    }];

    XCTAssertEqual(1, [[self.cleverTap nativeDisplayUnitsStillAllowedToShow:@[noTi]] count]);
}

- (void)testTheGateKeepsTheOrderAndDropsOnlyTheUnitThatHasNoRoom {
    // One campaign is an exception to the account caps. The other is not. Both arrive in the same
    // response. Only one may come through. The rest of the list must not move.
    [self.helper.ndStore storeServerSideNativeDisplays:@[@{
        CLTAP_INAPP_ID: @70002,
        CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS: @1
    }]];
    [self.helper.ndFCManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:@"70003" times:1];

    NSArray *expected = @[kOtherCampaignId];
    XCTAssertEqualObjects(expected, ([self gate:@[[self unitWithTi:kCampaignId],
                                                  [self unitWithTi:kOtherCampaignId]]]));
}

- (void)testAnEmptyResponseGivesAnEmptyResult {
    XCTAssertEqualObjects(@[], [self gate:@[]]);
}

- (void)testThereIsNoGateWithoutAnFCManager {
    // Analytics only instances and app extensions have no Native Display managers. Nothing is
    // capped there. The list must come back untouched.
    self.cleverTap.ndFCManager = nil;

    NSArray *units = @[[self unitWithTi:kCampaignId]];
    XCTAssertEqualObjects(units, [self.cleverTap nativeDisplayUnitsStillAllowedToShow:units]);
}

#pragma mark The cap settings come from the rule, never from the content

- (void)testTheTwoSkipFlagsOnTheContentAreIgnored {
    // efc and excludeGlobalFCaps are read from the campaign's rule in adUnit_notifs_ss. The content
    // the server sends for Native Display carries no cap settings. A unit that somehow arrives with
    // these two set must not be treated as an exception to anything.
    [self.helper.ndFCManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:kOtherCampaignId times:1];

    CleverTapDisplayUnit *unit = [self unitWithTi:kCampaignId extras:@{
        CLTAP_INAPP_EXCLUDE_FROM_CAPS: @1,
        CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS: @1
    }];

    XCTAssertEqualObjects(@[], [self gate:@[unit]]);
}

- (void)testTheThreeCountingCapFieldsOnTheContentAreIgnored {
    // tlc, tdc and mdc belong to in-app. A Native Display campaign puts its own cap in
    // frequencyLimits or occurrenceLimits instead. Those are checked during evaluation. All three
    // are zero here. A gate that read them would hold the unit back.
    CleverTapDisplayUnit *unit = [self unitWithTi:kCampaignId extras:@{
        CLTAP_INAPP_TOTAL_LIFETIME_COUNT: @0,
        CLTAP_INAPP_TOTAL_DAILY_COUNT: @0,
        CLTAP_INAPP_MAX_PER_SESSION: @0
    }];
    [self show:kCampaignId times:1];

    NSArray *expected = @[kCampaignId];
    XCTAssertEqualObjects(expected, [self gate:@[unit]]);
}

- (void)testARuleWithTheExemptionLetsTheUnitThroughAFullAccountCap {
    // The flag on the rule is the one that counts. This case was checked on a device. The account
    // session cap is used up. The campaign still shows.
    [self.helper.ndStore storeServerSideNativeDisplays:@[@{
        CLTAP_INAPP_ID: @70001,
        CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS: @1
    }]];
    [self.helper.ndFCManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:kOtherCampaignId times:1];

    NSArray *expected = @[kCampaignId];
    XCTAssertEqualObjects(expected, [self gate:@[[self unitWithTi:kCampaignId]]]);
}

#pragma mark Reading the exemption flag

- (void)testACampaignWithNoRuleIsNotAnException {
    XCTAssertFalse([self.cleverTap nativeDisplayExcludesGlobalCapsFor:kCampaignId]);
}

- (void)testTheRuleIsFoundByTiAndNotByWzrkId {
    // A wzrk_id is the ti plus a suffix. The suffix changes on every send. A lookup by wzrk_id
    // would find nothing. The campaign would then lose its exemption with nothing logged.
    [self.helper.ndStore storeServerSideNativeDisplays:@[@{
        CLTAP_INAPP_ID: @70001,
        CLTAP_NOTIFICATION_ID_TAG: kWzrkId,
        CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS: @1
    }]];

    XCTAssertTrue([self.cleverTap nativeDisplayExcludesGlobalCapsFor:kCampaignId]);
    XCTAssertFalse([self.cleverTap nativeDisplayExcludesGlobalCapsFor:kWzrkId]);
}

- (void)testAFlagOfZeroOrAMissingFlagIsNotAnException {
    [self.helper.ndStore storeServerSideNativeDisplays:@[
        @{ CLTAP_INAPP_ID: @70001, CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS: @0 },
        @{ CLTAP_INAPP_ID: @70002 }
    ]];

    XCTAssertFalse([self.cleverTap nativeDisplayExcludesGlobalCapsFor:kCampaignId]);
    XCTAssertFalse([self.cleverTap nativeDisplayExcludesGlobalCapsFor:kOtherCampaignId]);
}

#pragma mark Which campaigns get their impression times saved

- (void)testACampaignWithFrequencyLimitsNeedsItsTimesSaved {
    [self.helper.ndStore storeServerSideNativeDisplays:@[@{
        CLTAP_INAPP_ID: @70001,
        CLTAP_INAPP_FC_LIMITS: @[@{ @"type": @"hours", @"limit": @2, @"frequency": @1 }]
    }]];

    XCTAssertTrue([self.cleverTap nativeDisplayCampaignNeedsTimestamps:kCampaignId]);
}

- (void)testACampaignWithOccurrenceLimitsNeedsItsTimesSaved {
    [self.helper.ndStore storeServerSideNativeDisplays:@[@{
        CLTAP_INAPP_ID: @70001,
        CLTAP_INAPP_OCCURRENCE_LIMITS: @[@{ @"type": @"onEvery", @"limit": @2 }]
    }]];

    XCTAssertTrue([self.cleverTap nativeDisplayCampaignNeedsTimestamps:kCampaignId]);
}

- (void)testACampaignWithEmptyLimitListsNeedsNoTimesSaved {
    // Saved times have one reader. That reader matches frequencyLimits and occurrenceLimits. An
    // empty list is never matched against. There is nothing to save for.
    [self.helper.ndStore storeServerSideNativeDisplays:@[@{
        CLTAP_INAPP_ID: @70001,
        CLTAP_INAPP_FC_LIMITS: @[],
        CLTAP_INAPP_OCCURRENCE_LIMITS: @[]
    }]];

    XCTAssertFalse([self.cleverTap nativeDisplayCampaignNeedsTimestamps:kCampaignId]);
}

- (void)testACampaignWithNoRuleNeedsNoTimesSaved {
    XCTAssertFalse([self.cleverTap nativeDisplayCampaignNeedsTimestamps:kCampaignId]);
}

#pragma mark Counting a view the app reported

- (void)testAReportedViewIsCounted {
    [self.cleverTap countNativeDisplayView:[self unitWithTi:kCampaignId]];

    XCTAssertEqual(1, [self.helper.ndFCManager todayCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.helper.ndFCManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.helper.ndFCManager shownTodayCount]);
    XCTAssertTrue(self.cleverTap.appReportedANativeDisplayView);
}

- (void)testAUnitWithNoTiIsNotCounted {
    CleverTapDisplayUnit *noTi = [[CleverTapDisplayUnit alloc] initWithJSON:@{
        CLTAP_NOTIFICATION_ID_TAG: kWzrkId
    }];

    [self.cleverTap countNativeDisplayView:noTi];

    XCTAssertEqual(0, [self.helper.ndFCManager shownTodayCount]);
    XCTAssertFalse(self.cleverTap.appReportedANativeDisplayView);
}

- (void)testAViewIsCountedUnderTiAndNotUnderWzrkId {
    // Two sends of one campaign have the same ti. Their wzrk_ids are different. A count under the
    // wzrk_id would go back to zero every time the campaign runs again.
    [self.cleverTap countNativeDisplayView:[self unitWithTi:kCampaignId]];

    XCTAssertEqual(1, [self.helper.ndFCManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(0, [self.helper.ndFCManager lifetimeCountForCampaign:kWzrkId]);
}

- (void)testOnlyACampaignWithLimitsGetsItsViewTimeSaved {
    [self.helper.ndStore storeServerSideNativeDisplays:@[@{
        CLTAP_INAPP_ID: @70001,
        CLTAP_INAPP_FC_LIMITS: @[@{ @"type": @"hours", @"limit": @2, @"frequency": @1 }]
    }]];

    [self.cleverTap countNativeDisplayView:[self unitWithTi:kCampaignId]];
    [self.cleverTap countNativeDisplayView:[self unitWithTi:kOtherCampaignId]];

    CTImpressionManager *impressions = self.helper.impressionManager;
    XCTAssertEqual(1, [[impressions getImpressions:kCampaignId] count]);
    XCTAssertEqual(0, [[impressions getImpressions:kOtherCampaignId] count]);

    // The second campaign was still counted. Only its time was not saved.
    XCTAssertEqual(1, [self.helper.ndFCManager lifetimeCountForCampaign:kOtherCampaignId]);
}

#pragma mark The change of day

- (void)testTheGateChecksTheDateBeforeItAppliesTheDailyCap {
    // A batch that arrives just after midnight. The counts on disk were made yesterday. A unit must
    // not be measured against them. checkUpdateDailyLimits runs before the loop for this reason.
    [self.helper.ndFCManager resetDailyCounters:@"20250101"];
    [self show:kCampaignId times:2];
    [self.helper.ndFCManager updateGlobalLimitsPerDay:1 andPerSession:-1];

    // The state the gate starts from. Two units were counted under yesterday's date. The cap is
    // one. Without the date check the unit below has no room left.
    XCTAssertEqual(2, [self.helper.ndFCManager shownTodayCount]);

    NSArray *expected = @[kCampaignId];
    XCTAssertEqualObjects(expected, [self gate:@[[self unitWithTi:kCampaignId]]]);
    XCTAssertEqual(0, [self.helper.ndFCManager shownTodayCount]);
}

#pragma mark The warning about missing view reports

- (void)testAHeldBackUnitDoesNotArmTheWarning {
    // The warning is about units the app was really given. The app cannot report a view of a unit
    // it never received. A held back unit must not be counted here.
    [self.helper.ndFCManager updateGlobalLimitsPerDay:-1 andPerSession:1];
    [self show:kOtherCampaignId times:1];

    [self gate:@[[self unitWithTi:kCampaignId]]];

    XCTAssertFalse(self.cleverTap.sentCappedNativeDisplaysToApp);
}

- (void)testADeliveredUnitArmsTheWarningWhenTheAccountHasCaps {
    [self.helper.ndFCManager updateGlobalLimitsPerDay:5 andPerSession:-1];

    [self gate:@[[self unitWithTi:kCampaignId]]];

    XCTAssertTrue(self.cleverTap.sentCappedNativeDisplaysToApp);
}

- (void)testAnAccountWithNoCapsNeverArmsTheWarning {
    // Nothing is capped here. A missing view report changes nothing. There is nothing to warn about.
    [self gate:@[[self unitWithTi:kCampaignId]]];

    XCTAssertFalse(self.cleverTap.sentCappedNativeDisplaysToApp);
}

#pragma mark Reading the two account caps off a response

- (void)testTheCapsAreReadFromNumbersAndFromStrings {
    XCTAssertEqual(5, [self.cleverTap nativeDisplayIntFrom:@5 fallback:-1]);
    XCTAssertEqual(5, [self.cleverTap nativeDisplayIntFrom:@"5" fallback:-1]);
}

- (void)testAValueThatIsNotANumberUsesTheFallback {
    // Without the fallback these would all be read as zero. Zero is a real cap. It would stop
    // every Native Display unit on the account.
    XCTAssertEqual(-1, [self.cleverTap nativeDisplayIntFrom:@"not a number" fallback:-1]);
    XCTAssertEqual(-1, [self.cleverTap nativeDisplayIntFrom:nil fallback:-1]);
    XCTAssertEqual(-1, [self.cleverTap nativeDisplayIntFrom:@{} fallback:-1]);
    XCTAssertEqual(-1, [self.cleverTap nativeDisplayIntFrom:@[] fallback:-1]);
}

- (void)testAResponseWithoutNdmcLeavesTheAccountCapsAlone {
    // ndmc is on every response that knows about caps. Seeing it is how we know the response has
    // caps at all. A response without it says nothing about them.
    [self.helper.ndFCManager updateGlobalLimitsPerDay:6 andPerSession:5];

    [self.cleverTap saveNativeDisplayRulesAndCaps:@{}];

    XCTAssertEqual(5, [self.helper.ndFCManager globalSessionMax]);
    XCTAssertEqual(6, [self.helper.ndFCManager maxPerDayCount]);
}

- (void)testAResponseWithNdmcAndNoNdmpClearsTheDailyCap {
    // The response does know about caps. A missing ndmp then means there is no daily limit, not
    // that the old one still stands.
    [self.helper.ndFCManager updateGlobalLimitsPerDay:6 andPerSession:5];

    [self.cleverTap saveNativeDisplayRulesAndCaps:@{ CLTAP_ND_SESSION_MAX_META_KEY: @2 }];

    XCTAssertEqual(2, [self.helper.ndFCManager globalSessionMax]);
    XCTAssertEqual(-1, [self.helper.ndFCManager maxPerDayCount]);
}

- (void)testTheCapsAreSavedWhenTheServerSendsThemAsStrings {
    [self.cleverTap saveNativeDisplayRulesAndCaps:@{
        CLTAP_ND_SESSION_MAX_META_KEY: @"3",
        CLTAP_ND_DAILY_MAX_META_KEY: @"7"
    }];

    XCTAssertEqual(3, [self.helper.ndFCManager globalSessionMax]);
    XCTAssertEqual(7, [self.helper.ndFCManager maxPerDayCount]);
}

- (void)testTheRulesAreStoredAndAnEmptyListClearsThem {
    NSArray *rules = @[@{ CLTAP_INAPP_ID: @70001 }];

    [self.cleverTap saveNativeDisplayRulesAndCaps:@{ CLTAP_ND_SS_JSON_RESPONSE_KEY: rules }];
    XCTAssertEqual(1, [[self.helper.ndStore serverSideNativeDisplays] count]);

    // The server sends this list only when it is sending the full current set. An empty array
    // really does mean there are no rules left.
    [self.cleverTap saveNativeDisplayRulesAndCaps:@{ CLTAP_ND_SS_JSON_RESPONSE_KEY: @[] }];
    XCTAssertEqual(0, [[self.helper.ndStore serverSideNativeDisplays] count]);
}

- (void)testStaleCampaignsHaveTheirCountsRemoved {
    [self show:kCampaignId times:2];
    [self show:kOtherCampaignId times:1];

    // The server sends these ids as numbers.
    [self.cleverTap saveNativeDisplayRulesAndCaps:@{ CLTAP_ND_STALE_JSON_RESPONSE_KEY: @[@70001] }];

    XCTAssertEqual(0, [self.helper.ndFCManager lifetimeCountForCampaign:kCampaignId]);
    XCTAssertEqual(1, [self.helper.ndFCManager lifetimeCountForCampaign:kOtherCampaignId]);
}

@end
