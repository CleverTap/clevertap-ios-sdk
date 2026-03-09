//
//  CleverTapInstanceTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 15/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseTestCase.h"
#import "CTPlistInfo.h"
#import "CTPreferences.h"
#import "CleverTap+Tests.h"
#import <OCMock/OCMock.h>
#import "CTConstants.h"
#import "CTValidationConfig.h"
#import "CleverTapUTMDetail.h"
#import <CleverTapSDK/CleverTapSyncDelegate.h>
#import <CleverTapSDK/CleverTapURLDelegate.h>
#import <CleverTapSDK/CleverTapPushNotificationDelegate.h>
#import "CTDomainFactory.h"
#import "CleverTap+SCDomain.h"

/// Forward-declare private CleverTap methods that have no public header declaration
/// so the test file compiles without "No visible @interface" errors.
@interface CleverTap (TestPrivateSelectors)
- (id)profileGetLocalValues:(NSString *)propertyName;
- (BOOL)getFeatureFlag:(NSString *)key withDefaultValue:(BOOL)defaultValue;
@end

@interface CleverTapInstanceTests : BaseTestCase

@end

@implementation CleverTapInstanceTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_clevertap_shared_instance_exists {
    XCTAssertNotNil(self.cleverTapInstance);
}

//- (void)test_clevertap_addtional_instance_exists {
//    XCTAssertNotNil(self.additionalInstance);
//}

- (void)test_clevertap_instance_has_guid {
    NSString *ctguid = [self.cleverTapInstance profileGetCleverTapID];
    XCTAssertNotNil(ctguid);
}

- (void)test_clevertap_instance_sets_creds_in_info_plist{
    CTPlistInfo *plistInfo = [CTPlistInfo sharedInstance];
    XCTAssertEqualObjects(plistInfo.accountId, @"test");
    XCTAssertEqualObjects(plistInfo.accountToken, @"test");
    XCTAssertEqualObjects(plistInfo.accountRegion, @"eu1");
}

- (void)test_clevertap_instance_personalization_enabled{
    [CleverTap enablePersonalization];
    BOOL result = [CTPreferences getIntForKey:@"boolPersonalisationEnabled" withResetValue:0];
    XCTAssertTrue(result);
}

- (void)test_clevertap_instance_personalization_disabled {
    [CleverTap disablePersonalization];
    BOOL result = [CTPreferences getIntForKey:@"boolPersonalisationEnabled" withResetValue:0];
    XCTAssertFalse(result);
    [CleverTap enablePersonalization]; // restore so subsequent tests are not affected
}

- (void)test_clevertap_shared_get_global_instance {
    CleverTap *shared = [CleverTap sharedInstance];
    CleverTap *instance = [CleverTap getGlobalInstance:[shared getAccountID]];
    XCTAssertEqualObjects(instance, shared);
}

- (void)test_clevertap_get_global_instance {
    CleverTap *instance = [CleverTap getGlobalInstance:@"test"];
    XCTAssertNotNil(instance);
    XCTAssertEqualObjects([[instance config] accountId], @"test");
    XCTAssertEqualObjects([[instance config] accountToken], @"test");
}

- (void)testSetOptOutFailsWhenBothNO {
    id instanceMock = OCMPartialMock(self.cleverTapInstance);
    [instanceMock setOptOut:NO allowSystemEvents:NO];
    OCMVerify([instanceMock profilePush:[OCMArg any]]);
    [instanceMock stopMocking];
}

- (void)testOptOutYES_allowSystemEventsNO {
    id dispatchQueueManagerMock = OCMClassMock([CTDispatchQueueManager class]);
    self.cleverTapInstance.dispatchQueueManager = dispatchQueueManagerMock;
    
    // Making runSerialAsync run immediately
    OCMStub([self.cleverTapInstance.dispatchQueueManager runSerialAsync:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^block)(void);
            [invocation getArgument:&block atIndex:2];
            block();
        });
    
    [self.cleverTapInstance setOptOut:YES allowSystemEvents:NO];
    XCTAssertTrue(self.cleverTapInstance.currentUserOptedOut);
    XCTAssertFalse(self.cleverTapInstance.currentUserOptedOutAllowSystemEvents);
    [dispatchQueueManagerMock stopMocking];
}

- (void)testOptOutYES_allowSystemEventsYES {
    self.cleverTapInstance.dispatchQueueManager = OCMClassMock([CTDispatchQueueManager class]);
    OCMStub([self.cleverTapInstance.dispatchQueueManager runSerialAsync:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        void (^block)(void);
        [invocation getArgument:&block atIndex:2];
        block();
    });

    [self.cleverTapInstance setOptOut:YES allowSystemEvents:YES];
    
    XCTAssertTrue(self.cleverTapInstance.currentUserOptedOut);
    XCTAssertTrue(self.cleverTapInstance.currentUserOptedOutAllowSystemEvents);
}

- (void)testOptOutNO_allowSystemEventsYES {
    self.cleverTapInstance.dispatchQueueManager = OCMClassMock([CTDispatchQueueManager class]);
    OCMStub([self.cleverTapInstance.dispatchQueueManager runSerialAsync:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        void (^block)(void);
        [invocation getArgument:&block atIndex:2];
        block();
    });

    [self.cleverTapInstance setOptOut:NO allowSystemEvents:YES];

    XCTAssertFalse(self.cleverTapInstance.currentUserOptedOut);
    XCTAssertTrue(self.cleverTapInstance.currentUserOptedOutAllowSystemEvents);
}

- (void)testSetOptOutAliasCallsMainMethodWithNOSystemEvents {
    id instanceMock = OCMPartialMock(self.cleverTapInstance);
    OCMExpect([instanceMock setOptOut:YES allowSystemEvents:NO]);
    [instanceMock setOptOut:YES];
    OCMVerifyAll(instanceMock);
    [instanceMock stopMocking];
}

- (void)testShouldDropEventReturnsNOForFetchType {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"anyEvent"};
    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:CleverTapEventTypeFetch];
    XCTAssertFalse(result, @"Fetch event type should never be dropped");
}

- (void)testShouldDropEventDropsSystemEventWhenOptedOutAndDisallowSystemEvents {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"_system_event_name"};
    self.cleverTapInstance.currentUserOptedOut = YES;
    self.cleverTapInstance.currentUserOptedOutAllowSystemEvents = NO;

    id validatorMock = OCMClassMock([CTValidationConfig class]);
    OCMStub([validatorMock isRestrictedEventName:@"_system_event_name"]).andReturn(YES);

    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:123]; // any non-fetch type
    XCTAssertTrue(result, @"System event should be dropped if opted out and system events disallowed");

    [validatorMock stopMocking];
}

- (void)testShouldDropEventDoesNotDropSystemEventWhenAllowSystemEventsIsYES {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"_system_event_name"};
    self.cleverTapInstance.currentUserOptedOut = YES;
    self.cleverTapInstance.currentUserOptedOutAllowSystemEvents = YES;

    id validatorMock = OCMClassMock([CTValidationConfig class]);
    OCMStub([validatorMock isRestrictedEventName:@"_system_event_name"]).andReturn(YES);

    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:123];
    XCTAssertFalse(result, @"System event should not be dropped if system events are allowed");

    [validatorMock stopMocking];
}

- (void)testShouldDropEventDropsCustomEventWhenOptedOut {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"custom_event"};
    self.cleverTapInstance.currentUserOptedOut = YES;
    self.cleverTapInstance.currentUserOptedOutAllowSystemEvents = NO;

    id validatorMock = OCMClassMock([CTValidationConfig class]);
    OCMStub([validatorMock isRestrictedEventName:@"custom_event"]).andReturn(NO);

    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:123];
    XCTAssertTrue(result, @"Custom event should be dropped if user opted out");

    [validatorMock stopMocking];
}

- (void)testShouldNotDropEventIfUserNotOptedOut {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"custom_event"};
    self.cleverTapInstance.currentUserOptedOut = NO;

    id validatorMock = OCMClassMock([CTValidationConfig class]);
    OCMStub([validatorMock isRestrictedEventName:@"custom_event"]).andReturn(NO);

    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:123];
    XCTAssertFalse(result, @"Event should not be dropped if user not opted out");

    [validatorMock stopMocking];
}

- (void)testShouldDropEventWhenMuted {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"any_event"};
    self.cleverTapInstance.currentUserOptedOut = NO;

    id instanceMock = OCMPartialMock(self.cleverTapInstance);
    OCMStub([instanceMock isMuted]).andReturn(YES);

    BOOL result = [instanceMock _shouldDropEvent:event withType:123];
    XCTAssertTrue(result, @"Event should be dropped if instance is muted");

    [instanceMock stopMocking];
}

