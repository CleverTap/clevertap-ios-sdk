//
//  CTProfileBuilderTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTProfileBuilder.h"
#import "CTProfileOperationType.h"
#import "CTValidationConfig.h"
#import "CTValidationResult.h"
#import "CTConstants.h"

// Expose private class methods for testing
@interface CTProfileBuilder (Test)
+ (NSString *)getStringForOperation:(CTProfileOperation)operation;
@end

@interface CTProfileBuilderTest : XCTestCase
@end

@implementation CTProfileBuilderTest

+ (void)setUp {
    [CTProfileBuilder initializeWithValidationConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
}

#pragma mark - getStringForOperation:

- (void)test_getStringForOperation_add_returnsAddCommand {
    XCTAssertEqualObjects([CTProfileBuilder getStringForOperation:CTProfileOperationAdd], kCLTAP_COMMAND_ADD);
}

- (void)test_getStringForOperation_remove_returnsRemoveCommand {
    XCTAssertEqualObjects([CTProfileBuilder getStringForOperation:CTProfileOperationRemove], kCLTAP_COMMAND_REMOVE);
}

- (void)test_getStringForOperation_arrayRemove_returnsRemoveCommand {
    XCTAssertEqualObjects([CTProfileBuilder getStringForOperation:CTProfileOperationArrayRemove], kCLTAP_COMMAND_REMOVE);
}

- (void)test_getStringForOperation_set_returnsSetCommand {
    XCTAssertEqualObjects([CTProfileBuilder getStringForOperation:CTProfileOperationSet], kCLTAP_COMMAND_SET);
}

- (void)test_getStringForOperation_increment_returnsIncrementCommand {
    XCTAssertEqualObjects([CTProfileBuilder getStringForOperation:CTProfileOperationIncrement], kCLTAP_COMMAND_INCREMENT);
}

- (void)test_getStringForOperation_decrement_returnsDecrementCommand {
    XCTAssertEqualObjects([CTProfileBuilder getStringForOperation:CTProfileOperationDecrement], kCLTAP_COMMAND_DECREMENT);
}

#pragma mark - build:completionHandler:

- (void)test_build_nilProfile_completesWithNilFields {
    [CTProfileBuilder build:nil completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(systemFields);
    }];
}

- (void)test_build_emptyProfile_completesWithNilFields {
    [CTProfileBuilder build:@{} completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(systemFields);
    }];
}

- (void)test_build_withKnownField_putsInSystemFields {
    // "Email" is a known profile field → goes to systemFields
    NSDictionary *profile = @{@"Email": @"test@example.com"};
    [CTProfileBuilder build:profile completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray *errors) {
        XCTAssertEqualObjects(systemFields[@"Email"], @"test@example.com");
        XCTAssertNil(customFields[@"Email"]);
    }];
}

- (void)test_build_withCustomField_putsInCustomFields {
    NSDictionary *profile = @{@"myCustomKey": @"myValue"};
    [CTProfileBuilder build:profile completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray *errors) {
        XCTAssertEqualObjects(customFields[@"myCustomKey"], @"myValue");
        XCTAssertNil(systemFields[@"myCustomKey"]);
    }];
}

- (void)test_build_withMixedFields_separatesBothCorrectly {
    NSDictionary *profile = @{@"Email": @"test@example.com", @"myCustomKey": @"myValue"};
    [CTProfileBuilder build:profile completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray *errors) {
        XCTAssertEqualObjects(systemFields[@"Email"], @"test@example.com");
        XCTAssertEqualObjects(customFields[@"myCustomKey"], @"myValue");
    }];
}

#pragma mark - buildRemoveValueForKey:

- (void)test_buildRemoveValueForKey_validKey_returnsDeleteCommand {
    [CTProfileBuilder buildRemoveValueForKey:@"myKey" completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray *errors) {
        XCTAssertNotNil(customFields[@"myKey"]);
        XCTAssertEqualObjects(customFields[@"myKey"][kCLTAP_COMMAND_DELETE], @YES);
        XCTAssertEqual(errors.count, 0U);
    }];
}

- (void)test_buildRemoveValueForKey_emptyKey_completesWithError {
    [CTProfileBuilder buildRemoveValueForKey:@"" completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray *errors) {
        XCTAssertNil(customFields);
        XCTAssertGreaterThan(errors.count, 0U);
    }];
}

#pragma mark - buildAddMultiValue:

