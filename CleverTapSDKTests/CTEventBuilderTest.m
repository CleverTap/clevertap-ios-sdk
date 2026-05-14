//
//  CTEventBuilderTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 27/04/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTEventBuilder.h"
#import "CTValidator.h"
#import "CTInAppNotification.h"
#import "CleverTap+DisplayUnit.h"
#import "CTConstants.h"

@interface CTEventBuilderTest : XCTestCase
@end

@implementation CTEventBuilderTest

- (void)setUp {
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_build_withValidEventNameAndActions {
    NSString *eventName = @"test_validEvent";
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @"value2"};
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], eventName);
        XCTAssertEqualObjects(event[@"evtData"], eventActions);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_build_withEmptyEventName {
    NSString *eventName = @"";
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @"value2"};
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNil(event);
    }];
}

- (void)test_build_withNilEventName {
    NSString *eventName = nil;
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @"value2"};
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNil(event);
    }];
}

- (void)test_build_withRestrictedEventName {
    NSString *eventName = @"App Launched";
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @"value2"};
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNil(event);
        XCTAssertEqual(errors.count, 1);
    }];
}

- (void)test_build_withDiscardedEventName {
    [CTValidator setDiscardedEvents:@[@"aa",@"bb",@"cc"]];
    NSString *eventName = @"aa";
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @"value2"};
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNil(event);
        XCTAssertEqual(errors.count, 1);
    }];
}

- (void)test_build_withObjectForCleaningEventName {
    NSString *eventName = @"Test.Event:Name$";
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @"value2"};
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"TestEventName");
        XCTAssertEqualObjects(event[@"evtData"], eventActions);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_build_withObjectForCleaningEventName_ResultEmpty {
    NSString *eventName = @" . : $";
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @"value2"};

    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNil(event);
        XCTAssertEqual(errors.count, 1);
    }];
}

- (void)test_build_withObjectForCleaningEventActionsKey {
    NSString *eventName = @"TestEventName";
    NSDictionary *eventActions = @{@"key   ": @"value1"};

    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"TestEventName");
        XCTAssertEqualObjects(event[@"evtData"], @{ @"key": @"value1" });
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_build_withObjectForCleaningEventActionsKeyAndValue {
    NSString *eventName = @"TestEventName";
    NSDictionary *eventActions = @{
        @"   some key   ": @" value 1 ",
        @"another   key ": @"   val1   "
    };

    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"TestEventName");
        XCTAssertEqualObjects(event[@"evtData"], (@{
            @"some key": @"value 1",
            @"another   key": @"val1"
        }));
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_build_withObjectForCleaningEventActionsKey_ResultEmpty {
    NSString *eventName = @"Test.Event:Name$";
    NSDictionary *eventActions = @{@" . : $": @"value1"};

    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"TestEventName");
        XCTAssertEqualObjects(event[@"evtData"], @{});
        XCTAssertEqual(errors.count, 1);
    }];
}

