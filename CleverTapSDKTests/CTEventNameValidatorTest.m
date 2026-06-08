//
//  CTEventNameValidatorTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTEventNameValidator.h"
#import "CTValidationConfig.h"
#import "CTValidationResult.h"

@interface CTEventNameValidatorTest : XCTestCase
@property (nonatomic, strong) CTEventNameValidator *validator;
@property (nonatomic, strong) CTValidationConfig *config;
@end

@implementation CTEventNameValidatorTest

- (void)setUp {
    self.config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    self.validator = [[CTEventNameValidator alloc] initWithConfig:self.config];
}

#pragma mark - nil / empty

- (void)test_validateEventName_nil_returnsDrop {
    CTValidationResult *result = [self.validator validateEventName:nil];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.dropReason, CTDropReasonNullEventName);
}

- (void)test_validateEventName_emptyString_returnsDrop {
    CTValidationResult *result = [self.validator validateEventName:@""];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.dropReason, CTDropReasonNullEventName);
}

- (void)test_validateEventName_whitespaceOnly_returnsDrop {
    // Normalization trims whitespace → becomes empty → drop
    CTValidationResult *result = [self.validator validateEventName:@"   "];
    XCTAssertTrue([result shouldDrop]);
}

#pragma mark - valid name

- (void)test_validateEventName_validName_returnsSuccess {
    CTValidationResult *result = [self.validator validateEventName:@"Purchase"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @"Purchase");
}

- (void)test_validateEventName_withLeadingTrailingWhitespace_trimsAndSucceeds {
    CTValidationResult *result = [self.validator validateEventName:@"  Purchase  "];
    XCTAssertFalse([result shouldDrop]);
    XCTAssertEqualObjects(result.cleanedData, @"Purchase");
}

#pragma mark - restricted names

- (void)test_validateEventName_restrictedName_returnsDrop {
    CTValidationResult *result = [self.validator validateEventName:@"App Launched"];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.dropReason, CTDropReasonRestrictedEventName);
}

- (void)test_validateEventName_restrictedName_caseInsensitive_returnsDrop {
    CTValidationResult *result = [self.validator validateEventName:@"app launched"];
    XCTAssertTrue([result shouldDrop]);
}

- (void)test_validateEventName_anotherRestrictedName_returnsDrop {
    CTValidationResult *result = [self.validator validateEventName:@"Notification Clicked"];
    XCTAssertTrue([result shouldDrop]);
}

#pragma mark - discarded names

- (void)test_validateEventName_discardedName_returnsDrop {
    self.config.discardedEventNames = [NSSet setWithObject:@"spam_event"];
    CTValidationResult *result = [self.validator validateEventName:@"spam_event"];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.dropReason, CTDropReasonDiscardedEventName);
}

- (void)test_validateEventName_discardedName_caseInsensitive_returnsDrop {
    self.config.discardedEventNames = [NSSet setWithObject:@"spam_event"];
    CTValidationResult *result = [self.validator validateEventName:@"SPAM_EVENT"];
    XCTAssertTrue([result shouldDrop]);
}

- (void)test_validateEventName_noDiscardedNames_customEventNotDropped {
    // discardedEventNames is nil by default
    CTValidationResult *result = [self.validator validateEventName:@"custom_event"];
    XCTAssertFalse([result shouldDrop]);
}

#pragma mark - invalid characters

- (void)test_validateEventName_withDot_removedWithWarning {
    // eventNameCharsNotAllowed includes '.'
    CTValidationResult *result = [self.validator validateEventName:@"my.event"];
    XCTAssertFalse([result shouldDrop]);
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqualObjects(result.cleanedData, @"myevent");
}

- (void)test_validateEventName_withColon_removedWithWarning {
    CTValidationResult *result = [self.validator validateEventName:@"my:event"];
    XCTAssertFalse([result shouldDrop]);
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqualObjects(result.cleanedData, @"myevent");
}

#pragma mark - max length

- (void)test_validateEventName_exceedingMaxLength_truncatesWithWarning {
    // maxEventNameLength = 1024
    NSString *longName = [@"" stringByPaddingToLength:1025 withString:@"a" startingAtIndex:0];
    CTValidationResult *result = [self.validator validateEventName:longName];
    XCTAssertFalse([result shouldDrop]);
    XCTAssertEqual(((NSString *)result.cleanedData).length, 1024U);
}

@end
