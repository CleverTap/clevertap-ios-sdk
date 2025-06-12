//
//  CleverTapProductConfigTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 12/06/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CleverTapInstanceConfig.h"
#import "CTPreferences.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CleverTap+ProductConfig.h"
#import "CleverTapProductConfigPrivate.h"

@interface CleverTapProductConfig (Tests)
- (BOOL)shouldThrottleWithMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval;
- (NSInteger)getMinimumFetchInterval;
- (NSInteger)timeSinceLastRequest;
@end


@interface CleverTapProductConfigTests : XCTestCase

@property (nonatomic, strong) CleverTapProductConfig *productConfig;
@property (nonatomic, strong) id mockInstanceConfig;
@property (nonatomic, strong) id mockPrivateDelegate;
@property (nonatomic, strong) id mockDelegate;
@property (nonatomic, strong) NSDate *mockCurrentDate;
@property (nonatomic, strong) id mockCTPreferences;

@end

@implementation CleverTapProductConfigTests

- (void)setUp {
    [super setUp];
    
    self.mockInstanceConfig = OCMClassMock([CleverTapInstanceConfig class]);
    self.mockPrivateDelegate = OCMProtocolMock(@protocol(CleverTapPrivateProductConfigDelegate));
    self.mockDelegate = OCMProtocolMock(@protocol(CleverTapProductConfigDelegate));
    self.mockCTPreferences = OCMClassMock([CTPreferences class]);
    self.mockCurrentDate = [NSDate dateWithTimeIntervalSince1970:1234567890];
    
    OCMStub([self.mockCTPreferences storageKeyWithSuffix:OCMOCK_ANY config:OCMOCK_ANY]).andReturn(@"test_key");
    OCMStub([self.mockCTPreferences getIntForKey:OCMOCK_ANY withResetValue:0]).andReturn(0);
    
    self.productConfig = [[CleverTapProductConfig alloc] initWithConfig:self.mockInstanceConfig
                                                         privateDelegate:self.mockPrivateDelegate];
}

- (void)tearDown {
    self.productConfig = nil;
    self.mockInstanceConfig = nil;
    self.mockPrivateDelegate = nil;
    self.mockDelegate = nil;
    self.mockCurrentDate = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInitialization {
    XCTAssertNotNil(self.productConfig);
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5); // CLTAP_DEFAULT_FETCH_CALLS
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60); // CLTAP_DEFAULT_FETCH_WINDOW_LENGTH
    XCTAssertEqual(self.productConfig.lastFetchTs, 0);
}

#pragma mark - Configuration Update Tests

- (void)testUpdateProductConfigWithOptions {
    NSDictionary *options = @{
        @"rc_n": @10,
        @"rc_w": @120
    };
    
    [self.productConfig updateProductConfigWithOptions:options];
    
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 10);
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 120);
}

- (void)testUpdateProductConfigWithInvalidOptions {
    NSDictionary *options = @{
        @"rc_n": @0,
        @"rc_w": @-10
    };
    
    [self.productConfig updateProductConfigWithOptions:options];
    
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5);
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60);
}

- (void)testUpdateProductConfigWithLastFetchTs {
    NSTimeInterval timestamp = 1234567890;
    
    [self.productConfig updateProductConfigWithLastFetchTs:timestamp];
    
    XCTAssertEqual(self.productConfig.lastFetchTs, timestamp);
}

#pragma mark - Property Setter Tests

- (void)testSetFetchConfigCallsValid {
    [self.productConfig setFetchConfigCalls:15];
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 15);
}

- (void)testSetFetchConfigCallsInvalid {
    [self.productConfig setFetchConfigCalls:0];
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5); 
    
    [self.productConfig setFetchConfigCalls:-5];
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5); 
}

- (void)testSetFetchConfigWindowLengthValid {
    [self.productConfig setFetchConfigWindowLength:180];
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 180);
}

- (void)testSetFetchConfigWindowLengthInvalid {
    [self.productConfig setFetchConfigWindowLength:0];
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60); 
    
    [self.productConfig setFetchConfigWindowLength:-30];
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60); 
}

- (void)testSetMinimumFetchConfigInterval {
    NSTimeInterval interval = 300;
    [self.productConfig setMinimumFetchConfigInterval:interval];
    XCTAssertEqual(self.productConfig.minimumFetchConfigInterval, interval);
}