- (void)test_build_withObjectForCleaningEventActionsValue {
    NSString *eventName = @"Test.Event:Name$";
    NSDictionary *eventActions = @{@" key1$": @" . : $"};

    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"TestEventName");
        XCTAssertEqualObjects(event[@"evtData"], @{ @"key1": @". : $" });
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildChargedEventWithDetails {
    NSDictionary *chargeDetails = @{@"charge1": @"value1", @"charge2": @"value2"};
    NSDictionary *item1 = @{@"item1": @"value1"};
    NSDictionary *item2 = @{@"item2": @"value2"};

    NSArray *items = @[item1, item2];
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Charged");
        XCTAssertEqual([event[@"evtData"] count], 3);
        XCTAssertEqual([event[@"evtData"][@"Items"] count], 2);
        
        NSString *value = event[@"evtData"][@"charge1"];

        XCTAssertEqualObjects(value, @"value1");
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildChargedEventWithDetails_withNilInput {
    NSDictionary *chargeDetails = nil;
    NSArray *items = nil;
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        
        XCTAssertNil(event);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildChargedEventWithDetails_withInvalidInputForChargeDetails {
    NSDictionary *chargeDetails = @{@" . : $": @"value1", @"charge2": @"value2"};
    NSDictionary *item1 = @{@"item1": @"value1"};
    NSDictionary *item2 = @{@"item2": @"value2"};

    NSArray *items = @[item1, item2];
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Charged");
        XCTAssertEqual([event[@"evtData"] count], 2);
        XCTAssertEqual([event[@"evtData"][@"Items"] count], 2);
        
        NSString *value = event[@"evtData"][@"charge1"];

        XCTAssertNil(value);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildChargedEventWithDetails_withInvalidInputForItems {
    NSDictionary *chargeDetails = @{@" . : $": @"value1", @"charge2": @"value2"};
    NSDictionary *item1 = @{@" . : $": @"value1"};
    NSDictionary *item2 = @{@"item2": @"value2"};

    NSArray *items = @[item1, item2];
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNil(event);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildChargedEventWithDetailsAndItems {
    NSDictionary *chargeDetails = @{@"  charge 1   ": @" value 1", @"charge2 ": @" value2"};
    NSDictionary *item1 = @{@"item 1  ": @"value    1   "};
    NSDictionary *item2 = @{@"  item2": @"value2    "};

    NSArray *items = @[item1, item2];
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Charged");
        XCTAssertEqual([event[@"evtData"] count], 3);
        XCTAssertEqualObjects(event[@"evtData"][@"Items"], (@[@{@"item 1": @"value    1"}, @{@"item2": @"value2"}]));
        
        NSString *value1 = event[@"evtData"][@"charge 1"];
        XCTAssertEqualObjects(value1, @"value 1");
        NSString *value2 = event[@"evtData"][@"charge2"];
        XCTAssertEqualObjects(value2, @"value2");
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildPushNotificationEvent_withClickedTrue {
    NSDictionary *notification = @{@"notiKey": @"notiValue"};
    
    [CTEventBuilder buildPushNotificationEvent:true forNotification:notification completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Notification Clicked");
        XCTAssertEqual([event[@"evtData"] count], 1);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildPushNotificationEvent_withNilInput {
    NSDictionary *notification = nil;
    
    [CTEventBuilder buildPushNotificationEvent:true forNotification:notification completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNil(event);
        XCTAssertNil(errors);
    }];
}

- (void)test_buildPushNotificationEvent_withClickedFalse {
    NSDictionary *notification = @{@"notiKey": @"notiValue"};
    
    [CTEventBuilder buildPushNotificationEvent:false forNotification:notification completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Notification Viewed");
        XCTAssertEqual([event[@"evtData"] count], 1);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildInAppNotificationStateEvent_withClickedTrueAndInvalidKey {
    NSDictionary *notification = @{@"notiKey": @"notiValue"};
    CTInAppNotification *inAppNotification = [[CTInAppNotification alloc] initWithJSON:notification];
    NSDictionary *queryParam = @{@"key1": @"value1"};
    
    [CTEventBuilder buildInAppNotificationStateEvent:true forNotification:inAppNotification andQueryParameters:queryParam completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Notification Clicked");
        XCTAssertEqual([event[@"evtData"] count], 1);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildInAppNotificationStateEvent_withClickedFalseAndInvalidKey {
    NSDictionary *notification = @{@"notiKey": @"notiValue"};
    CTInAppNotification *inAppNotification = [[CTInAppNotification alloc] initWithJSON:notification];
    NSDictionary *queryParam = @{@"key1": @"value1"};
    
    [CTEventBuilder buildInAppNotificationStateEvent:false forNotification:inAppNotification andQueryParameters:queryParam completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Notification Viewed");
        XCTAssertEqual([event[@"evtData"] count], 1);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildInAppNotificationStateEvent_withValidKey {
    NSDictionary *notification = @{@"wzrk_notiKey": @"notiValue"};
    CTInAppNotification *inAppNotification = [[CTInAppNotification alloc] initWithJSON:notification];
    NSDictionary *queryParam = @{@"key1": @"value1"};
    
    [CTEventBuilder buildInAppNotificationStateEvent:false forNotification:inAppNotification andQueryParameters:queryParam completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Notification Viewed");
        XCTAssertEqual([event[@"evtData"] count], 2);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildInboxMessageStateEvent_withClickedTrueAndInvalidKey {
    CleverTapInboxMessage *inboxMsg = [[CleverTapInboxMessage alloc] init];
    NSDictionary *queryParam = @{@"key1": @"value1"};
    
    [CTEventBuilder buildInboxMessageStateEvent:true forMessage:inboxMsg andQueryParameters:queryParam completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Notification Clicked");
        XCTAssertEqual([event[@"evtData"] count], 1);
        XCTAssertEqual(errors.count, 0);
    }];
}

- (void)test_buildInboxMessageStateEvent_withClickedFalseAndInvalidKey {
    CleverTapInboxMessage *inboxMsg = [[CleverTapInboxMessage alloc] init];
    NSDictionary *queryParam = @{@"key1": @"value1"};
    
    [CTEventBuilder buildInboxMessageStateEvent:false forMessage:inboxMsg andQueryParameters:queryParam completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"Notification Viewed");
        XCTAssertEqual([event[@"evtData"] count], 1);
        XCTAssertEqual(errors.count, 0);
    }];
}

#pragma mark - Display Unit element-click params merging

/// Verifies the bug fix in `buildDisplayViewStateEvent:`: the `params` argument
/// is now merged into `notif` alongside the wzrk_* fields extracted from the
/// cached unit JSON. Required for `-recordDisplayUnitElementClickedEventForID:`
/// to deliver `wzrk_element_id` and `additionalProperties` to the event.
- (void)testBuildDisplayViewStateEvent_mergesParamsAlongsideWzrkFields {
    NSDictionary *unitJson = @{
        @"wzrk_id": @"1234",
        @"wzrk_pivot": @"wzrk_default"
    };
    CleverTapDisplayUnit *displayUnit = [[CleverTapDisplayUnit alloc] initWithJSON:unitJson];
    NSDictionary *params = @{
        @"wzrk_element_id": @"button-1",
        @"action_type": @"open_url",
        @"action_url": @"https://example.com"
    };

    XCTestExpectation *exp = [self expectationWithDescription:@"build"];
    __block NSDictionary *captured = nil;
    [CTEventBuilder buildDisplayViewStateEvent:YES
                                forDisplayUnit:displayUnit
                            andQueryParameters:params
                             completionHandler:^(NSDictionary *event,
                                                 NSArray<CTValidationResult *> *errors) {
        captured = event;
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqualObjects(captured[CLTAP_EVENT_NAME], CLTAP_NOTIFICATION_CLICKED_EVENT_NAME);
    NSDictionary *evtData = captured[CLTAP_EVENT_DATA];
    // wzrk_* extraction from cached unit JSON preserved.
    XCTAssertEqualObjects(evtData[@"wzrk_id"], @"1234");
    XCTAssertEqualObjects(evtData[@"wzrk_pivot"], @"wzrk_default");
    // params merged in (the bug fix).
    XCTAssertEqualObjects(evtData[@"wzrk_element_id"], @"button-1");
    XCTAssertEqualObjects(evtData[@"action_type"], @"open_url");
    XCTAssertEqualObjects(evtData[@"action_url"], @"https://example.com");
    // Timestamp tag still set.
    XCTAssertNotNil(evtData[CLTAP_NOTIFICATION_CLICKED_TAG]);
}

/// Regression guard: the existing single-arg
/// `-recordDisplayUnitClickedEventForID:` passes `nil` for `params`.
/// The bug fix must not regress that path — only wzrk_* fields appear on the
/// event, no spurious entries leak from the new merge step.
- (void)testBuildDisplayViewStateEvent_nilParamsBehavesAsBefore {
    NSDictionary *unitJson = @{ @"wzrk_id": @"x" };
    CleverTapDisplayUnit *displayUnit = [[CleverTapDisplayUnit alloc] initWithJSON:unitJson];

    XCTestExpectation *exp = [self expectationWithDescription:@"build"];
    __block NSDictionary *captured = nil;
    [CTEventBuilder buildDisplayViewStateEvent:YES
                                forDisplayUnit:displayUnit
                            andQueryParameters:nil
                             completionHandler:^(NSDictionary *event,
                                                 NSArray<CTValidationResult *> *errors) {
        captured = event;
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    NSDictionary *evtData = captured[CLTAP_EVENT_DATA];
    XCTAssertEqualObjects(evtData[@"wzrk_id"], @"x");
    XCTAssertNil(evtData[@"wzrk_element_id"]);
}

@end
