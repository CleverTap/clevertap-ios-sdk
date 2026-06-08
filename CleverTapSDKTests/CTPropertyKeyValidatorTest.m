//
//  CTPropertyKeyValidatorTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTPropertyKeyValidator.h"
#import "CTValidationConfig.h"
#import "CTValidationResult.h"

@interface CTPropertyKeyValidatorTest : XCTestCase
@property (nonatomic, strong) CTPropertyKeyValidator *validator;
@property (nonatomic, strong) CTValidationConfig *config;
@end

@implementation CTPropertyKeyValidatorTest

- (void)setUp {
    self.config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    self.validator = [[CTPropertyKeyValidator alloc] initWithConfig:self.config];
}

#pragma mark - validateKey: nil / empty

- (void)test_validateKey_nil_returnsWarning {
    CTValidationResult *result = [self.validator validateKey:nil];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertFalse([result shouldDrop]);
}

- (void)test_validateKey_emptyString_returnsWarning {
    CTValidationResult *result = [self.validator validateKey:@""];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertFalse([result shouldDrop]);
}

- (void)test_validateKey_whitespaceOnly_returnsDrop {
    // After trimming, key becomes empty → drop
    CTValidationResult *result = [self.validator validateKey:@"   "];
    XCTAssertTrue([result shouldDrop]);
}

#pragma mark - validateKey: valid key

- (void)test_validateKey_validKey_returnsSuccess {
    CTValidationResult *result = [self.validator validateKey:@"my_key"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @"my_key");
}

- (void)test_validateKey_validKey_tripsLeadingTrailingWhitespace {
    CTValidationResult *result = [self.validator validateKey:@"  my_key  "];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @"my_key");
}

#pragma mark - validateKey: invalid characters

- (void)test_validateKey_keyWithColon_returnsWarning {
    CTValidationResult *result = [self.validator validateKey:@"my:key"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    // The colon is stripped
    XCTAssertEqualObjects(result.cleanedData, @"mykey");
}

- (void)test_validateKey_keyWithDollarSign_returnsWarning {
    CTValidationResult *result = [self.validator validateKey:@"$special"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqualObjects(result.cleanedData, @"special");
}

#pragma mark - validateKey: key too long

- (void)test_validateKey_keyExceedsMaxLength_returnsWarning {
    // maxKeyLength = 120; create a 121-char key
    NSString *longKey = [@"" stringByPaddingToLength:121 withString:@"a" startingAtIndex:0];
    CTValidationResult *result = [self.validator validateKey:longKey];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    NSString *cleaned = (NSString *)result.cleanedData;
    XCTAssertEqual(cleaned.length, 120U);
}

- (void)test_validateKey_keyAtMaxLength_returnsSuccess {
    NSString *key = [@"" stringByPaddingToLength:120 withString:@"b" startingAtIndex:0];
    CTValidationResult *result = [self.validator validateKey:key];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqual(((NSString *)result.cleanedData).length, 120U);
}

#pragma mark - validateMultiValueKey:

- (void)test_validateMultiValueKey_validKey_returnsSuccess {
    CTValidationResult *result = [self.validator validateMultiValueKey:@"custom_tag"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @"custom_tag");
}

- (void)test_validateMultiValueKey_restrictedKey_returnsDrop {
    CTValidationResult *result = [self.validator validateMultiValueKey:@"Email"];
    XCTAssertTrue([result shouldDrop]);
}

- (void)test_validateMultiValueKey_restrictedKey_caseInsensitive_returnsDrop {
    CTValidationResult *result = [self.validator validateMultiValueKey:@"email"];
    XCTAssertTrue([result shouldDrop]);
}

- (void)test_validateMultiValueKey_nilKey_returnsWarning_notDrop {
    CTValidationResult *result = [self.validator validateMultiValueKey:nil];
    // Base validateKey returns warning for nil → shouldDrop is NO
    XCTAssertFalse([result shouldDrop]);
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
}

- (void)test_validateMultiValueKey_anotherRestrictedField_returnsDrop {
    CTValidationResult *result = [self.validator validateMultiValueKey:@"Phone"];
    XCTAssertTrue([result shouldDrop]);
}

@end
