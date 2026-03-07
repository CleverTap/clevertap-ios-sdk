//
//  CTDataValidatorTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDataValidator.h"
#import "CTValidationConfig.h"
#import "CTValidationResult.h"

@interface CTDataValidatorTest : XCTestCase
@property (nonatomic, strong) CTDataValidator *validator;
@end

@implementation CTDataValidatorTest

- (void)setUp {
    self.validator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
}

#pragma mark - validate:forKey:

- (void)test_validate_plainString_returnsSuccess {
    CTValidationResult *result = [self.validator validate:@"hello" forKey:@"k"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @"hello");
}

- (void)test_validate_emptyString_returnsNil {
    CTValidationResult *result = [self.validator validate:@"" forKey:@"k"];
    XCTAssertNil(result);
}

- (void)test_validate_whitespaceOnly_returnsNil {
    CTValidationResult *result = [self.validator validate:@"   " forKey:@"k"];
    XCTAssertNil(result);
}

- (void)test_validate_stringWithInvalidChars_returnsWarning {
    // valueCharsNotAllowed contains '
    CTValidationResult *result = [self.validator validate:@"it's" forKey:@"k"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqualObjects(result.cleanedData, @"its");
}

- (void)test_validate_stringExceedingMaxLength_truncatesWithWarning {
    NSString *longValue = [@"" stringByPaddingToLength:1025 withString:@"a" startingAtIndex:0];
    CTValidationResult *result = [self.validator validate:longValue forKey:@"k"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqual(((NSString *)result.cleanedData).length, 1024U);
}

#pragma mark - cleanArray:forKey: (2-arg public method)

- (void)test_cleanArray_validStrings_returnsCleanedArray {
    NSArray *input = @[@"a", @"b", @"c"];
    CTValidationResult *result = [self.validator cleanArray:input forKey:@"tags"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    NSArray *cleaned = (NSArray *)result.cleanedData;
    XCTAssertEqual(cleaned.count, 3U);
}

- (void)test_cleanArray_withNullElement_skipsNullWithWarning {
    NSNull *null = [NSNull null];
    NSArray *input = @[@"a", null, @"b"];
    CTValidationResult *result = [self.validator cleanArray:input forKey:@"tags"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    NSArray *cleaned = (NSArray *)result.cleanedData;
    XCTAssertEqual(cleaned.count, 2U);
}

- (void)test_cleanArray_exceedingMaxLength_truncatesWithWarning {
    // maxArrayLength = 100; create 101-element array
    NSMutableArray *input = [NSMutableArray array];
    for (int i = 0; i < 101; i++) {
        [input addObject:[NSString stringWithFormat:@"item%d", i]];
    }
    CTValidationResult *result = [self.validator cleanArray:input forKey:@"tags"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    NSArray *cleaned = (NSArray *)result.cleanedData;
    XCTAssertEqual(cleaned.count, 100U);
}

#pragma mark - validateEventData:

- (void)test_validateEventData_validSimpleDict_returnsSuccess {
    NSDictionary *input = @{@"name": @"Alice", @"score": @100};
    CTValidationResult *result = [self.validator validateEventData:input];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    NSDictionary *cleaned = (NSDictionary *)result.cleanedData;
    XCTAssertEqualObjects(cleaned[@"name"], @"Alice");
    XCTAssertEqualObjects(cleaned[@"score"], @100);
}

- (void)test_validateEventData_withNestedDict_cleansRecursively {
    NSDictionary *userDict = @{@"name": @"Bob"};
    NSDictionary *input = @{@"user": userDict};
    CTValidationResult *result = [self.validator validateEventData:input];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    NSDictionary *cleaned = (NSDictionary *)result.cleanedData;
    NSDictionary *user = cleaned[@"user"];
    XCTAssertEqualObjects(user[@"name"], @"Bob");
}

- (void)test_validateEventData_withArrayValue_keepsArray {
    NSArray *tags = @[@"a", @"b"];
    NSDictionary *input = @{@"tags": tags};
    CTValidationResult *result = [self.validator validateEventData:input];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    NSDictionary *cleaned = (NSDictionary *)result.cleanedData;
    NSArray *expected = @[@"a", @"b"];
    XCTAssertEqualObjects(cleaned[@"tags"], expected);
}

- (void)test_validateEventData_withEmptyArray_removesKey {
    NSArray *emptyTags = @[];
    NSDictionary *input = @{@"tags": emptyTags};
    CTValidationResult *result = [self.validator validateEventData:input];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    NSDictionary *cleaned = (NSDictionary *)result.cleanedData;
    XCTAssertNil(cleaned[@"tags"]);
}

- (void)test_validateEventData_withNSDate_convertsToDateString {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    NSDictionary *input = @{@"dob": date};
    CTValidationResult *result = [self.validator validateEventData:input];
    NSDictionary *cleaned = (NSDictionary *)result.cleanedData;
    NSString *dateStr = cleaned[@"dob"];
    XCTAssertTrue([dateStr hasPrefix:@"$D_"]);
}

- (void)test_validateEventData_keyWithInvalidChars_cleansKeyWithWarning {
    // Key contains ':' which is in keyCharsNotAllowed
    NSDictionary *input = @{@"my:key": @"value"};
    CTValidationResult *result = [self.validator validateEventData:input];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    NSDictionary *cleaned = (NSDictionary *)result.cleanedData;
    XCTAssertNil(cleaned[@"my:key"]);
    XCTAssertEqualObjects(cleaned[@"mykey"], @"value");
}

- (void)test_validateEventData_withEmptyDict_returnsEmptyCleanedDict {
    NSDictionary *input = @{};
    CTValidationResult *result = [self.validator validateEventData:input];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @{});
}

@end
