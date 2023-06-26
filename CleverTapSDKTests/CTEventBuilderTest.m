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

@interface CTEventBuilderTest : XCTestCase

@end

@implementation CTEventBuilderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
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

- (void)test_build_withObjectForCleaningEventActionsValue_ResultEmpty {
    NSString *eventName = @"Test.Event:Name$";
    NSDictionary *eventActions = @{@" key1$": @" . : $"};

    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {

        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[@"evtName"], @"TestEventName");
        XCTAssertEqualObjects(event[@"evtData"], @{});
        XCTAssertEqual(errors.count, 1);
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

@end
