//
//  CTProductConfigControllerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTProductConfigController.h"
#import "CleverTap+ProductConfig.h"
#import "CleverTapInstanceConfig.h"

@interface CTProductConfigDelegateSpy : NSObject <CTProductConfigDelegate>
@property (nonatomic, assign) NSUInteger fetchCallCount;
@property (nonatomic, assign) NSUInteger activateCallCount;
@property (nonatomic, assign) NSUInteger initializeCallCount;
@end

@implementation CTProductConfigDelegateSpy
- (void)productConfigDidFetch { self.fetchCallCount++; }
- (void)productConfigDidActivate { self.activateCallCount++; }
- (void)productConfigDidInitialize { self.initializeCallCount++; }
@end

@interface CTProductConfigControllerTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTProductConfigDelegateSpy *delegate;
@property (nonatomic, strong) CTProductConfigController *controller;
@end

@implementation CTProductConfigControllerTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"productConfigTestAcct"
                                                        accountToken:@"testToken"];
    self.delegate = [[CTProductConfigDelegateSpy alloc] init];
    self.controller = [[CTProductConfigController alloc] initWithConfig:self.config
                                                                   guid:@"testGuid"
                                                              delegate:self.delegate];
}

- (void)tearDown {
    [self.controller reset];
    self.controller = nil;
    self.delegate = nil;
    self.config = nil;
    [super tearDown];
}

#pragma mark - init

- (void)test_init_isInitializedIsYes {
    XCTAssertTrue(self.controller.isInitialized);
}

- (void)test_init_notifiesDelegateOnInitialize {
    XCTAssertEqual(self.delegate.initializeCallCount, 1U);
}

#pragma mark - get: on empty store

- (void)test_get_unknownKey_returnsNonNilConfigValue {
    CleverTapConfigValue *value = [self.controller get:@"unknown"];
    XCTAssertNotNil(value);
}

- (void)test_get_unknownKey_returnsEmptyStringValue {
    CleverTapConfigValue *value = [self.controller get:@"unknown"];
    XCTAssertEqualObjects(value.stringValue, @"");
}

#pragma mark - setDefaults: then get:

- (void)test_setDefaults_stringValue_returnsStringConfigValue {
    [self.controller setDefaults:@{@"welcome_msg": @"Hello!"}];
    CleverTapConfigValue *value = [self.controller get:@"welcome_msg"];
    XCTAssertEqualObjects(value.stringValue, @"Hello!");
}

- (void)test_setDefaults_numberValue_returnsNumberConfigValue {
    [self.controller setDefaults:@{@"max_retries": @3}];
    CleverTapConfigValue *value = [self.controller get:@"max_retries"];
    XCTAssertEqualObjects(value.numberValue, @3);
}

- (void)test_setDefaults_callsDelegateFetch {
    NSUInteger before = self.delegate.fetchCallCount;
    [self.controller setDefaults:@{@"key": @"val"}];
    XCTAssertGreaterThan(self.delegate.fetchCallCount, before);
}

#pragma mark - updateProductConfig: + activate

- (void)test_updateProductConfig_afterActivate_storesValue {
    NSArray *config = @[@{@"n": @"theme", @"v": @"dark"}];
    [self.controller updateProductConfig:config];
    [self.controller activate];
    CleverTapConfigValue *value = [self.controller get:@"theme"];
    XCTAssertEqualObjects(value.stringValue, @"dark");
}

- (void)test_updateProductConfig_withoutActivate_doesNotExposeValue {
    NSArray *config = @[@{@"n": @"theme", @"v": @"dark"}];
    [self.controller updateProductConfig:config];
    // Not activated — active config should not have "theme"
    CleverTapConfigValue *value = [self.controller get:@"theme"];
    XCTAssertEqualObjects(value.stringValue, @"");
}

- (void)test_updateProductConfig_notifiesDelegateFetch {
    NSUInteger before = self.delegate.fetchCallCount;
    [self.controller updateProductConfig:@[@{@"n": @"k", @"v": @"v"}]];
    XCTAssertGreaterThan(self.delegate.fetchCallCount, before);
}

- (void)test_activate_notifiesDelegateActivate {
    [self.controller updateProductConfig:@[@{@"n": @"k", @"v": @"v"}]];
    NSUInteger before = self.delegate.activateCallCount;
    [self.controller activate];
    XCTAssertGreaterThan(self.delegate.activateCallCount, before);
}

#pragma mark - fetchAndActivate

- (void)test_fetchAndActivate_thenUpdateProductConfig_exposesValue {
    [self.controller fetchAndActivate];
    NSArray *config = @[@{@"n": @"flag", @"v": @"on"}];
    [self.controller updateProductConfig:config];
    CleverTapConfigValue *value = [self.controller get:@"flag"];
    XCTAssertEqualObjects(value.stringValue, @"on");
}

#pragma mark - fetchedConfig overrides defaults

- (void)test_fetchedConfigOverridesDefault_afterActivate {
    [self.controller setDefaults:@{@"theme": @"light"}];
    NSArray *config = @[@{@"n": @"theme", @"v": @"dark"}];
    [self.controller updateProductConfig:config];
    [self.controller activate];
    CleverTapConfigValue *value = [self.controller get:@"theme"];
    XCTAssertEqualObjects(value.stringValue, @"dark");
}

#pragma mark - reset

- (void)test_reset_clearsActiveConfig {
    [self.controller setDefaults:@{@"key": @"val"}];
    [self.controller reset];
    CleverTapConfigValue *value = [self.controller get:@"key"];
    XCTAssertEqualObjects(value.stringValue, @"");
}

@end