- (void)testSetLastFetchTs {
    NSTimeInterval timestamp = 1234567890;
    
    // Mock the persistence call
    OCMExpect([CTPreferences putInt:timestamp forKey:OCMOCK_ANY]);
    
    [self.productConfig setLastFetchTs:timestamp];
    
    XCTAssertEqual(self.productConfig.lastFetchTs, timestamp);
    OCMVerify([CTPreferences putInt:timestamp forKey:OCMOCK_ANY]);
}

- (void)testSetDelegate {
    OCMExpect([self.mockPrivateDelegate setProductConfigDelegate:self.mockDelegate]);
    
    [self.productConfig setDelegate:self.mockDelegate];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

#pragma mark - Reset Tests

- (void)testResetProductConfigSettings {
    OCMExpect([CTPreferences removeObjectForKey:OCMOCK_ANY]);
    OCMExpect([CTPreferences getIntForKey:OCMOCK_ANY withResetValue:0]).andReturn(0);
    
    [self.productConfig resetProductConfigSettings];
    
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5);
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60);
    XCTAssertEqual(self.productConfig.lastFetchTs, 0);
    
    OCMVerify([CTPreferences removeObjectForKey:OCMOCK_ANY]);
    OCMVerify([CTPreferences getIntForKey:OCMOCK_ANY withResetValue:0]);
}

#pragma mark - Public API Tests