- (void)testShouldNotDropFetchEventWhenMuted {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"any_event"};

    id instanceMock = OCMPartialMock(self.cleverTapInstance);
    OCMStub([instanceMock isMuted]).andReturn(YES);

    BOOL result = [instanceMock _shouldDropEvent:event withType:CleverTapEventTypeFetch];
    XCTAssertFalse(result, @"Fetch events should never be dropped, even when the SDK is muted");

    [instanceMock stopMocking];
}

- (void)testShouldNotDropEventWhenNotMutedAndNotOptedOut {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"custom_event"};
    self.cleverTapInstance.currentUserOptedOut = NO;

    id instanceMock = OCMPartialMock(self.cleverTapInstance);
    OCMStub([instanceMock isMuted]).andReturn(NO);

    BOOL result = [instanceMock _shouldDropEvent:event withType:CleverTapEventTypeRaised];
    XCTAssertFalse(result, @"Events should not be dropped when the SDK is neither muted nor opted out");

    [instanceMock stopMocking];
}

#pragma mark - setOffline / offline

- (void)test_setOffline_YES_offlineGetterReturnsYES {
    [self.cleverTapInstance setOffline:YES];
    XCTAssertTrue(self.cleverTapInstance.offline);
}

- (void)test_setOffline_NO_offlineGetterReturnsNO {
    [self.cleverTapInstance setOffline:YES];
    [self.cleverTapInstance setOffline:NO];
    XCTAssertFalse(self.cleverTapInstance.offline);
}

#pragma mark - isCleverTapNotification:

- (void)test_isCleverTapNotification_withWzrkPrefixedKey_returnsYES {
    NSDictionary *aps = @{@"alert": @"Hello"};
    NSDictionary *payload = @{@"wzrk_id": @"campaign_123", @"aps": aps};
    XCTAssertTrue([self.cleverTapInstance isCleverTapNotification:payload]);
}

- (void)test_isCleverTapNotification_withWDollarPrefixedKey_returnsYES {
    NSDictionary *payload = @{@"W$id": @"campaign_123"};
    XCTAssertTrue([self.cleverTapInstance isCleverTapNotification:payload]);
}

- (void)test_isCleverTapNotification_withNoCleverTapKeys_returnsNO {
    NSDictionary *aps = @{@"alert": @"Hello"};
    NSDictionary *payload = @{@"aps": aps, @"custom_key": @"value"};
    XCTAssertFalse([self.cleverTapInstance isCleverTapNotification:payload]);
}

- (void)test_isCleverTapNotification_withEmptyPayload_returnsNO {
    NSDictionary *emptyPayload = @{};
    XCTAssertFalse([self.cleverTapInstance isCleverTapNotification:emptyPayload]);
}

#pragma mark - getAccountID

- (void)test_getAccountID_returnsConfiguredAccountId {
    XCTAssertEqualObjects([self.cleverTapInstance getAccountID], @"test");
}

- (void)test_getAccountID_additionalInstance_returnsItsOwnAccountId {
    XCTAssertEqualObjects([self.additionalInstance getAccountID], @"testAddtional");
}

#pragma mark - setDebugLevel / getDebugLevel

- (void)test_setDebugLevel_info_getDebugLevelReturnsInfo {
    [CleverTap setDebugLevel:CleverTapLogInfo];
    XCTAssertEqual([CleverTap getDebugLevel], CleverTapLogInfo);
    [CleverTap setDebugLevel:CleverTapLogDebug]; // restore
}

- (void)test_setDebugLevel_off_getDebugLevelReturnsOff {
    [CleverTap setDebugLevel:CleverTapLogOff];
    XCTAssertEqual([CleverTap getDebugLevel], CleverTapLogOff);
    [CleverTap setDebugLevel:CleverTapLogDebug]; // restore
}

#pragma mark - isValidCleverTapId:

- (void)test_isValidCleverTapId_alphanumericId_returnsYES {
    XCTAssertTrue([CleverTap isValidCleverTapId:@"user123"]);
}

- (void)test_isValidCleverTapId_allowedSpecialChars_returnsYES {
    XCTAssertTrue([CleverTap isValidCleverTapId:@"user(id)!:@$_-"]);
}

- (void)test_isValidCleverTapId_nil_returnsNO {
    XCTAssertFalse([CleverTap isValidCleverTapId:nil]);
}

- (void)test_isValidCleverTapId_emptyString_returnsNO {
    XCTAssertFalse([CleverTap isValidCleverTapId:@""]);
}

- (void)test_isValidCleverTapId_exceeds64Chars_returnsNO {
    NSString *longId = [@"" stringByPaddingToLength:65 withString:@"a" startingAtIndex:0];
    XCTAssertFalse([CleverTap isValidCleverTapId:longId]);
}

- (void)test_isValidCleverTapId_invalidSpecialChars_returnsNO {
    XCTAssertFalse([CleverTap isValidCleverTapId:@"bad#id"]);
    XCTAssertFalse([CleverTap isValidCleverTapId:@"bad&id"]);
}

#pragma mark - profileGetCleverTapAttributionIdentifier

- (void)test_profileGetCleverTapAttributionIdentifier_isNonNil {
    XCTAssertNotNil([self.cleverTapInstance profileGetCleverTapAttributionIdentifier]);
}

- (void)test_profileGetCleverTapAttributionIdentifier_matchesProfileGetCleverTapID {
    NSString *ctid = [self.cleverTapInstance profileGetCleverTapID];
    NSString *attrId = [self.cleverTapInstance profileGetCleverTapAttributionIdentifier];
    XCTAssertEqualObjects(ctid, attrId);
}

#pragma mark - getGlobalInstance:

- (void)test_getGlobalInstance_unknownAccountId_returnsNil {
    CleverTap *instance = [CleverTap getGlobalInstance:@"nonexistent_account_xyz_abc"];
    XCTAssertNil(instance);
}

#pragma mark - instanceWithConfig:

- (void)test_instanceWithConfig_configAccountIdIsPreserved {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
                                       initWithAccountId:@"configTestAcct"
                                       accountToken:@"configTestToken"];
    CleverTap *instance = [CleverTap instanceWithConfig:config];
    XCTAssertEqualObjects([instance getAccountID], @"configTestAcct");
}

#pragma mark - setLibrary:

- (void)test_setLibrary_updatesDeviceInfoLibrary {
    [self.cleverTapInstance setLibrary:@"Flutter"];
    XCTAssertEqualObjects(self.cleverTapInstance.deviceInfo.library, @"Flutter");
}

#pragma mark - getBatchHeader

- (void)test_getBatchHeader_returnsNonNilDictionary {
    NSDictionary *header = [self batchHeaderForTesting];
    XCTAssertNotNil(header);
}

- (void)test_getBatchHeader_typeIsMeta {
    NSDictionary *header = [self batchHeaderForTesting];
    XCTAssertEqualObjects(header[@"type"], @"meta");
}

- (void)test_getBatchHeader_containsAccountIdAndToken {
    NSDictionary *header = [self batchHeaderForTesting];
    XCTAssertEqualObjects(header[@"id"], @"test");
    XCTAssertEqualObjects(header[@"tk"], @"test");
}

- (void)test_getBatchHeader_containsDeviceId {
    NSDictionary *header = [self batchHeaderForTesting];
    XCTAssertNotNil(header[@"g"]);
    XCTAssertGreaterThan([header[@"g"] length], 0u);
}

- (void)test_getBatchHeader_containsAppFields {
    NSDictionary *header = [self batchHeaderForTesting];
    XCTAssertNotNil(header[@"af"]);
    XCTAssertTrue([header[@"af"] isKindOfClass:[NSDictionary class]]);
}

#pragma mark - sessionGetTimeElapsed

- (void)test_sessionGetTimeElapsed_returnsNonNegativeValue {
    NSTimeInterval elapsed = [self.cleverTapInstance sessionGetTimeElapsed];
    XCTAssertGreaterThanOrEqual(elapsed, 0);
}

- (void)test_sessionGetTimeElapsed_isReasonablySmall {
    // The session was started at most a few seconds ago during setUp
    NSTimeInterval elapsed = [self.cleverTapInstance sessionGetTimeElapsed];
    XCTAssertLessThan(elapsed, 300);  // less than 5 minutes
}

#pragma mark - sessionGetUTMDetails

- (void)test_sessionGetUTMDetails_returnsNonNilObject {
    CleverTapUTMDetail *utmDetail = [self.cleverTapInstance sessionGetUTMDetails];
    XCTAssertNotNil(utmDetail);
}

