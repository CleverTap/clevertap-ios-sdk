//
//  CTFeatureFlagsControllerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTFeatureFlagsController.h"
#import "CleverTapInstanceConfig.h"

@interface CTFeatureFlagsDelegateSpy : NSObject <CTFeatureFlagsDelegate>
@property (nonatomic, assign) NSUInteger updateCallCount;
@end

@implementation CTFeatureFlagsDelegateSpy
- (void)featureFlagsDidUpdate {
    self.updateCallCount++;
}
@end

@interface CTFeatureFlagsControllerTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFeatureFlagsDelegateSpy *delegate;
@property (nonatomic, strong) CTFeatureFlagsController *controller;
@end

@implementation CTFeatureFlagsControllerTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"ffControllerTestAcct"
                                                        accountToken:@"testToken"];
    self.delegate = [[CTFeatureFlagsDelegateSpy alloc] init];
    self.controller = [[CTFeatureFlagsController alloc] initWithConfig:self.config
                                                                  guid:@"testGuid"
                                                              delegate:self.delegate];
}

- (void)tearDown {
    self.controller = nil;
    self.delegate = nil;
    self.config = nil;
    [super tearDown];
}

#pragma mark - init

- (void)test_init_isInitializedIsYes {
    XCTAssertTrue(self.controller.isInitialized);
}

#pragma mark - get:withDefaultValue: — empty store

- (void)test_get_unknownKey_returnsDefaultValueYes {
    BOOL result = [self.controller get:@"unknown" withDefaultValue:YES];
    XCTAssertTrue(result);
}

- (void)test_get_unknownKey_returnsDefaultValueNo {
    BOOL result = [self.controller get:@"unknown" withDefaultValue:NO];
    XCTAssertFalse(result);
}

#pragma mark - updateFeatureFlags: then get:

- (void)test_updateFeatureFlags_storesTrueFlag {
    NSArray *flags = @[@{@"n": @"dark_mode", @"v": @YES}];
    [self.controller updateFeatureFlags:flags];
    XCTAssertTrue([self.controller get:@"dark_mode" withDefaultValue:NO]);
}

- (void)test_updateFeatureFlags_storesFalseFlag {
    NSArray *flags = @[@{@"n": @"beta_feature", @"v": @NO}];
    [self.controller updateFeatureFlags:flags];
    XCTAssertFalse([self.controller get:@"beta_feature" withDefaultValue:YES]);
}

- (void)test_updateFeatureFlags_storesMultipleFlags {
    NSArray *flags = @[
        @{@"n": @"flag_a", @"v": @YES},
        @{@"n": @"flag_b", @"v": @NO}
    ];
    [self.controller updateFeatureFlags:flags];
    XCTAssertTrue([self.controller get:@"flag_a" withDefaultValue:NO]);
    XCTAssertFalse([self.controller get:@"flag_b" withDefaultValue:YES]);
}

- (void)test_updateFeatureFlags_overwritesPreviousValue {
    NSArray *first = @[@{@"n": @"toggle", @"v": @YES}];
    [self.controller updateFeatureFlags:first];
    NSArray *second = @[@{@"n": @"toggle", @"v": @NO}];
    [self.controller updateFeatureFlags:second];
    XCTAssertFalse([self.controller get:@"toggle" withDefaultValue:YES]);
}

- (void)test_updateFeatureFlags_emptyArray_clearsStore {
    NSArray *flags = @[@{@"n": @"feature", @"v": @YES}];
    [self.controller updateFeatureFlags:flags];
    [self.controller updateFeatureFlags:@[]];
    // After clearing, unknown key should fall back to default
    XCTAssertFalse([self.controller get:@"feature" withDefaultValue:NO]);
}

#pragma mark - delegate notification

- (void)test_updateFeatureFlags_notifiesDelegate {
    NSArray *flags = @[@{@"n": @"flag", @"v": @YES}];
    [self.controller updateFeatureFlags:flags];
    XCTAssertGreaterThan(self.delegate.updateCallCount, 0U);
}

@end
