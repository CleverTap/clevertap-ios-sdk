//
//  CTEventBuilderTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 27/04/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTEventBuilder.h"
#import "CTValidator.h"
#import "CTValidationResult.h"
#import "CTInAppNotification.h"
#import "CTUtils.h"
#import "CTEventBuilder+Tests.h"
#import "CTConstants.h"

@interface CTEventBuilderTests : XCTestCase

@end

@implementation CTEventBuilderTests

#pragma mark - getErrorObject Tests

- (void)testGetErrorObject_WithValidValidationResult {
    
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    [vr setErrorCode:512];
    [vr setErrorDesc:@"Test error description"];
    
    
    NSMutableDictionary *error = [CTEventBuilder getErrorObject:vr];
    
    
    XCTAssertNotNil(error);
    XCTAssertEqual([error[@"c"] intValue], 512);
    XCTAssertEqualObjects(error[@"d"], @"Test error description");
}

- (void)testGetErrorObject_WithNilValidationResult {
    
    NSMutableDictionary *error = [CTEventBuilder getErrorObject:nil];
    
    
    XCTAssertNotNil(error);
    XCTAssertGreaterThan([error count], 0);
}

#pragma mark - Basic Event Building Tests

- (void)testBuildBasicEvent_WithValidEventName {
    
    NSString *eventName = @"TestEvent";
    id mockValidator = OCMClassMock([CTValidator class]);
    OCMStub([mockValidator isRestrictedEventName:eventName]).andReturn(NO);
    OCMStub([mockValidator isDiscaredEventName:eventName]).andReturn(NO);
    
    CTValidationResult *validResult = [[CTValidationResult alloc] init];
    [validResult setObject:eventName];
    [validResult setErrorCode:0];
    OCMStub([mockValidator cleanEventName:eventName]).andReturn(validResult);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:eventName completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], eventName);
        XCTAssertNotNil(event[CLTAP_EVENT_DATA]);
        XCTAssertEqual([errors count], 0);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mockValidator stopMocking];
}