- (void)test_sessionGetUTMDetails_returnsUTMDetailInstance {
    id utmDetail = [self.cleverTapInstance sessionGetUTMDetails];
    XCTAssertTrue([utmDetail isKindOfClass:[CleverTapUTMDetail class]]);
}

#pragma mark - userSetLocation / setUserSetLocation:

- (void)test_setUserSetLocation_getterReturnsSetLatitude {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.3318, -122.0312);
    [self.cleverTapInstance setUserSetLocation:coord];
    CLLocationCoordinate2D result = self.cleverTapInstance.userSetLocation;
    XCTAssertEqualWithAccuracy(result.latitude, coord.latitude, 0.00001);
}

- (void)test_setUserSetLocation_getterReturnsSetLongitude {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.3318, -122.0312);
    [self.cleverTapInstance setUserSetLocation:coord];
    CLLocationCoordinate2D result = self.cleverTapInstance.userSetLocation;
    XCTAssertEqualWithAccuracy(result.longitude, coord.longitude, 0.00001);
}

- (void)test_setUserSetLocation_updatesOnSubsequentCall {
    CLLocationCoordinate2D first  = CLLocationCoordinate2DMake(10.0, 20.0);
    CLLocationCoordinate2D second = CLLocationCoordinate2DMake(50.0, 60.0);
    [self.cleverTapInstance setUserSetLocation:first];
    [self.cleverTapInstance setUserSetLocation:second];
    CLLocationCoordinate2D result = self.cleverTapInstance.userSetLocation;
    XCTAssertEqualWithAccuracy(result.latitude,  second.latitude,  0.00001);
    XCTAssertEqualWithAccuracy(result.longitude, second.longitude, 0.00001);
}

#pragma mark - isPersonalizationEnabled

- (void)test_isPersonalizationEnabled_afterEnablePersonalization_returnsYES {
    [CleverTap enablePersonalization];
    XCTAssertTrue([CleverTap isPersonalizationEnabled]);
}

- (void)test_isPersonalizationEnabled_afterDisablePersonalization_returnsNO {
    [CleverTap disablePersonalization];
    XCTAssertFalse([CleverTap isPersonalizationEnabled]);
    [CleverTap enablePersonalization]; // restore
}

#pragma mark - recordScreenView:

- (void)test_recordScreenView_incrementsScreenCount {
    // Call once to establish a baseline screen name
    [self.cleverTapInstance recordScreenView:@"CT_Test_Screen_A"];
    int countAfterFirst = self.cleverTapInstance.sessionManager.screenCount;

    // Call with a different name — should increment
    [self.cleverTapInstance recordScreenView:@"CT_Test_Screen_B"];
    int countAfterSecond = self.cleverTapInstance.sessionManager.screenCount;

    XCTAssertEqual(countAfterSecond, countAfterFirst + 1);
}

- (void)test_recordScreenView_duplicateNameDoesNotIncrementScreenCount {
    [self.cleverTapInstance recordScreenView:@"CT_Test_Screen_Dup"];
    int countAfterFirst = self.cleverTapInstance.sessionManager.screenCount;

    // Same name again — should be skipped
    [self.cleverTapInstance recordScreenView:@"CT_Test_Screen_Dup"];
    int countAfterDup = self.cleverTapInstance.sessionManager.screenCount;

    XCTAssertEqual(countAfterDup, countAfterFirst);
}

- (void)test_recordScreenView_nilNameDoesNotIncrementScreenCount {
    [self.cleverTapInstance recordScreenView:@"CT_Test_Screen_BeforeNil"];
    int countBefore = self.cleverTapInstance.sessionManager.screenCount;

    [self.cleverTapInstance recordScreenView:nil];
    int countAfter = self.cleverTapInstance.sessionManager.screenCount;

    XCTAssertEqual(countAfter, countBefore);
}

#pragma mark - recordEvent:

- (void)test_recordEvent_queuesEventWithRaisedType {
    // Stub the serial queue to execute blocks synchronously so we can assert immediately.
    id mockDispatch = OCMPartialMock(self.cleverTapInstance.dispatchQueueManager);
    OCMStub([mockDispatch runSerialAsync:[OCMArg invokeBlock]]);

    id mockInstance = OCMPartialMock(self.cleverTapInstance);
    OCMExpect([mockInstance queueEvent:[OCMArg any] withType:CleverTapEventTypeRaised]);

    [self.cleverTapInstance recordEvent:@"CT_Test_SimpleEvent"];

    OCMVerifyAll(mockInstance);
    [mockInstance stopMocking];
    [mockDispatch stopMocking];
}

- (void)test_recordEvent_withNilName_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordEvent:nil]);
}

- (void)test_recordEvent_withEmptyName_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordEvent:@""]);
}

#pragma mark - recordEvent:withProps:

- (void)test_recordEventWithProps_queuesEvent {
    id mockDispatch = OCMPartialMock(self.cleverTapInstance.dispatchQueueManager);
    OCMStub([mockDispatch runSerialAsync:[OCMArg invokeBlock]]);

    NSDictionary *props = @{@"key1": @"value1", @"count": @42};
    NSUInteger initialCount = self.cleverTapInstance.eventsQueue.count;
    [self.cleverTapInstance recordEvent:@"CT_Test_PropsEvent" withProps:props];

    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, initialCount);
    [mockDispatch stopMocking];
}

- (void)test_recordEventWithProps_withNilProps_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordEvent:@"CT_Test_NilProps" withProps:nil]);
}

#pragma mark - recordChargedEventWithDetails:andItems:

- (void)test_recordChargedEvent_withValidDetails_queuesEvent {
    id mockDispatch = OCMPartialMock(self.cleverTapInstance.dispatchQueueManager);
    OCMStub([mockDispatch runSerialAsync:[OCMArg invokeBlock]]);

    NSDictionary *chargeDetails = @{@"Amount": @99, @"Currency": @"USD", @"Payment Mode": @"Credit"};
    NSDictionary *item = @{@"Name": @"Widget", @"Amount": @49, @"Quantity": @2};
    NSArray *items = @[item];
    NSUInteger initialCount = self.cleverTapInstance.eventsQueue.count;

    [self.cleverTapInstance recordChargedEventWithDetails:chargeDetails andItems:items];

    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, initialCount);
    [mockDispatch stopMocking];
}

- (void)test_recordChargedEvent_withEmptyItems_queuesEvent {
    id mockDispatch = OCMPartialMock(self.cleverTapInstance.dispatchQueueManager);
    OCMStub([mockDispatch runSerialAsync:[OCMArg invokeBlock]]);

    NSDictionary *chargeDetails = @{@"Amount": @50, @"Currency": @"EUR"};
    NSUInteger initialCount = self.cleverTapInstance.eventsQueue.count;

    NSArray *emptyItems = @[];
    [self.cleverTapInstance recordChargedEventWithDetails:chargeDetails andItems:emptyItems];

    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, initialCount);
    [mockDispatch stopMocking];
}

- (void)test_recordChargedEvent_withNilDetails_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordChargedEventWithDetails:nil andItems:nil]);
}

#pragma mark - enableDeviceNetworkInfoReporting:

- (void)test_enableDeviceNetworkInfoReporting_YES_setsUseIPTrueInBatchHeaderAppFields {
    [self.cleverTapInstance enableDeviceNetworkInfoReporting:YES];
    NSDictionary *appFields = [self batchHeaderForTesting][@"af"];
    XCTAssertEqualObjects(appFields[@"useIP"], @YES);
}

- (void)test_enableDeviceNetworkInfoReporting_NO_setsUseIPFalseInBatchHeaderAppFields {
    [self.cleverTapInstance enableDeviceNetworkInfoReporting:NO];
    NSDictionary *appFields = [self batchHeaderForTesting][@"af"];
    XCTAssertEqualObjects(appFields[@"useIP"], @NO);
}

- (void)test_enableDeviceNetworkInfoReporting_togglesCorrectly {
    [self.cleverTapInstance enableDeviceNetworkInfoReporting:YES];
    XCTAssertEqualObjects([self batchHeaderForTesting][@"af"][@"useIP"], @YES);

    [self.cleverTapInstance enableDeviceNetworkInfoReporting:NO];
    XCTAssertEqualObjects([self batchHeaderForTesting][@"af"][@"useIP"], @NO);
}

#pragma mark - setCustomSdkVersion:version:

