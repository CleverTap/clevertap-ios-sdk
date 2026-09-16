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

// Spaces are ignored when matching, so the un-spaced form of a restricted name
// is dropped too.
- (void)test_validateEventName_restrictedName_spacesIgnored_returnsDrop {
    CTValidationResult *result = [self.validator validateEventName:@"NotificationClicked"];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.dropReason, CTDropReasonRestrictedEventName);
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

// A dashboard entry without spaces still matches an event name that has them,
// and vice versa.
- (void)test_validateEventName_discardedName_spacesIgnored_returnsDrop {
    self.config.discardedEventNames = [NSSet setWithObject:@"addtocart"];
    CTValidationResult *result = [self.validator validateEventName:@"Add To Cart"];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.dropReason, CTDropReasonDiscardedEventName);
}

- (void)test_validateEventName_discardedNameWithSpaces_matchesUnspacedEvent_returnsDrop {
    self.config.discardedEventNames = [NSSet setWithObject:@"Add To Cart"];
    CTValidationResult *result = [self.validator validateEventName:@"addtocart"];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.dropReason, CTDropReasonDiscardedEventName);
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

- (void)test_validateEventName_repeatedCalls_doNotAccumulateWarnings {
    // Warnings must not carry over between calls on a shared validator instance.
    for (NSInteger i = 0; i < 50; i++) {
        [self.validator validateEventName:@"my.event"];
    }
    CTValidationResult *result = [self.validator validateEventName:@"my.event"];
    XCTAssertEqual(result.subResults.count, 1U);
}

- (void)test_validateEventName_truncatedName_reportsBothWarnings {
    NSString *longName = [@"" stringByPaddingToLength:1025 withString:@"a" startingAtIndex:0];
    CTValidationResult *result = [self.validator validateEventName:longName];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqual(result.subResults.count, 2U);
    XCTAssertEqual(result.errorCode, CTValidationErrorEventNameTooLong);
}

#pragma mark - Concurrency

- (void)test_validateEventName_concurrentCallsOnSharedValidator_doNotCrashOrLeakWarnings {
    const NSInteger iterations = 2000;

    XCTestExpectation *done = [self expectationWithDescription:@"concurrent validation"];
    done.expectedFulfillmentCount = 2;

    dispatch_queue_t q1 = dispatch_queue_create("test.nameValidator.1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t q2 = dispatch_queue_create("test.nameValidator.2", DISPATCH_QUEUE_SERIAL);

    dispatch_async(q1, ^{
        for (NSInteger i = 0; i < iterations; i++) {
            CTValidationResult *result = [self.validator validateEventName:@"Purchase"];
            // A clean name must never pick up warnings produced by the other queue.
            XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
        }
        [done fulfill];
    });
    dispatch_async(q2, ^{
        for (NSInteger i = 0; i < iterations; i++) {
            CTValidationResult *result = [self.validator validateEventName:@"my.event"];
            XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
            XCTAssertEqual(result.subResults.count, 1U);
        }
        [done fulfill];
    });

    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