- (void)testBuildBasicEvent_WithNilEventName {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:nil completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertEqual([errors count], 0);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildBasicEvent_WithEmptyEventName {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:@"" completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertEqual([errors count], 0);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildBasicEvent_WithRestrictedEventName {
    
    NSString *eventName = @"RestrictedEvent";
    id mockValidator = OCMClassMock([CTValidator class]);
    OCMStub([mockValidator isRestrictedEventName:eventName]).andReturn(YES);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:eventName completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertEqual([errors count], 1);
        CTValidationResult *error = errors[0];
        XCTAssertEqual([error errorCode], 512);
        XCTAssertTrue([[error errorDesc] containsString:@"Restricted event name"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mockValidator stopMocking];
}

- (void)testBuildBasicEvent_WithDiscardedEventName {
    
    NSString *eventName = @"DiscardedEvent";
    id mockValidator = OCMClassMock([CTValidator class]);
    OCMStub([mockValidator isRestrictedEventName:eventName]).andReturn(NO);
    OCMStub([mockValidator isDiscaredEventName:eventName]).andReturn(YES);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:eventName completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertEqual([errors count], 1);
        CTValidationResult *error = errors[0];
        XCTAssertEqual([error errorCode], 512);
        XCTAssertTrue([[error errorDesc] containsString:@"Discarded event name"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mockValidator stopMocking];
}

#pragma mark - Event with Actions Tests

- (void)testBuildEventWithActions_WithValidData {
    
    NSString *eventName = @"TestEvent";
    NSDictionary *eventActions = @{@"key1": @"value1", @"key2": @123};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], eventName);
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertNotNil(eventData);
        XCTAssertEqualObjects(eventData[@"key1"], @"value1");
        XCTAssertEqualObjects(eventData[@"key2"], @123);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildEventWithActions_WithInvalidPropertyKey {
    
    NSString *eventName = @"TestEvent";
    NSDictionary *eventActions = @{@"": @"value1"};
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:eventName withEventActions:eventActions completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqual([errors count], 1);
        CTValidationResult *error = errors[0];
        XCTAssertEqual([error errorCode], 512);
        XCTAssertTrue([[error errorDesc] containsString:@"Invalid event property key"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Charged Event Tests

- (void)testBuildChargedEvent_WithValidData {
    
    NSDictionary *chargeDetails = @{@"Amount": @99.99, @"Currency": @"USD"};
    NSArray *items = @[@{@"Product": @"TestProduct", @"Price": @29.99}];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_CHARGED_EVENT);
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertNotNil(eventData);
        XCTAssertEqualObjects(eventData[@"Amount"], @99.99);
        XCTAssertEqualObjects(eventData[@"Currency"], @"USD");
        NSArray *itemsArray = eventData[CLTAP_CHARGED_EVENT_ITEMS];
        XCTAssertNotNil(itemsArray);
        XCTAssertEqual([itemsArray count], 1);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildChargedEvent_WithNilChargeDetails {
    
    NSArray *items = @[@{@"Product": @"TestProduct"}];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildChargedEventWithDetails:nil andItems:items completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildChargedEvent_WithNilItems {
    
    NSDictionary *chargeDetails = @{@"Amount": @99.99};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:nil completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildChargedEvent_WithTooManyItems {
    
    NSDictionary *chargeDetails = @{@"Amount": @99.99};
    NSMutableArray *items = [NSMutableArray array];
    for (int i = 0; i < 51; i++) {
        [items addObject:@{@"Product": [NSString stringWithFormat:@"Product%d", i]}];
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqual([errors count], 1);
        CTValidationResult *error = errors[0];
        XCTAssertEqual([error errorCode], 522);
        XCTAssertTrue([[error errorDesc] containsString:@"more than 50 items"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Push Notification Event Tests

- (void)testBuildPushNotificationEvent_Clicked {
    
    NSDictionary *notification = @{
        @"ct_campaign_id": @"12345",
        @"ct_title": @"Test Title"
    };
    
    id mockUtils = OCMClassMock([CTUtils class]);
    OCMStub([mockUtils doesString:@"ct_campaign_id" startWith:CLTAP_NOTIFICATION_TAG]).andReturn(YES);
    OCMStub([mockUtils doesString:@"ct_title" startWith:CLTAP_NOTIFICATION_TAG]).andReturn(YES);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildPushNotificationEvent:YES forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_NOTIFICATION_CLICKED_EVENT_NAME);
        XCTAssertNotNil(event[CLTAP_EVENT_DATA]);
        XCTAssertNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mockUtils stopMocking];
}

- (void)testBuildPushNotificationEvent_Viewed {
    
    NSDictionary *notification = @{
        @"ct_campaign_id": @"12345"
    };
    
    id mockUtils = OCMClassMock([CTUtils class]);
    OCMStub([mockUtils doesString:@"ct_campaign_id" startWith:CLTAP_NOTIFICATION_TAG]).andReturn(YES);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildPushNotificationEvent:NO forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_NOTIFICATION_VIEWED_EVENT_NAME);
        XCTAssertNotNil(event[CLTAP_EVENT_DATA]);
        XCTAssertNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mockUtils stopMocking];
}

- (void)testBuildPushNotificationEvent_WithNilNotification {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildPushNotificationEvent:YES forNotification:nil completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Geofence Event Tests

- (void)testBuildGeofenceEvent_Entered {
    
    NSDictionary *geofenceDetails = @{
        @"geofence_id": @"geo123",
        @"latitude": @37.7749,
        @"longitude": @(-122.4194)
    };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildGeofenceStateEvent:YES forGeofenceDetails:geofenceDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_GEOFENCE_ENTERED_EVENT_NAME);
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertNotNil(eventData);
        XCTAssertEqualObjects(eventData[@"geofence_id"], @"geo123");
        XCTAssertEqualObjects(eventData[@"latitude"], @37.7749);
        XCTAssertEqualObjects(eventData[@"longitude"], @(-122.4194));
        XCTAssertNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildGeofenceEvent_Exited {
    
    NSDictionary *geofenceDetails = @{@"geofence_id": @"geo123"};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildGeofenceStateEvent:NO forGeofenceDetails:geofenceDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_GEOFENCE_EXITED_EVENT_NAME);
        XCTAssertNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildGeofenceEvent_WithEmptyDetails {
    
    NSDictionary *geofenceDetails = @{};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildGeofenceStateEvent:YES forGeofenceDetails:geofenceDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_GEOFENCE_ENTERED_EVENT_NAME);
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertEqual([eventData count], 0);
        XCTAssertNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Signed Call Event Tests

- (void)testBuildSignedCallEvent_Outgoing {
    
    NSDictionary *callDetails = @{
        @"call_id": @"call123",
        @"duration": @120
    };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildSignedCallEvent:0 forCallDetails:callDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_SIGNED_CALL_OUTGOING_EVENT_NAME);
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertNotNil(eventData);
        XCTAssertEqualObjects(eventData[@"call_id"], @"call123");
        XCTAssertEqualObjects(eventData[@"duration"], @120);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildSignedCallEvent_Incoming {
    
    NSDictionary *callDetails = @{@"call_id": @"call123"};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildSignedCallEvent:1 forCallDetails:callDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_SIGNED_CALL_INCOMING_EVENT_NAME);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildSignedCallEvent_End {
    
    NSDictionary *callDetails = @{@"call_id": @"call123"};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildSignedCallEvent:2 forCallDetails:callDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event[CLTAP_EVENT_NAME], CLTAP_SIGNED_CALL_END_EVENT_NAME);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildSignedCallEvent_WithInvalidEventType {
    
    NSDictionary *callDetails = @{@"call_id": @"call123"};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildSignedCallEvent:99 forCallDetails:callDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertEqual([errors count], 1);
        CTValidationResult *error = errors[0];
        XCTAssertEqual([error errorCode], 525);
        XCTAssertTrue([[error errorDesc] containsString:@"did not specify event name"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildSignedCallEvent_WithEmptyCallDetails {
    
    NSDictionary *callDetails = @{};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildSignedCallEvent:0 forCallDetails:callDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNotNil(event);
        XCTAssertEqual([errors count], 1);
        CTValidationResult *error = errors[0];
        XCTAssertEqual([error errorCode], 524);
        XCTAssertTrue([[error errorDesc] containsString:@"does not have any field"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Exception Handling Tests

- (void)testBuildEvent_WithExceptionInValidation {
    
    NSString *eventName = @"TestEvent";
    id mockValidator = OCMClassMock([CTValidator class]);
    OCMStub([mockValidator isRestrictedEventName:eventName]).andReturn(NO);
    OCMStub([mockValidator isDiscaredEventName:eventName]).andReturn(NO);
    
    OCMStub([mockValidator cleanEventName:eventName]).andThrow([NSException exceptionWithName:@"TestException" reason:@"Test" userInfo:nil]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder build:eventName completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertNotNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mockValidator stopMocking];
}

- (void)testBuildChargedEvent_WithException {
    
    NSDictionary *chargeDetails = @{@"Amount": @99.99};
    NSArray *items = @[@{@"Product": @"TestProduct"}];
    
    id mockValidator = OCMClassMock([CTValidator class]);
    OCMStub([mockValidator cleanObjectKey:[OCMArg any]]).andThrow([NSException exceptionWithName:@"TestException" reason:@"Test" userInfo:nil]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called"];
    
    
    [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        
        XCTAssertNil(event);
        XCTAssertNotNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [mockValidator stopMocking];
}

@end