- (void)test_setCustomSdkVersion_appearsInBatchHeaderAppFields {
    [self.cleverTapInstance setCustomSdkVersion:@"CT_UnitTestSDK" version:42];
    NSDictionary *appFields = [self batchHeaderForTesting][@"af"];
    XCTAssertEqualObjects(appFields[@"CT_UnitTestSDK"], @42);
}

- (void)test_setCustomSdkVersion_multipleVersions_allAppearInBatchHeaderAppFields {
    [self.cleverTapInstance setCustomSdkVersion:@"CT_FlutterSDKTest" version:10];
    [self.cleverTapInstance setCustomSdkVersion:@"CT_ReactNativeSDKTest" version:5];
    NSDictionary *appFields = [self batchHeaderForTesting][@"af"];
    XCTAssertEqualObjects(appFields[@"CT_FlutterSDKTest"], @10);
    XCTAssertEqualObjects(appFields[@"CT_ReactNativeSDKTest"], @5);
}

- (void)test_setCustomSdkVersion_overwritesPreviousVersion {
    [self.cleverTapInstance setCustomSdkVersion:@"CT_OverwriteSDK" version:1];
    [self.cleverTapInstance setCustomSdkVersion:@"CT_OverwriteSDK" version:2];
    NSDictionary *appFields = [self batchHeaderForTesting][@"af"];
    XCTAssertEqualObjects(appFields[@"CT_OverwriteSDK"], @2);
}

#pragma mark - getUserLastVisitTs

- (void)test_getUserLastVisitTs_returnsNonNegativeValue {
    [CleverTap enablePersonalization];
    NSTimeInterval ts = [self.cleverTapInstance getUserLastVisitTs];
    XCTAssertGreaterThanOrEqual(ts, 0);
}

// Helper: returns the batch header for cleverTapInstance, temporarily setting
// domainFactory.redirectDomain so that batchHeader does not return nil in tests
// (no real server handshake happens in the test environment).
- (NSDictionary *)batchHeaderForTesting {
    NSString *savedDomain = self.cleverTapInstance.domainFactory.redirectDomain;
    self.cleverTapInstance.domainFactory.redirectDomain = @"eu1.clevertap.com";
    NSDictionary *header = [self.cleverTapInstance getBatchHeader];
    self.cleverTapInstance.domainFactory.redirectDomain = savedDomain;
    return header;
}

// Helper: returns a dispatch queue manager partial mock whose runSerialAsync:
// executes blocks synchronously so we can assert on queue state immediately.
- (id)synchronousDispatchMockForInstance:(CleverTap *)instance {
    id mockDispatch = OCMPartialMock(instance.dispatchQueueManager);
    OCMStub([mockDispatch runSerialAsync:[OCMArg invokeBlock]]);
    return mockDispatch;
}

#pragma mark - profilePush:

- (void)test_profilePush_withValidProperties_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSDictionary *profileProps = @{@"Name": @"Test User", @"Age": @25};
    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profilePush:profileProps];

    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_profilePush_withNilProperties_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profilePush:nil]);
}

- (void)test_profilePush_withEmptyDictionary_doesNotThrow {
    NSDictionary *emptyProps = @{};
    XCTAssertNoThrow([self.cleverTapInstance profilePush:emptyProps]);
}

#pragma mark - profileRemoveValueForKey:

- (void)test_profileRemoveValueForKey_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profileRemoveValueForKey:@"CT_TestRemoveKey"];

    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_profileRemoveValueForKey_withNilKey_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileRemoveValueForKey:nil]);
}

#pragma mark - profileSetMultiValues:forKey:

- (void)test_profileSetMultiValues_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSArray *sportsValues = @[@"soccer", @"tennis"];
    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profileSetMultiValues:sportsValues forKey:@"CT_Sports"];

    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_profileSetMultiValues_withEmptyArray_doesNotThrow {
    NSArray *emptyValues = @[];
    XCTAssertNoThrow([self.cleverTapInstance profileSetMultiValues:emptyValues forKey:@"CT_Sports"]);
}

- (void)test_profileSetMultiValues_withNilKey_doesNotThrow {
    NSArray *singleValue = @[@"value"];
    XCTAssertNoThrow([self.cleverTapInstance profileSetMultiValues:singleValue forKey:nil]);
}

#pragma mark - profileAddMultiValue:forKey:

- (void)test_profileAddMultiValue_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profileAddMultiValue:@"hockey" forKey:@"CT_Sports"];

    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_profileAddMultiValue_withNilValue_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileAddMultiValue:nil forKey:@"CT_Sports"]);
}

#pragma mark - profileAddMultiValues:forKey:

- (void)test_profileAddMultiValues_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSArray *additionalSports = @[@"cricket", @"badminton"];
    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profileAddMultiValues:additionalSports forKey:@"CT_Sports"];

    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_profileAddMultiValues_withNilValues_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileAddMultiValues:nil forKey:@"CT_Sports"]);
}

#pragma mark - profileRemoveMultiValue:forKey:

- (void)test_profileRemoveMultiValue_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileRemoveMultiValue:@"hockey" forKey:@"CT_Sports"]);
}

- (void)test_profileRemoveMultiValue_withNilValue_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileRemoveMultiValue:nil forKey:@"CT_Sports"]);
}

#pragma mark - profileIncrementValueBy:forKey: / profileDecrementValueBy:forKey:

- (void)test_profileIncrementValueBy_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profileIncrementValueBy:@5 forKey:@"CT_Points"];

    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_profileDecrementValueBy_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profileDecrementValueBy:@3 forKey:@"CT_Points"];

    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_profileIncrementValueBy_withZeroValue_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileIncrementValueBy:@0 forKey:@"CT_Points"]);
}

- (void)test_profileDecrementValueBy_withNilKey_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileDecrementValueBy:@1 forKey:nil]);
}

#pragma mark - recordErrorWithMessage:andErrorCode:

- (void)test_recordErrorWithMessage_queuesEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];

    NSUInteger countBefore = self.cleverTapInstance.eventsQueue.count;
    [self.cleverTapInstance recordErrorWithMessage:@"Something went wrong" andErrorCode:500];

    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, countBefore);
    [mockDispatch stopMocking];
}

- (void)test_recordErrorWithMessage_withNilMessage_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordErrorWithMessage:nil andErrorCode:0]);
}

- (void)test_recordErrorWithMessage_withNegativeCode_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordErrorWithMessage:@"error" andErrorCode:-1]);
}

// Helper: creates a CleverTap instance with a unique account ID and
// enablePersonalization set to the given value. Used to test the
// personalization-gated guard branches in event/profile query methods.
- (CleverTap *)instanceWithPersonalization:(BOOL)enabled suffix:(NSString *)suffix {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
                                       initWithAccountId:[NSString stringWithFormat:@"CT_Perso%@_%@", enabled ? @"Y" : @"N", suffix]
                                       accountToken:@"test_token"];
    config.enablePersonalization = enabled;
    return [CleverTap instanceWithConfig:config];
}

#pragma mark - setOptOut: / setOptOut:allowSystemEvents:

- (void)test_setOptOut_YES_setsCurrentUserOptedOutToYES {
    id mock = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    [self.cleverTapInstance setOptOut:YES];
    BOOL result = self.cleverTapInstance.currentUserOptedOut;
    [self.cleverTapInstance setOptOut:NO]; // restore while mock is still active
    [mock stopMocking];
    XCTAssertTrue(result);
}

- (void)test_setOptOut_NO_setsCurrentUserOptedOutToNO {
    id mock = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    [self.cleverTapInstance setOptOut:YES];
    [self.cleverTapInstance setOptOut:NO];
    BOOL result = self.cleverTapInstance.currentUserOptedOut;
    [mock stopMocking];
    XCTAssertFalse(result);
}

- (void)test_setOptOut_YES_setsAllowSystemEventsToNO {
    // setOptOut:YES calls setOptOut:YES allowSystemEvents:!YES
    // resolvedAllowSystemEvents = !YES || NO = NO
    id mock = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    [self.cleverTapInstance setOptOut:YES];
    BOOL result = self.cleverTapInstance.currentUserOptedOutAllowSystemEvents;
    [self.cleverTapInstance setOptOut:NO]; // restore
    [mock stopMocking];
    XCTAssertFalse(result);
}

- (void)test_setOptOut_YES_allowSystemEvents_YES_setsAllowSystemEventsToYES {
    // resolvedAllowSystemEvents = !YES || YES = YES
    id mock = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    [self.cleverTapInstance setOptOut:YES allowSystemEvents:YES];
    BOOL optedOut    = self.cleverTapInstance.currentUserOptedOut;
    BOOL allowSystem = self.cleverTapInstance.currentUserOptedOutAllowSystemEvents;
    [self.cleverTapInstance setOptOut:NO]; // restore
    [mock stopMocking];
    XCTAssertTrue(optedOut);
    XCTAssertTrue(allowSystem);
}

