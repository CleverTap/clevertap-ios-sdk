//
//  CTValidationResultTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTValidationResult.h"

@interface CTValidationResultTest : XCTestCase
@end

@implementation CTValidationResultTest

#pragma mark - resultWithErrorCode:andMessage:

- (void)test_resultWithErrorCode_warningRange {
    CTValidationResult *result = [CTValidationResult resultWithErrorCode:512 andMessage:@"warning message"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqual(result.errorCode, 512);
    XCTAssertEqualObjects(result.errorDesc, @"warning message");
}

- (void)test_resultWithErrorCode_dropRange_513 {
    CTValidationResult *result = [CTValidationResult resultWithErrorCode:513 andMessage:@"drop message"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeDrop);
    XCTAssertEqual(result.errorCode, 513);
}

- (void)test_resultWithErrorCode_dropRange_514 {
    CTValidationResult *result = [CTValidationResult resultWithErrorCode:514 andMessage:@"drop message 514"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeDrop);
    XCTAssertEqual(result.errorCode, 514);
}

#pragma mark - dropWithSubResults:reason:

- (void)test_dropWithSubResults_setsOutcomeAndReason {
    CTValidationResult *sub1 = [CTValidationResult resultWithErrorCode:513 andMessage:@"sub error 1"];
    CTValidationResult *sub2 = [CTValidationResult resultWithErrorCode:514 andMessage:@"sub error 2"];
    NSArray *subResults = @[sub1, sub2];

    CTValidationResult *result = [CTValidationResult dropWithSubResults:subResults reason:CTDropReasonEmptyKey];
    XCTAssertEqual(result.outcome, CTValidationOutcomeDrop);
    XCTAssertEqual(result.subResults.count, 2u);
    XCTAssertEqual(result.dropReason, CTDropReasonEmptyKey);
    XCTAssertEqual(result.errorCode, 513); // aggregated from first sub-result
}

- (void)test_dropWithSubResults_emptyArray {
    CTValidationResult *result = [CTValidationResult dropWithSubResults:@[] reason:CTDropReasonNullEventName];
    XCTAssertEqual(result.outcome, CTValidationOutcomeDrop);
    XCTAssertEqual(result.subResults.count, 0u);
}

@end