- (void)test_buildAddMultiValue_nilValue_completesWithError {
    [CTProfileBuilder buildAddMultiValue:nil forKey:@"tags" localDataStore:nil completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray *errors) {
        XCTAssertNil(customFields);
        XCTAssertGreaterThan(errors.count, 0U);
    }];
}

- (void)test_buildAddMultiValue_emptyValue_completesWithError {
    [CTProfileBuilder buildAddMultiValue:@"" forKey:@"tags" localDataStore:nil completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray *errors) {
        XCTAssertNil(customFields);
        XCTAssertGreaterThan(errors.count, 0U);
    }];
}

- (void)test_buildAddMultiValue_validValue_returnsAddCommand {
    [CTProfileBuilder buildAddMultiValue:@"red" forKey:@"tags" localDataStore:nil completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray *errors) {
        XCTAssertNotNil(customFields[@"tags"]);
        XCTAssertNotNil(customFields[@"tags"][kCLTAP_COMMAND_ADD]);
    }];
}

#pragma mark - buildIncrementValueBy: / buildDecrementValueBy:

- (void)test_buildIncrementValueBy_validValue_returnsIncrementDict {
    [CTProfileBuilder buildIncrementValueBy:@5 forKey:@"score" localDataStore:nil completionHandler:^(NSDictionary *operatorDict, NSArray *errors) {
        XCTAssertNotNil(operatorDict[@"score"]);
        XCTAssertEqualObjects(operatorDict[@"score"][kCLTAP_COMMAND_INCREMENT], @5);
        XCTAssertNil(errors);
    }];
}

- (void)test_buildIncrementValueBy_negativeValue_completesWithError {
    [CTProfileBuilder buildIncrementValueBy:@(-1) forKey:@"score" localDataStore:nil completionHandler:^(NSDictionary *operatorDict, NSArray *errors) {
        XCTAssertNil(operatorDict);
        XCTAssertGreaterThan(errors.count, 0U);
    }];
}

- (void)test_buildIncrementValueBy_emptyKey_completesWithError {
    [CTProfileBuilder buildIncrementValueBy:@5 forKey:@"" localDataStore:nil completionHandler:^(NSDictionary *operatorDict, NSArray *errors) {
        XCTAssertNil(operatorDict);
        XCTAssertGreaterThan(errors.count, 0U);
    }];
}

- (void)test_buildDecrementValueBy_validValue_returnsDecrementDict {
    [CTProfileBuilder buildDecrementValueBy:@3 forKey:@"score" localDataStore:nil completionHandler:^(NSDictionary *operatorDict, NSArray *errors) {
        XCTAssertNotNil(operatorDict[@"score"]);
        XCTAssertEqualObjects(operatorDict[@"score"][kCLTAP_COMMAND_DECREMENT], @3);
        XCTAssertNil(errors);
    }];
}

#pragma mark - _getUpdatedValue:forKey:withCommand:cachedValue:

- (void)test_getUpdatedValue_noCachedValue_returnsIncrementValue {
    NSNumber *result = [CTProfileBuilder _getUpdatedValue:@5 forKey:@"score" withCommand:kCLTAP_COMMAND_INCREMENT cachedValue:nil];
    XCTAssertEqualObjects(result, @5);
}

- (void)test_getUpdatedValue_intIncrement_returnsSum {
    NSNumber *cached = @(NSIntegerMax > INT_MAX ? (int)10 : 10); // int cached value
    NSNumber *result = [CTProfileBuilder _getUpdatedValue:@3 forKey:@"score" withCommand:kCLTAP_COMMAND_INCREMENT cachedValue:cached];
    XCTAssertEqual(result.intValue, 13);
}

- (void)test_getUpdatedValue_doubleDecrement_returnsDifference {
    NSNumber *cached = @(10.5);
    NSNumber *result = [CTProfileBuilder _getUpdatedValue:@(2.5) forKey:@"score" withCommand:kCLTAP_COMMAND_DECREMENT cachedValue:cached];
    XCTAssertEqualWithAccuracy(result.doubleValue, 8.0, 1e-9);
}

- (void)test_getUpdatedValue_nonNumberCached_returnsValue {
    NSNumber *result = [CTProfileBuilder _getUpdatedValue:@7 forKey:@"score" withCommand:kCLTAP_COMMAND_INCREMENT cachedValue:@"notANumber"];
    XCTAssertEqualObjects(result, @7);
}

@end