- (void)test_setOptOut_NO_allowSystemEvents_YES_setsAllowSystemEventsToYES {
    // resolvedAllowSystemEvents = !NO || YES = YES
    id mock = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    [self.cleverTapInstance setOptOut:NO allowSystemEvents:YES];
    BOOL result = self.cleverTapInstance.currentUserOptedOutAllowSystemEvents;
    [mock stopMocking];
    XCTAssertTrue(result);
}

#pragma mark - profileGet: / getProperty:

- (void)test_profileGet_whenPersonalizationDisabled_returnsNil {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"profileGet"];
    id result = [instance profileGet:@"Name"];
    XCTAssertNil(result);
}

- (void)test_getProperty_aliasesProfileGet_bothReturnSameValue {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"getProperty"];
    id profileResult     = [instance profileGet:@"Name"];
    id getPropertyResult = [instance getProperty:@"Name"];
    XCTAssertEqual(profileResult, getPropertyResult); // both nil
}

#pragma mark - eventGetFirstTime: / eventGetLastTime: / eventGetOccurrences:

- (void)test_eventGetFirstTime_whenPersonalizationDisabled_returnsNegativeOne {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"firstTime"];
    XCTAssertEqual([instance eventGetFirstTime:@"CT_Test_Event"], -1);
}

- (void)test_eventGetLastTime_whenPersonalizationDisabled_returnsNegativeOne {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"lastTime"];
    XCTAssertEqual([instance eventGetLastTime:@"CT_Test_Event"], -1);
}

- (void)test_eventGetOccurrences_whenPersonalizationDisabled_returnsNegativeOne {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"occurrences"];
    XCTAssertEqual([instance eventGetOccurrences:@"CT_Test_Event"], -1);
}

#pragma mark - userGetEventHistory / eventGetDetail:

- (void)test_userGetEventHistory_whenPersonalizationDisabled_returnsNil {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"eventHistory"];
    XCTAssertNil([instance userGetEventHistory]);
}

- (void)test_eventGetDetail_whenPersonalizationDisabled_returnsNil {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"eventDetail"];
    XCTAssertNil([instance eventGetDetail:@"CT_Test_Event"]);
}

#pragma mark - getUserEventLogCount: / getUserEventLog: / getUserEventLogHistory

- (void)test_getUserEventLogCount_whenPersonalizationDisabled_returnsNegativeOne {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"logCount"];
    XCTAssertEqual([instance getUserEventLogCount:@"CT_Test_Event"], -1);
}

- (void)test_getUserEventLog_whenPersonalizationDisabled_returnsNil {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"eventLog"];
    XCTAssertNil([instance getUserEventLog:@"CT_Test_Event"]);
}

- (void)test_getUserEventLogHistory_whenPersonalizationDisabled_returnsNil {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"logHistory"];
    XCTAssertNil([instance getUserEventLogHistory]);
}

#pragma mark - userGetScreenCount / userGetTotalVisits / userGetPreviousVisitTime

- (void)test_userGetScreenCount_matchesSessionManagerScreenCount {
    int apiCount     = [self.cleverTapInstance userGetScreenCount];
    int sessionCount = self.cleverTapInstance.sessionManager.screenCount;
    XCTAssertEqual(apiCount, sessionCount);
}

- (void)test_userGetScreenCount_incrementsAfterRecordScreenView {
    [self.cleverTapInstance recordScreenView:@"CT_Count_ScreenA"];
    int countA = [self.cleverTapInstance userGetScreenCount];

    [self.cleverTapInstance recordScreenView:@"CT_Count_ScreenB"];
    int countB = [self.cleverTapInstance userGetScreenCount];

    XCTAssertEqual(countB, countA + 1);
}

- (void)test_userGetTotalVisits_whenPersonalizationDisabled_returnsNegativeOne {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"totalVisits"];
    XCTAssertEqual([instance userGetTotalVisits], -1);
}

- (void)test_userGetPreviousVisitTime_returnsValidValue {
    // userGetPreviousVisitTime returns self.lastAppLaunchedTime, which is captured once
    // at init via eventGetLastTime:. When no prior App Launched event exists in the data
    // store (e.g. a fresh simulator), CTLocalDataStore returns -1 as the sentinel value.
    // On subsequent runs a non-negative Unix timestamp is returned. Both are valid.
    NSTimeInterval ts = [self.cleverTapInstance userGetPreviousVisitTime];
    XCTAssertTrue(ts == -1 || ts >= 0,
                  @"Expected -1 (no prior visit) or a non-negative Unix timestamp, got %f", ts);
}

#pragma mark - setLocale:

- (void)test_setLocale_localeIdentifierAppearsInBatchHeaderAppFields {
    NSLocale *testLocale = [NSLocale localeWithLocaleIdentifier:@"fr_FR"];
    [self.cleverTapInstance setLocale:testLocale];
    NSDictionary *appFields = [self batchHeaderForTesting][@"af"];
    XCTAssertEqualObjects(appFields[@"locale"], @"fr_FR");
}

- (void)test_setLocale_changingLocaleUpdatesNextBatchHeader {
    [self.cleverTapInstance setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
    XCTAssertEqualObjects([self batchHeaderForTesting][@"af"][@"locale"], @"de_DE");

    [self.cleverTapInstance setLocale:[NSLocale localeWithLocaleIdentifier:@"ja_JP"]];
    XCTAssertEqualObjects([self batchHeaderForTesting][@"af"][@"locale"], @"ja_JP");
}

#pragma mark - onUserLogin:

- (void)test_onUserLogin_withValidProperties_doesNotThrow {
    NSDictionary *loginProps = @{@"Identity": @"ct_test_user_001", @"Name": @"CT Test User"};
    XCTAssertNoThrow([self.cleverTapInstance onUserLogin:loginProps]);
}

- (void)test_onUserLogin_withCleverTapID_doesNotThrow {
    NSDictionary *loginProps = @{@"Name": @"CT Test User"};
    XCTAssertNoThrow([self.cleverTapInstance onUserLogin:loginProps withCleverTapID:@"ct_custom_id_001"]);
}

- (void)test_onUserLogin_withEmptyProperties_doesNotThrow {
    NSDictionary *emptyProps = @{};
    XCTAssertNoThrow([self.cleverTapInstance onUserLogin:emptyProps]);
}

#pragma mark - setSyncDelegate:

- (void)test_setSyncDelegate_withConformingDelegate_storesDelegate {
    id mockDelegate = OCMProtocolMock(@protocol(CleverTapSyncDelegate));
    [self.cleverTapInstance setSyncDelegate:mockDelegate];
    XCTAssertEqualObjects([self.cleverTapInstance valueForKey:@"syncDelegate"], mockDelegate);
}

- (void)test_setSyncDelegate_withNonConformingObject_doesNotOverwriteDelegate {
    // Record delegate before the attempt
    id previous = [self.cleverTapInstance valueForKey:@"syncDelegate"];
    NSObject *nonConforming = [[NSObject alloc] init];
    [self.cleverTapInstance setSyncDelegate:(id<CleverTapSyncDelegate>)nonConforming];
    id after = [self.cleverTapInstance valueForKey:@"syncDelegate"];
    // Non-conforming object must NOT have been stored
    XCTAssertNotEqualObjects(after, nonConforming);
    // Previous delegate must be preserved
    XCTAssertEqualObjects(after, previous);
}

#pragma mark - setUrlDelegate:

- (void)test_setUrlDelegate_withConformingDelegate_storesDelegate {
    id mockDelegate = OCMProtocolMock(@protocol(CleverTapURLDelegate));
    [self.cleverTapInstance setUrlDelegate:mockDelegate];
    XCTAssertEqualObjects([self.cleverTapInstance urlDelegate], mockDelegate);
}

- (void)test_setUrlDelegate_withNonConformingObject_doesNotOverwriteDelegate {
    id previous = [self.cleverTapInstance urlDelegate];
    NSObject *nonConforming = [[NSObject alloc] init];
    [self.cleverTapInstance setUrlDelegate:(id<CleverTapURLDelegate>)nonConforming];
    id after = [self.cleverTapInstance urlDelegate];
    XCTAssertNotEqualObjects(after, nonConforming);
    XCTAssertEqualObjects(after, previous);
}

#pragma mark - setPushNotificationDelegate:

- (void)test_setPushNotificationDelegate_withConformingDelegate_storesDelegate {
    id mockDelegate = OCMProtocolMock(@protocol(CleverTapPushNotificationDelegate));
    [self.cleverTapInstance setPushNotificationDelegate:mockDelegate];
    XCTAssertEqualObjects([self.cleverTapInstance valueForKey:@"pushNotificationDelegate"], mockDelegate);
}

- (void)test_setPushNotificationDelegate_withNonConformingObject_doesNotOverwriteDelegate {
    id previous = [self.cleverTapInstance valueForKey:@"pushNotificationDelegate"];
    NSObject *nonConforming = [[NSObject alloc] init];
    [self.cleverTapInstance setPushNotificationDelegate:(id<CleverTapPushNotificationDelegate>)nonConforming];
    id after = [self.cleverTapInstance valueForKey:@"pushNotificationDelegate"];
    XCTAssertNotEqualObjects(after, nonConforming);
    XCTAssertEqualObjects(after, previous);
}

#pragma mark - flushQueue

- (void)test_flushQueue_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance flushQueue]);
}

