//
//  CleverTapProductConfigTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CleverTapProductConfigPrivate.h"
#import "CleverTapInstanceConfig.h"

@interface CleverTapProductConfigTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) id mockPrivateDelegate;
@property (nonatomic, strong) CleverTapProductConfig *productConfig;
@end

@implementation CleverTapProductConfigTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"prodConfigModelTestAcct"
                                                        accountToken:@"testToken"];
    self.mockPrivateDelegate = OCMProtocolMock(@protocol(CleverTapPrivateProductConfigDelegate));
    OCMStub([self.mockPrivateDelegate productConfigDelegate]).andReturn(nil);
    OCMStub([self.mockPrivateDelegate setProductConfigDelegate:OCMOCK_ANY]);
    self.productConfig = [[CleverTapProductConfig alloc] initWithConfig:self.config
                                                       privateDelegate:self.mockPrivateDelegate];
}

- (void)tearDown {
    [self.mockPrivateDelegate stopMocking];
    self.productConfig = nil;
    self.mockPrivateDelegate = nil;
    self.config = nil;
    [super tearDown];
}

#pragma mark - init defaults

- (void)test_init_setsDefaultFetchConfigCalls {
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5);
}

- (void)test_init_setsDefaultFetchConfigWindowLength {
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60);
}

#pragma mark - setFetchConfigCalls:

- (void)test_setFetchConfigCalls_positive_storesValue {
    self.productConfig.fetchConfigCalls = 3;
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 3);
}

- (void)test_setFetchConfigCalls_zero_usesDefault {
    self.productConfig.fetchConfigCalls = 0;
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5);
}

- (void)test_setFetchConfigCalls_negative_usesDefault {
    self.productConfig.fetchConfigCalls = -1;
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 5);
}

#pragma mark - setFetchConfigWindowLength:

- (void)test_setFetchConfigWindowLength_positive_storesValue {
    self.productConfig.fetchConfigWindowLength = 30;
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 30);
}

- (void)test_setFetchConfigWindowLength_zero_usesDefault {
    self.productConfig.fetchConfigWindowLength = 0;
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60);
}

- (void)test_setFetchConfigWindowLength_negative_usesDefault {
    self.productConfig.fetchConfigWindowLength = -5;
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 60);
}

#pragma mark - updateProductConfigWithOptions:

- (void)test_updateProductConfigWithOptions_setsFetchConfigCalls {
    [self.productConfig updateProductConfigWithOptions:@{@"rc_n": @3, @"rc_w": @30}];
    XCTAssertEqual(self.productConfig.fetchConfigCalls, 3);
}

- (void)test_updateProductConfigWithOptions_setsFetchConfigWindowLength {
    [self.productConfig updateProductConfigWithOptions:@{@"rc_n": @3, @"rc_w": @30}];
    XCTAssertEqual(self.productConfig.fetchConfigWindowLength, 30);
}

#pragma mark - lastFetchTs / getLastFetchTimeStamp

- (void)test_getLastFetchTimeStamp_returnsDateFromTs {
    self.productConfig.lastFetchTs = 1000.0;
    NSDate *date = [self.productConfig getLastFetchTimeStamp];
    XCTAssertEqualWithAccuracy(date.timeIntervalSince1970, 1000.0, 0.001);
}

#pragma mark - delegate forwarding

- (void)test_activate_callsPrivateDelegateActivate {
    OCMExpect([self.mockPrivateDelegate activateProductConfig]);
    [self.productConfig activate];
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)test_reset_callsPrivateDelegateReset {
    OCMExpect([self.mockPrivateDelegate resetProductConfig]);
    [self.productConfig reset];
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)test_setDefaults_callsPrivateDelegateSetDefaults {
    NSDictionary *defaults = @{@"key": @"value"};
    OCMExpect([self.mockPrivateDelegate setDefaultsProductConfig:defaults]);
    [self.productConfig setDefaults:defaults];
    OCMVerifyAll(self.mockPrivateDelegate);
}

- (void)test_fetch_callsPrivateDelegateFetch_whenLastFetchTsIsZero {
    // lastFetchTs = 0 => timeSinceLastRequest is very large => not throttled => delegate is called
    self.productConfig.lastFetchTs = 0;
    OCMExpect([self.mockPrivateDelegate fetchProductConfig]);
    [self.productConfig fetch];
    OCMVerifyAll(self.mockPrivateDelegate);
}

@end
