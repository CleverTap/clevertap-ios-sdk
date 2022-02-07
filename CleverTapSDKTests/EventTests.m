//
//  EventTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 15/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseTestCase.h"
#import <OCMock/OCMock.h>
#import "CleverTap+Tests.h"
#import "CTValidationResult.h"
#import "CTValidationResultStack.h"

@interface EventTests : BaseTestCase

@end

@implementation EventTests

- (void)setUp {
    [super setUp];
    self.responseFilePath = @"app_inbox"; // TODO just a test but we will need to figure out how to test with Core Data
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_event_recorded_with_props {
    NSString *stubName = @"Test Record Event with props";
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    
    NSString *eventName = [self randomString];
    NSDictionary *props = @{@"prop1":@1};
    [self.cleverTapInstance recordEvent:eventName withProps:props];
    
    [self getLastEventWithStubName:stubName eventName:eventName eventType:nil handler:^(NSDictionary* lastEvent) {
            XCTAssertNotNil(lastEvent);
            XCTAssertEqualObjects([lastEvent objectForKey:@"evtName"], eventName);
            XCTAssertEqualObjects([lastEvent objectForKey:@"evtData"], props);
            [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_event_recorded {
    NSString *stubName = @"Test Record Event";
    [self stubRequestsWithName: stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test Record Event"];
    
    NSString *eventName = [self randomString];
    [self.cleverTapInstance recordEvent:eventName];
    
    [self getLastEventWithStubName:stubName eventName:eventName  eventType:nil  handler:^(NSDictionary* lastEvent) {
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects([lastEvent objectForKey:@"evtName"], eventName);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_charged_event_recorded {
    NSString *stubName = @"Test Charged Record Event";
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test Charged Record Event"];
    
    NSString *eventName = @"Charged";
    NSDictionary *chargeDetails = @{
                                    @"Amount" : @300,
                                    @"Payment mode": @"Credit Card",
                                    @"Charged ID": @24052013
                                    };
    NSDictionary *item1 = @{
                            @"Category": @"books",
                            @"Book name": @"The Millionaire next door",
                            @"Quantity": @1
                            };
    NSDictionary *item2 = @{
                            @"Category": @"books",
                            @"Book name": @"Achieving inner zen",
                            @"Quantity": @1
                            };
    NSArray *items = @[item1, item2];
    [self.cleverTapInstance recordChargedEventWithDetails:chargeDetails andItems:items];
    
    [self getLastEventWithStubName:stubName eventName:eventName  eventType:nil handler:^(NSDictionary* lastEvent) {
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects([lastEvent objectForKey:@"evtName"], eventName);
        
        NSMutableDictionary *eventData = [NSMutableDictionary dictionaryWithDictionary:chargeDetails];
        eventData[@"Items"] = items;
        
        XCTAssertEqualObjects([lastEvent objectForKey:@"evtData"], eventData);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

@end