- (void)test_flushQueue_whenMuted_emptiesEventsQueue {
    id mockDispatch = OCMPartialMock(self.cleverTapInstance.dispatchQueueManager);
    OCMStub([mockDispatch runSerialAsync:[OCMArg invokeBlock]]);
    id mockInstance = OCMPartialMock(self.cleverTapInstance);
    OCMStub([mockInstance isMuted]).andReturn(YES);

    NSDictionary *flushTestEvent = @{@"evtName": @"CT_FlushTest"};
    [self.cleverTapInstance.eventsQueue addObject:flushTestEvent];
    [self.cleverTapInstance flushQueue];

    XCTAssertEqual(self.cleverTapInstance.eventsQueue.count, 0);
    [mockInstance stopMocking];
    [mockDispatch stopMocking];
}

#pragma mark - clearQueue

- (void)test_clearQueue_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance clearQueue]);
}

- (void)test_clearQueue_resultingEventsQueueIsEmpty {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    NSDictionary *clearTestEvent = @{@"evtName": @"CT_ClearQueueTest"};
    [self.cleverTapInstance.eventsQueue addObject:clearTestEvent];
    [self.cleverTapInstance clearQueue];
    XCTAssertEqual(self.cleverTapInstance.eventsQueue.count, 0);
    [mockDispatch stopMocking];
}

#pragma mark - setPushTokenAsString:

- (void)test_setPushTokenAsString_whenAnalyticsOnly_isNoOp {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
        initWithAccountId:@"CT_AnalyticsOnly_Push_001"
        accountToken:@"test_token"];
    config.analyticsOnly = YES;
    CleverTap *analyticsOnlyInstance = [CleverTap instanceWithConfig:config];
    XCTAssertNoThrow([analyticsOnlyInstance setPushTokenAsString:@"ct_test_push_token"]);
}

- (void)test_setPushTokenAsString_withValidToken_doesNotThrow {
    // Regular instance (non-analyticsOnly) should accept the call without throwing
    XCTAssertNoThrow([self.cleverTapInstance setPushTokenAsString:@"ct_test_push_token_valid"]);
}

#pragma mark - pushInstallReferrerSource:medium:campaign:

- (void)test_pushInstallReferrer_withAllNilArgs_doesNotThrow {
    // All-nil guard: method returns early without queuing anything
    XCTAssertNoThrow([self.cleverTapInstance pushInstallReferrerSource:nil
                                                               medium:nil
                                                             campaign:nil]);
}

- (void)test_pushInstallReferrer_withValidArgs_doesNotThrow {
    // Use a fresh instance so install_referrer_status is unset for this accountId
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
        initWithAccountId:@"CT_Referrer_Test_001"
        accountToken:@"test_token"];
    CleverTap *instance = [CleverTap instanceWithConfig:config];
    XCTAssertNoThrow([instance pushInstallReferrerSource:@"CT_TestSource"
                                                 medium:@"CT_TestMedium"
                                               campaign:@"CT_TestCampaign"]);
}

#pragma mark - changeCredentialsWithAccountID:andToken:

- (void)test_changeCredentialsWithAccountIDAndToken_doesNotThrow {
    XCTAssertNoThrow([CleverTap changeCredentialsWithAccountID:@"CT_NewAcct_001"
                                                      andToken:@"CT_NewToken_001"]);
    // Restore plist state: changeCredentials always mutates CTPlistInfo.sharedInstance
    // even when the CleverTap instance is already initialized (the instanceConfig guard
    // only protects the in-memory config, not the plist singleton).
    [CleverTap changeCredentialsWithAccountID:@"test" token:@"test" region:@"eu1"];
}

- (void)test_changeCredentialsWithAccountIDTokenAndRegion_doesNotThrow {
    XCTAssertNoThrow([CleverTap changeCredentialsWithAccountID:@"CT_NewAcct_002"
                                                         token:@"CT_NewToken_002"
                                                        region:@"eu1"]);
    // Restore plist state (same reason as above).
    [CleverTap changeCredentialsWithAccountID:@"test" token:@"test" region:@"eu1"];
}

#pragma mark - profileGet: / profileGetLocalValues: — personalization enabled path

- (void)test_profileGet_enabledPath_andProfileGetLocalValues_returnSameResult {
    // With personalization enabled both methods read from the same local data store.
    // They must agree on whatever value (or nil) is currently stored for a key.
    [CleverTap enablePersonalization];
    id getResult   = [self.cleverTapInstance profileGet:@"CT_NonExistentKey"];
    id localResult = [self.cleverTapInstance profileGetLocalValues:@"CT_NonExistentKey"];
    XCTAssertEqualObjects(getResult, localResult,
        @"profileGet: and profileGetLocalValues: must return the same value when personalization is enabled");
}

- (void)test_profileGet_disabledPath_returnsNilButProfileGetLocalValues_doesNot {
    // profileGet: returns nil from the personalization guard; profileGetLocalValues:
    // bypasses the guard and delegates directly to the data store (may return nil too,
    // but for a different reason — no stored data, not the guard).
    CleverTap *disabled  = [self instanceWithPersonalization:NO  suffix:@"pGet_dis"];
    CleverTap *enabled   = [self instanceWithPersonalization:YES suffix:@"pGet_en"];

    // disabled returns nil due to the guard
    XCTAssertNil([disabled profileGet:@"CT_NonExistentKey2"]);
    // profileGetLocalValues bypasses the guard on the disabled instance too
    // (result may be nil due to no data, but NOT because of the personalization guard)
    XCTAssertNoThrow([disabled profileGetLocalValues:@"CT_NonExistentKey2"]);
    // enabled instance: profileGet goes to the store (result may be nil if key absent)
    XCTAssertNoThrow([enabled profileGet:@"CT_NonExistentKey2"]);
}

- (void)test_profileGetLocalValues_withNilKey_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileGetLocalValues:nil]);
}

#pragma mark - eventGetFirstTime: / eventGetLastTime: / eventGetOccurrences: — personalization enabled path

- (void)test_eventGetFirstTime_whenPersonalizationEnabled_returnsMinusOneOrPositiveTimestamp {
    // When personalization is enabled the method reads from the data store.
    // On a fresh simulator there is no history → -1; on subsequent runs → positive timestamp.
    CleverTap *instance = [self instanceWithPersonalization:YES suffix:@"firstTime_en"];
    NSTimeInterval ts = [instance eventGetFirstTime:CLTAP_APP_LAUNCHED_EVENT];
    XCTAssertTrue(ts == -1 || ts > 0,
                  @"Expected -1 (no history) or a positive Unix timestamp, got %f", ts);
}

- (void)test_eventGetLastTime_whenPersonalizationEnabled_returnsMinusOneOrPositiveTimestamp {
    CleverTap *instance = [self instanceWithPersonalization:YES suffix:@"lastTime_en"];
    NSTimeInterval ts = [instance eventGetLastTime:CLTAP_APP_LAUNCHED_EVENT];
    XCTAssertTrue(ts == -1 || ts > 0,
                  @"Expected -1 (no history) or a positive Unix timestamp, got %f", ts);
}

- (void)test_eventGetOccurrences_whenPersonalizationEnabled_returnsMinusOneOrNonNegative {
    CleverTap *instance = [self instanceWithPersonalization:YES suffix:@"occ_en"];
    int count = [instance eventGetOccurrences:CLTAP_APP_LAUNCHED_EVENT];
    XCTAssertTrue(count == -1 || count >= 0,
                  @"Expected -1 (no history) or non-negative count, got %d", count);
}

#pragma mark - getUserAppLaunchCount

