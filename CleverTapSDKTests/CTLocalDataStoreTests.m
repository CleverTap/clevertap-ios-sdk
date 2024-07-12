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

- (void)testGetUserAttributeChangePropertiesWithEmptyEvent {
    NSDictionary *event = @{};
    NSDictionary *result = [self.dataStore getUserAttributeChangeProperties:event];
    XCTAssertEqual(result.count, 0);
}

- (void)testGetUserAttributeChangePropertiesWithNoProfile {
    NSDictionary *event = @{@"someKey": @"someValue"};
    NSDictionary *result = [self.dataStore getUserAttributeChangeProperties:event];
    XCTAssertEqual(result.count, 0);
}

- (void)testGetUserAttributeChangePropertiesWithProfileUpdate {
    NSDictionary *profile = @{
        @"name": @"John",
        @"age": @"30",
        @"cc": @"1234", // Should be skipped
        @"tz": @"GMT", // Should be skipped
        @"Carrier": @"Jio" // Should be skipped
    };
    NSDictionary *event = @{CLTAP_PROFILE: profile};

    // Mock old values for the keys
    id mockOldValueForName = @"Jane";
    id mockOldValueForAge = @"25";
    
    // Stub the method to return mock old values
    CTLocalDataStore *dataStoreMock = OCMPartialMock(self.dataStore);
    id mockGetProfileFieldForKeyName = OCMStub([dataStoreMock getProfileFieldForKey:@"name"]).andReturn(mockOldValueForName);
    id mockGetProfileFieldForKeyAge = OCMStub([dataStoreMock getProfileFieldForKey:@"age"]).andReturn(mockOldValueForAge);
    
    // Call the method and get the result
    NSDictionary *result = [dataStoreMock getUserAttributeChangeProperties:event];
    
    // Verify the result dictionary
    XCTAssertEqual(result.count, 2);
    XCTAssertEqual(result[@"name"][CLTAP_KEY_OLD_VALUE], mockOldValueForName);
    XCTAssertEqual(result[@"name"][CLTAP_KEY_NEW_VALUE], @"John");
    XCTAssertEqual(result[@"age"][CLTAP_KEY_OLD_VALUE], mockOldValueForAge);
    XCTAssertEqual(result[@"age"][CLTAP_KEY_NEW_VALUE], @"30");
    
    // Ensure skipped keys are not present in the result
    XCTAssertNil(result[@"cc"]);
    XCTAssertNil(result[@"tz"]);
    XCTAssertNil(result[@"Carrier"]);
    
    // Verify the mock methods were called
    OCMVerify(mockGetProfileFieldForKeyName);
    OCMVerify(mockGetProfileFieldForKeyAge);
}

- (void)testGetUserAttributeChangePropertiesWithIncrementCommand {
    NSDictionary *profile = @{
        @"points": @{kCLTAP_COMMAND_INCREMENT: @10}
    };
    NSDictionary *event = @{CLTAP_PROFILE: profile};
    
    // Mock old and new values for the key
    id mockOldValue = @20;
    id mockNewValue = @30;
    
    // Stub the method to return mock old values and handle increment command
    CTLocalDataStore *dataStoreMock = OCMPartialMock(self.dataStore);
    id mockGetProfileFieldForKey = OCMStub([dataStoreMock getProfileFieldForKey:@"points"]).andReturn(mockOldValue);
    
    // Call the method and get the result
    NSDictionary *result = [dataStoreMock getUserAttributeChangeProperties:event];
    
    // Verify the result dictionary
    XCTAssertEqual(result.count, 1);
    XCTAssertEqual(result[@"points"][CLTAP_KEY_OLD_VALUE], mockOldValue);
    XCTAssertEqual(result[@"points"][CLTAP_KEY_NEW_VALUE], mockNewValue);
    
    // Verify the mock methods were called
    OCMVerify(mockGetProfileFieldForKey);
}

@end
