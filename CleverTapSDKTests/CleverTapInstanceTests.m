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
#import "CTValidator.h"

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
    OCMReject([instanceMock profilePush:[OCMArg any]]);
    [instanceMock setOptOut:NO allowSystemEvents:NO];
    OCMVerifyAll(instanceMock);
}

- (void)testOptOutYES_allowSystemEventsNO {
    // Making runSerialAsync run immediately
    self.cleverTapInstance.dispatchQueueManager = OCMClassMock([CTDispatchQueueManager class]);
    OCMStub([self.cleverTapInstance.dispatchQueueManager runSerialAsync:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^block)(void);
            [invocation getArgument:&block atIndex:2];
            block();
        });
    
    [self.cleverTapInstance setOptOut:YES allowSystemEvents:NO];
    XCTAssertTrue(self.cleverTapInstance.currentUserOptedOut);
    XCTAssertFalse(self.cleverTapInstance.currentUserOptedOutAllowSystemEvents);
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

    id validatorMock = OCMClassMock([CTValidator class]);
    OCMStub([validatorMock isRestrictedEventName:@"_system_event_name"]).andReturn(YES);

    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:123]; // any non-fetch type
    XCTAssertTrue(result, @"System event should be dropped if opted out and system events disallowed");

    [validatorMock stopMocking];
}

- (void)testShouldDropEventDoesNotDropSystemEventWhenAllowSystemEventsIsYES {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"_system_event_name"};
    self.cleverTapInstance.currentUserOptedOut = YES;
    self.cleverTapInstance.currentUserOptedOutAllowSystemEvents = YES;

    id validatorMock = OCMClassMock([CTValidator class]);
    OCMStub([validatorMock isRestrictedEventName:@"_system_event_name"]).andReturn(YES);

    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:123];
    XCTAssertFalse(result, @"System event should not be dropped if system events are allowed");

    [validatorMock stopMocking];
}

- (void)testShouldDropEventDropsCustomEventWhenOptedOut {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"custom_event"};
    self.cleverTapInstance.currentUserOptedOut = YES;
    self.cleverTapInstance.currentUserOptedOutAllowSystemEvents = NO;

    id validatorMock = OCMClassMock([CTValidator class]);
    OCMStub([validatorMock isRestrictedEventName:@"custom_event"]).andReturn(NO);

    BOOL result = [self.cleverTapInstance _shouldDropEvent:event withType:123];
    XCTAssertTrue(result, @"Custom event should be dropped if user opted out");

    [validatorMock stopMocking];
}

- (void)testShouldNotDropEventIfUserNotOptedOut {
    NSDictionary *event = @{CLTAP_EVENT_NAME: @"custom_event"};
    self.cleverTapInstance.currentUserOptedOut = NO;

    id validatorMock = OCMClassMock([CTValidator class]);
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

@end