- (void)test_getUserAppLaunchCount_whenPersonalizationDisabled_returnsNegativeOne {
    CleverTap *instance = [self instanceWithPersonalization:NO suffix:@"appLaunchCount_dis"];
    XCTAssertEqual([instance getUserAppLaunchCount], -1);
}

- (void)test_getUserAppLaunchCount_whenPersonalizationEnabled_returnsMinusOneOrNonNegative {
    [CleverTap enablePersonalization];
    int count = [self.cleverTapInstance getUserAppLaunchCount];
    XCTAssertTrue(count == -1 || count >= 0,
                  @"Expected -1 (no history) or non-negative count, got %d", count);
}

#pragma mark - recordNotificationViewedEventWithData: / recordNotificationClickedEventWithData:

- (void)test_recordNotificationViewedEventWithData_withValidPayload_doesNotThrow {
    NSDictionary *payload = @{@"wzrk_id": @"ct_campaign_viewed_001",
                              @"aps": @{@"alert": @"Hello"}};
    XCTAssertNoThrow([self.cleverTapInstance recordNotificationViewedEventWithData:payload]);
}

- (void)test_recordNotificationClickedEventWithData_withValidPayload_doesNotThrow {
    NSDictionary *payload = @{@"wzrk_id": @"ct_campaign_clicked_001",
                              @"aps": @{@"alert": @"Hello"}};
    XCTAssertNoThrow([self.cleverTapInstance recordNotificationClickedEventWithData:payload]);
}

- (void)test_recordNotificationViewedEventWithData_withNilPayload_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordNotificationViewedEventWithData:nil]);
}

- (void)test_recordNotificationClickedEventWithData_withNilPayload_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordNotificationClickedEventWithData:nil]);
}

- (void)test_recordNotificationViewedEventWithData_queuesNotificationViewedEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    NSDictionary *payload = @{@"wzrk_id": @"ct_viewed_q_001",
                              @"aps": @{@"alert": @"Test"}};
    NSUInteger countBefore = self.cleverTapInstance.notificationsQueue.count;
    [self.cleverTapInstance recordNotificationViewedEventWithData:payload];
    XCTAssertGreaterThan(self.cleverTapInstance.notificationsQueue.count, countBefore,
                         @"A notification-viewed event should be added to notificationsQueue");
    [mockDispatch stopMocking];
}

- (void)test_recordNotificationClickedEventWithData_queuesRaisedEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    NSDictionary *payload = @{@"wzrk_id": @"ct_clicked_q_001",
                              @"aps": @{@"alert": @"Test"}};
    NSUInteger countBefore = self.cleverTapInstance.eventsQueue.count;
    [self.cleverTapInstance recordNotificationClickedEventWithData:payload];
    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, countBefore,
                         @"A clicked notification event should be added to eventsQueue as a raised event");
    [mockDispatch stopMocking];
}

#pragma mark - setPushTokenAsString: / setPushToken: — behavior

- (void)test_setPushTokenAsString_withValidToken_queuesDataEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    NSUInteger countBefore = self.cleverTapInstance.eventsQueue.count;
    [self.cleverTapInstance setPushTokenAsString:@"ct_apns_test_token_abc123"];
    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, countBefore,
                         @"A valid APNS token should queue a data event in eventsQueue");
    [mockDispatch stopMocking];
}

- (void)test_setPushTokenAsString_analyticsOnly_isNoOp_doesNotQueue {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
        initWithAccountId:@"CT_AnalyticsOnly_Push_NoQueue"
        accountToken:@"test_token"];
    config.analyticsOnly = YES;
    CleverTap *analyticsInstance = [CleverTap instanceWithConfig:config];

    id mockDispatch = [self synchronousDispatchMockForInstance:analyticsInstance];
    NSUInteger countBefore = analyticsInstance.eventsQueue.count;
    [analyticsInstance setPushTokenAsString:@"ct_apns_analytics_only_token"];
    XCTAssertEqual(analyticsInstance.eventsQueue.count, countBefore,
                   @"analyticsOnly instance must not queue an APNS token event");
    [mockDispatch stopMocking];
}

- (void)test_setPushToken_withNilData_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance setPushToken:nil]);
}

#pragma mark - setOffline: — flushQueue side effect

- (void)test_setOffline_YES_doesNotCallFlushQueue {
    id mockInstance = OCMPartialMock(self.cleverTapInstance);
    [[mockInstance reject] flushQueue];
    [mockInstance setOffline:YES];
    OCMVerifyAll(mockInstance);
    [mockInstance stopMocking];
    // Restore: setOffline:NO will call the real flushQueue on the un-mocked instance.
    [self.cleverTapInstance setOffline:NO];
}

- (void)test_setOffline_NO_callsFlushQueue {
    id mockInstance = OCMPartialMock(self.cleverTapInstance);
    OCMExpect([mockInstance flushQueue]);
    [mockInstance setOffline:NO];
    OCMVerifyAll(mockInstance);
    [mockInstance stopMocking];
}

#pragma mark - handleNotificationWithData: / handleNotificationWithData:openDeepLinksInForeground:

- (void)test_handleNotificationWithData_withNilData_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance handleNotificationWithData:nil]);
}

- (void)test_handleNotificationWithData_withNonCTPayload_doesNotThrow {
    NSDictionary *payload = @{@"custom_key": @"someValue"};
    XCTAssertNoThrow([self.cleverTapInstance handleNotificationWithData:payload]);
}

- (void)test_handleNotificationWithData_withCTPayload_doesNotThrow {
    NSDictionary *ctPayload = @{@"wzrk_id": @"ct_handle_123",
                                @"aps": @{@"alert": @"Test"}};
    XCTAssertNoThrow([self.cleverTapInstance handleNotificationWithData:ctPayload]);
}

- (void)test_handleNotificationWithData_openDeepLinksInForeground_withNilData_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance handleNotificationWithData:nil
                                              openDeepLinksInForeground:YES]);
}

- (void)test_handleNotificationWithData_openDeepLinksInForeground_withCTPayload_doesNotThrow {
    NSDictionary *ctPayload = @{@"wzrk_id": @"ct_handle_deep_123",
                                @"aps": @{@"alert": @"Test"}};
    XCTAssertNoThrow([self.cleverTapInstance handleNotificationWithData:ctPayload
                                              openDeepLinksInForeground:NO]);
}

#pragma mark - handleOpenURL:sourceApplication: / +handleOpenURL:

- (void)test_handleOpenURL_instanceMethod_withValidURL_doesNotThrow {
    NSURL *url = [NSURL URLWithString:@"https://example.com?utm_source=email"];
    XCTAssertNoThrow([self.cleverTapInstance handleOpenURL:url sourceApplication:@"com.example.app"]);
}

- (void)test_handleOpenURL_instanceMethod_withNilURL_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance handleOpenURL:nil sourceApplication:nil]);
}

- (void)test_handleOpenURL_classMethod_withValidURL_doesNotThrow {
    NSURL *url = [NSURL URLWithString:@"https://example.com?utm_source=push"];
    XCTAssertNoThrow([CleverTap handleOpenURL:url]);
}

#pragma mark - setLocationForGeofences:withPluginVersion: / setLocation: / +setLocation:

- (void)test_setLocationForGeofences_setsUserSetLocation {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(40.7128, -74.0060);
    [self.cleverTapInstance setLocationForGeofences:coord withPluginVersion:@"1.0.0"];
    CLLocationCoordinate2D result = self.cleverTapInstance.userSetLocation;
    XCTAssertEqualWithAccuracy(result.latitude,  coord.latitude,  0.00001);
    XCTAssertEqualWithAccuracy(result.longitude, coord.longitude, 0.00001);
}

- (void)test_setLocationForGeofences_withNilVersion_doesNotThrow {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(51.5074, -0.1278);
    XCTAssertNoThrow([self.cleverTapInstance setLocationForGeofences:coord withPluginVersion:nil]);
}

- (void)test_setLocation_classMethod_doesNotThrow {
    XCTAssertNoThrow([CleverTap setLocation:CLLocationCoordinate2DMake(35.6762, 139.6503)]);
}

- (void)test_setLocation_instanceMethod_updatesUserSetLocation {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(-33.8688, 151.2093);
    [self.cleverTapInstance setLocation:coord];
    CLLocationCoordinate2D result = self.cleverTapInstance.userSetLocation;
    XCTAssertEqualWithAccuracy(result.latitude,  coord.latitude,  0.00001);
    XCTAssertEqualWithAccuracy(result.longitude, coord.longitude, 0.00001);
}

#pragma mark - recordGeofenceEnteredEvent: / recordGeofenceExitedEvent:

