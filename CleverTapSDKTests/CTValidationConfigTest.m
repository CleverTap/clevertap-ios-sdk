//
//  CTValidationConfigTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTValidationConfig.h"
#import "CTValidationResult.h"

// Expose private class methods for testing
@interface CTValidationConfig (Test)
+ (NSSet<NSString *> *)defaultRestrictedEventNames;
+ (NSSet<NSString *> *)defaultRestrictedMultiValueFields;
@end

@interface CTValidationConfigTest : XCTestCase
@end

@implementation CTValidationConfigTest

#pragma mark - defaultRestrictedEventNames

- (void)test_defaultRestrictedEventNames_containsAppLaunched {
    NSSet *names = [CTValidationConfig defaultRestrictedEventNames];
    XCTAssertTrue([names containsObject:@"App Launched"]);
}

- (void)test_defaultRestrictedEventNames_containsSystemEvents {
    NSSet *names = [CTValidationConfig defaultRestrictedEventNames];
    XCTAssertTrue([names containsObject:@"Notification Clicked"]);
    XCTAssertTrue([names containsObject:@"Notification Viewed"]);
    XCTAssertTrue([names containsObject:@"App Uninstalled"]);
}

- (void)test_defaultRestrictedEventNames_returnsSameInstance {
    NSSet *first = [CTValidationConfig defaultRestrictedEventNames];
    NSSet *second = [CTValidationConfig defaultRestrictedEventNames];
    XCTAssertTrue(first == second);
}

#pragma mark - defaultRestrictedMultiValueFields

- (void)test_defaultRestrictedMultiValueFields_containsCommonFields {
    NSSet *fields = [CTValidationConfig defaultRestrictedMultiValueFields];
    XCTAssertTrue([fields containsObject:@"Email"]);
    XCTAssertTrue([fields containsObject:@"Name"]);
    XCTAssertTrue([fields containsObject:@"Phone"]);
}

- (void)test_defaultRestrictedMultiValueFields_returnsSameInstance {
    NSSet *first = [CTValidationConfig defaultRestrictedMultiValueFields];
    NSSet *second = [CTValidationConfig defaultRestrictedMultiValueFields];
    XCTAssertTrue(first == second);
}

#pragma mark - defaultConfigWithCountryCode:

- (void)test_defaultConfig_setsMaxKeyLength120 {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    XCTAssertEqualObjects(config.maxKeyLength, @120);
}

- (void)test_defaultConfig_setsMaxValueLength1024 {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    XCTAssertEqualObjects(config.maxValueLength, @1024);
}

- (void)test_defaultConfig_setsMaxDepth3 {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    XCTAssertEqualObjects(config.maxDepth, @3);
}

- (void)test_defaultConfig_setsKeyCharsNotAllowed {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    XCTAssertNotNil(config.keyCharsNotAllowed);
}

- (void)test_defaultConfig_setsRestrictedEventNames {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    XCTAssertNotNil(config.restrictedEventNames);
    XCTAssertGreaterThan(config.restrictedEventNames.count, 0U);
}

- (void)test_defaultConfig_storesCountryCode {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:@"US"];
    XCTAssertEqualObjects(config.deviceCountryCode, @"US");
}

- (void)test_defaultConfig_nilCountryCode_storesNil {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    XCTAssertNil(config.deviceCountryCode);
}

#pragma mark - isRestrictedEventName:

- (void)test_isRestrictedEventName_withAppLaunched_returnsYes {
    XCTAssertTrue([CTValidationConfig isRestrictedEventName:@"App Launched"]);
}

- (void)test_isRestrictedEventName_withCustomEvent_returnsNo {
    XCTAssertFalse([CTValidationConfig isRestrictedEventName:@"custom_event"]);
}

- (void)test_isRestrictedEventName_withNil_returnsNo {
    XCTAssertFalse([CTValidationConfig isRestrictedEventName:nil]);
}

- (void)test_isRestrictedEventName_caseInsensitive_returnsYes {
    XCTAssertTrue([CTValidationConfig isRestrictedEventName:@"app launched"]);
}

@end