- (void)testFetch {
    // Set last fetch time to allow fetch (beyond minimum interval)
    // Using a time that's definitely old enough to pass throttling
    NSTimeInterval oldTimestamp = [[NSDate date] timeIntervalSince1970] - 3600; // 1 hour ago
    [self.productConfig setLastFetchTs:oldTimestamp];
    
    OCMExpect([self.mockPrivateDelegate fetchProductConfig]);
    
    [self.productConfig fetch];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testFetchWithMinimumInterval {
    // Set last fetch time to allow fetch (beyond minimum interval)
    NSTimeInterval oldTimestamp = [[NSDate date] timeIntervalSince1970] - 3600; // 1 hour ago
    [self.productConfig setLastFetchTs:oldTimestamp];
    
    OCMExpect([self.mockPrivateDelegate fetchProductConfig]);
    
    [self.productConfig fetchWithMinimumInterval:60];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testFetchWithMinimumIntervalThrottled {
    // Set last fetch time to very recent (should be throttled)
    NSTimeInterval recentTimestamp = [[NSDate date] timeIntervalSince1970] - 10; // 10 seconds ago
    [self.productConfig setLastFetchTs:recentTimestamp];
    
    // Should NOT call fetchProductConfig due to throttling
    OCMReject([self.mockPrivateDelegate fetchProductConfig]);
    
    [self.productConfig fetchWithMinimumInterval:60];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testActivate {
    OCMExpect([self.mockPrivateDelegate activateProductConfig]);
    
    [self.productConfig activate];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testFetchAndActivate {
    // Set last fetch time to allow fetch
    NSTimeInterval oldTimestamp = [[NSDate date] timeIntervalSince1970] - 3600; // 1 hour ago
    [self.productConfig setLastFetchTs:oldTimestamp];
    
    OCMExpect([self.mockPrivateDelegate fetchProductConfig]);
    OCMExpect([self.mockPrivateDelegate fetchAndActivateProductConfig]);
    
    [self.productConfig fetchAndActivate];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testReset {
    // Mock the class methods that will be called during reset
    OCMExpect([CTPreferences removeObjectForKey:OCMOCK_ANY]);
    OCMExpect([CTPreferences getIntForKey:OCMOCK_ANY withResetValue:0]).andReturn(0);
    OCMExpect([self.mockPrivateDelegate resetProductConfig]);
    
    [self.productConfig reset];
    
    OCMVerifyAll(self.mockPrivateDelegate);
    // Verify the class mock separately
    OCMVerify([CTPreferences removeObjectForKey:OCMOCK_ANY]);
    OCMVerify([CTPreferences getIntForKey:OCMOCK_ANY withResetValue:0]);
}

- (void)testSetDefaults {
    NSDictionary *defaults = @{@"key1": @"value1", @"key2": @"value2"};
    
    OCMExpect([self.mockPrivateDelegate setDefaultsProductConfig:defaults]);
    
    [self.productConfig setDefaults:defaults];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testSetDefaultsFromPlistFileName {
    NSString *fileName = @"test_config.plist";
    
    OCMExpect([self.mockPrivateDelegate setDefaultsFromPlistFileNameProductConfig:fileName]);
    
    [self.productConfig setDefaultsFromPlistFileName:fileName];
    
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testGet {
    NSString *key = @"test_key";
    CleverTapConfigValue *expectedValue = [[CleverTapConfigValue alloc] init];
    
    OCMExpect([self.mockPrivateDelegate getProductConfig:key]).andReturn(expectedValue);
    
    CleverTapConfigValue *result = [self.productConfig get:key];
    
    XCTAssertEqual(result, expectedValue);
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)testGetReturnsNilWhenDelegateDoesntRespond {
    id nonRespondingDelegate = OCMProtocolMock(@protocol(CleverTapPrivateProductConfigDelegate));
    OCMStub([nonRespondingDelegate respondsToSelector:@selector(getProductConfig:)]).andReturn(NO);
    
    CleverTapProductConfig *config = [[CleverTapProductConfig alloc] initWithConfig:self.mockInstanceConfig
                                                                    privateDelegate:nonRespondingDelegate];
    
    CleverTapConfigValue *result = [config get:@"test_key"];
    
    XCTAssertNil(result);
}

- (void)testGetLastFetchTimeStamp {
    NSTimeInterval timestamp = 1234567890;
    [self.productConfig setLastFetchTs:timestamp];
    
    NSDate *result = [self.productConfig getLastFetchTimeStamp];
    NSDate *expected = [NSDate dateWithTimeIntervalSince1970:timestamp];
    
    XCTAssertEqualWithAccuracy([result timeIntervalSince1970], [expected timeIntervalSince1970], 0.001);
}

#pragma mark - Throttling Logic Tests

- (void)testShouldThrottleWithMinimumFetchInterval {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // Test case where enough time has passed (should not throttle - returns YES to proceed)
    [self.productConfig setLastFetchTs:currentTime - 120]; // 2 minutes ago
    BOOL shouldProceed = [self.productConfig shouldThrottleWithMinimumFetchInterval:60];
    XCTAssertTrue(shouldProceed, @"Should allow fetch when enough time has passed");
    
    // Test case where not enough time has passed (should throttle - returns NO)
    [self.productConfig setLastFetchTs:currentTime - 30]; // 30 seconds ago
    shouldProceed = [self.productConfig shouldThrottleWithMinimumFetchInterval:60];
    XCTAssertFalse(shouldProceed, @"Should throttle when not enough time has passed");
}

- (void)testGetMinimumFetchInterval {
    // Set up config values
    [self.productConfig setFetchConfigCalls:5];
    [self.productConfig setFetchConfigWindowLength:60];
    [self.productConfig setMinimumFetchConfigInterval:30];
    
    NSInteger interval = [self.productConfig getMinimumFetchInterval];
    
    // Server minimum: (60/5)*60 = 720 seconds
    // SDK minimum: 30 seconds
    // Should return MAX(30, 720) = 720
    XCTAssertEqual(interval, 720);
}

- (void)testGetMinimumFetchIntervalWithHigherSDKMinimum {
    // Set up config values where SDK minimum is higher
    [self.productConfig setFetchConfigCalls:10];
    [self.productConfig setFetchConfigWindowLength:60];
    [self.productConfig setMinimumFetchConfigInterval:1000];
    
    NSInteger interval = [self.productConfig getMinimumFetchInterval];
    
    // Server minimum: (60/10)*60 = 360 seconds
    // SDK minimum: 1000 seconds
    // Should return MAX(1000, 360) = 1000
    XCTAssertEqual(interval, 1000);
}

- (void)testTimeSinceLastRequest {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 5 minutes ago
    [self.productConfig setLastFetchTs:currentTime - 300];
    
    NSInteger timeSince = [self.productConfig timeSinceLastRequest];
    
    // Allow for buffer since we use real time
    XCTAssertGreaterThanOrEqual(timeSince, 295);
    XCTAssertLessThanOrEqual(timeSince, 305);
}

- (void)testNilOptions {
    XCTAssertNoThrow([self.productConfig updateProductConfigWithOptions:nil]);
}

- (void)testEmptyOptions {
    NSDictionary *emptyOptions = @{};
    [self.productConfig updateProductConfigWithOptions:emptyOptions];
    
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5);
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60);
}

- (void)testOptionsWithNonNumericValues {
    NSDictionary *options = @{
        @"rc_n": @"invalid",
        @"rc_w": @"also_invalid"
    };
    
    [self.productConfig updateProductConfigWithOptions:options];
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5);
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60);
}

- (void)testDelegateMethodsWithNilDelegate {
    CleverTapProductConfig *configWithNilDelegate = [[CleverTapProductConfig alloc] initWithConfig:self.mockInstanceConfig
                                                                                    privateDelegate:nil];
    XCTAssertNil([configWithNilDelegate get:@"test"]);
}

@end
