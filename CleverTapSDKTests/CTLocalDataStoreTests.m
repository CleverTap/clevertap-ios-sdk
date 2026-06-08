//
//  CTLocalDataStoreTests.m
//  CleverTapSDKTests
//
//  Created by Kushagra Mishra on 04/07/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTLocalDataStore.h"
#import "CTProfileBuilder.h"
#import "CTConstants.h"
#import "XCTestCase+XCTestCase_Tests.h"
#import "CTLocalDataStore+Tests.h"

@interface CTLocalDataStoreTests : XCTestCase
@property (nonatomic, strong) CTLocalDataStore *dataStore;
@property (nonatomic, strong) id dataStoreMock;
@property (nonatomic, strong) id profileBuilderMock;
@end

@implementation CTLocalDataStoreTests

- (void)setUp {
    [super setUp];
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken" accountRegion:@"testRegion"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"testDeviceInfo"];
    CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:config];
    self.dataStore = [[CTLocalDataStore alloc] initWithConfig:config profileValues:[NSMutableDictionary new] andDeviceInfo:deviceInfo dispatchQueueManager:queueManager];
}

- (void)tearDown {
    self.dataStore = nil;
    [super tearDown];
}

- (void)testSetAndGetProfileValueForKey {
    
    [self waitForInitDataStore];
    NSDictionary *profile = @{@"someKey": @"someValue"};
    [self.dataStore setProfileFields:profile];
    XCTAssertEqualObjects([self.dataStore getProfileFieldForKey:@"someKey"], @"someValue");
}


- (void)testSetProfileFieldWithKeyAndValue {
    [self waitForInitDataStore];
    [self.dataStore setProfileFieldWithKey:@"someKey" andValue:@"someValue"];
    XCTAssertEqualObjects([self.dataStore getProfileFieldForKey:@"someKey"], @"someValue");
}

- (void)testPersistEventAndGetEventDetail {
    NSString *eventName = [self randomString];
    NSDictionary *event = @{CLTAP_EVENT_NAME: eventName};
    XCTestExpectation *expectation = [self expectationWithDescription:@"Datastore persist event"];
    // WAIT FOR DATA STORE TO FINISH INIT
    dispatch_async(self.dataStore.backgroundQueue, ^{
        // Wait for the background queue to complete datastore setup.
        [self.dataStore persistEvent:event];
        [self.dataStore runOnBackgroundQueue:^{
            [expectation fulfill];
        }];
    });

    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Datastore initialization did not complete in time.");
        }
    }];
    
    
    CleverTapEventDetail *eventDetails = [self.dataStore readUserEventLog:eventName];
    XCTAssertEqualObjects(eventDetails.eventName, eventName);
    XCTAssertEqual(eventDetails.count, 1);
    XCTAssertGreaterThan(eventDetails.firstTime, 0);
    XCTAssertGreaterThan(eventDetails.lastTime, 0);
}

- (void)waitForInitDataStore {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Datastore initialization"];

    // WAIT FOR DATA STORE TO FINISH INIT
    dispatch_async(self.dataStore.backgroundQueue, ^{
        // Wait for the background queue to complete datastore setup.
        [self.dataStore runOnBackgroundQueue:^{
            [expectation fulfill];
        }];
    });

    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Datastore initialization did not complete in time.");
        }
    }];
}

@end