- (void)test_recordGeofenceEnteredEvent_withValidDetails_doesNotThrow {
    NSDictionary *details = @{@"id": @"geofence_ct_001", @"name": @"CT Test Fence"};
    XCTAssertNoThrow([self.cleverTapInstance recordGeofenceEnteredEvent:details]);
}

- (void)test_recordGeofenceExitedEvent_withValidDetails_doesNotThrow {
    NSDictionary *details = @{@"id": @"geofence_ct_001", @"name": @"CT Test Fence"};
    XCTAssertNoThrow([self.cleverTapInstance recordGeofenceExitedEvent:details]);
}

- (void)test_recordGeofenceEnteredEvent_queuesRaisedEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    NSDictionary *details = @{@"id": @"gf_entered_queue_test"};
    NSUInteger countBefore = self.cleverTapInstance.eventsQueue.count;
    [self.cleverTapInstance recordGeofenceEnteredEvent:details];
    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, countBefore,
                         @"Geofence entered event should be queued to eventsQueue as a raised event");
    [mockDispatch stopMocking];
}

- (void)test_recordGeofenceExitedEvent_queuesRaisedEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    NSDictionary *details = @{@"id": @"gf_exited_queue_test"};
    NSUInteger countBefore = self.cleverTapInstance.eventsQueue.count;
    [self.cleverTapInstance recordGeofenceExitedEvent:details];
    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, countBefore,
                         @"Geofence exited event should be queued to eventsQueue as a raised event");
    [mockDispatch stopMocking];
}

#pragma mark - didFailToRegisterForGeofencesWithError:

- (void)test_didFailToRegisterForGeofences_withError_doesNotThrow {
    NSError *error = [NSError errorWithDomain:@"CTTestErrorDomain"
                                         code:42
                                     userInfo:@{NSLocalizedDescriptionKey: @"Geofence registration failed"}];
    XCTAssertNoThrow([self.cleverTapInstance didFailToRegisterForGeofencesWithError:error]);
}

- (void)test_didFailToRegisterForGeofences_withNilError_doesNotThrow {
    // Passing nil: error.code = 0, error.localizedDescription = nil — both are safe in Obj-C.
    XCTAssertNoThrow([self.cleverTapInstance didFailToRegisterForGeofencesWithError:nil]);
}

#pragma mark - getFeatureFlag:withDefaultValue:

- (void)test_getFeatureFlag_whenControllerNotInitialized_returnsDefaultYES {
    // analyticsOnly = YES means featureFlagsController is not initialized.
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
        initWithAccountId:@"CT_FF_DefaultYES" accountToken:@"test_token"];
    config.analyticsOnly = YES;
    CleverTap *instance = [CleverTap instanceWithConfig:config];
    BOOL result = [instance getFeatureFlag:@"CT_TestFlagYES" withDefaultValue:YES];
    XCTAssertTrue(result, @"Should return the default value YES when FF controller is not initialized");
}

- (void)test_getFeatureFlag_whenControllerNotInitialized_returnsDefaultNO {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
        initWithAccountId:@"CT_FF_DefaultNO" accountToken:@"test_token"];
    config.analyticsOnly = YES;
    CleverTap *instance = [CleverTap instanceWithConfig:config];
    BOOL result = [instance getFeatureFlag:@"CT_TestFlagNO" withDefaultValue:NO];
    XCTAssertFalse(result, @"Should return the default value NO when FF controller is not initialized");
}

#pragma mark - getDomainString / signedCallDomain / setDomainDelegate:

- (void)test_getDomainString_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance getDomainString]);
}

- (void)test_signedCallDomain_propertyAccessDoesNotThrow {
    XCTAssertNoThrow((void)self.cleverTapInstance.signedCallDomain);
}

- (void)test_signedCallDomain_setterDoesNotThrow {
    NSString *saved = self.cleverTapInstance.signedCallDomain;
    XCTAssertNoThrow(self.cleverTapInstance.signedCallDomain = @"ct-sc.example.com");
    self.cleverTapInstance.signedCallDomain = saved; // restore
}

- (void)test_setDomainDelegate_withConformingDelegate_doesNotThrow {
    id mockDelegate = OCMProtocolMock(@protocol(CleverTapDomainDelegate));
    XCTAssertNoThrow([self.cleverTapInstance setDomainDelegate:mockDelegate]);
    // restore to nil so delegate isn't retained across tests
    [self.cleverTapInstance setDomainDelegate:nil];
}

- (void)test_setDomainDelegate_withNil_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance setDomainDelegate:nil]);
}

#pragma mark - enableDeviceNetworkInfoReporting: — storage persistence

- (void)test_enableDeviceNetworkInfoReporting_YES_persistsToStorage {
    [self.cleverTapInstance enableDeviceNetworkInfoReporting:YES];
    NSString *key = [CTPreferences storageKeyWithSuffix:@"NetworkInfo"
                                                 config:self.cleverTapInstance.config];
    BOOL stored = (BOOL)[CTPreferences getIntForKey:key withResetValue:NO];
    XCTAssertTrue(stored, @"Enabling network info reporting should persist YES to CTPreferences");
}

- (void)test_enableDeviceNetworkInfoReporting_NO_persistsToStorage {
    [self.cleverTapInstance enableDeviceNetworkInfoReporting:NO];
    NSString *key = [CTPreferences storageKeyWithSuffix:@"NetworkInfo"
                                                 config:self.cleverTapInstance.config];
    BOOL stored = (BOOL)[CTPreferences getIntForKey:key withResetValue:YES];
    XCTAssertFalse(stored, @"Disabling network info reporting should persist NO to CTPreferences");
}

#pragma mark - recordSignedCallEvent:forCallDetails:

- (void)test_recordSignedCallEvent_withValidDetails_doesNotThrow {
    NSDictionary *callDetails = @{@"callId": @"sc_ct_001", @"type": @"outgoing"};
    XCTAssertNoThrow([self.cleverTapInstance recordSignedCallEvent:1 forCallDetails:callDetails]);
}

- (void)test_recordSignedCallEvent_withNilDetails_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance recordSignedCallEvent:0 forCallDetails:nil]);
}

- (void)test_recordSignedCallEvent_queuesRaisedEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    NSDictionary *callDetails = @{@"callId": @"sc_queue_ct_test"};
    NSUInteger countBefore = self.cleverTapInstance.eventsQueue.count;
    [self.cleverTapInstance recordSignedCallEvent:1 forCallDetails:callDetails];
    XCTAssertGreaterThan(self.cleverTapInstance.eventsQueue.count, countBefore,
                         @"Signed call event should be queued to eventsQueue as a raised event");
    [mockDispatch stopMocking];
}

#pragma mark - profileRemoveMultiValues:forKey: — queue assertion

- (void)test_profileRemoveMultiValues_queuesProfileEvent {
    id mockDispatch = [self synchronousDispatchMockForInstance:self.cleverTapInstance];
    // Seed a value to remove so the operation is meaningful
    [self.cleverTapInstance profileSetMultiValues:@[@"tennis", @"soccer"] forKey:@"CT_RemoveMultiSports"];
    NSUInteger countBefore = self.cleverTapInstance.profileQueue.count;
    [self.cleverTapInstance profileRemoveMultiValues:@[@"tennis"] forKey:@"CT_RemoveMultiSports"];
    XCTAssertGreaterThan(self.cleverTapInstance.profileQueue.count, countBefore,
                         @"profileRemoveMultiValues:forKey: should queue a profile event");
    [mockDispatch stopMocking];
}

- (void)test_profileRemoveMultiValues_withNilValues_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileRemoveMultiValues:nil forKey:@"CT_Sports"]);
}

- (void)test_profileRemoveMultiValues_withNilKey_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance profileRemoveMultiValues:@[@"soccer"] forKey:nil]);
}

#pragma mark - onUserLogin: — behavioral

- (void)test_onUserLogin_withNilProperties_doesNotThrow {
    XCTAssertNoThrow([self.cleverTapInstance onUserLogin:nil]);
}

- (void)test_onUserLogin_withValidProperties_dispatchesOnSerialQueue {
    // Verify the method delegates to the serial dispatch queue (async processing).
    id mockDispatch = OCMPartialMock(self.cleverTapInstance.dispatchQueueManager);
    OCMExpect([mockDispatch runSerialAsync:[OCMArg any]]);
    NSDictionary *props = @{@"Identity": @"ct_behavioral_login_test"};
    [self.cleverTapInstance onUserLogin:props];
    OCMVerifyAll(mockDispatch);
    [mockDispatch stopMocking];
}

@end
