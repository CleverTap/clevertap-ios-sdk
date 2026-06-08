//
//  CTValidationResultTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTValidationResult.h"
#import "CTValidationResult+Tests.h"

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

#pragma mark - success

- (void)test_success_outcomeIsSuccess {
    CTValidationResult *result = [CTValidationResult success];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
}

- (void)test_success_errorCodeIsZero {
    CTValidationResult *result = [CTValidationResult success];
    XCTAssertEqual(result.errorCode, 0);
}

#pragma mark - successWithData:

- (void)test_successWithData_setsCleanedData {
    CTValidationResult *result = [CTValidationResult successWithData:@"cleanValue"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @"cleanValue");
}

- (void)test_successWithData_nilData_outcomeIsSuccess {
    CTValidationResult *result = [CTValidationResult successWithData:nil];
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertNil(result.cleanedData);
}

#pragma mark - warningWithCode:message:data:

- (void)test_warningWithCode_setsOutcomeAndCode {
    CTValidationResult *result = [CTValidationResult warningWithCode:520 message:@"msg" data:@"val"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqual(result.errorCode, 520);
    XCTAssertEqualObjects(result.errorDesc, @"msg");
    XCTAssertEqualObjects(result.cleanedData, @"val");
}

#pragma mark - dropWithCode:message:reason:

- (void)test_dropWithCode_setsOutcomeAndReason {
    CTValidationResult *result = [CTValidationResult dropWithCode:513 message:@"drop" reason:CTDropReasonEmptyKey];
    XCTAssertEqual(result.outcome, CTValidationOutcomeDrop);
    XCTAssertEqual(result.errorCode, 513);
    XCTAssertEqualObjects(result.errorDesc, @"drop");
    XCTAssertEqual(result.dropReason, CTDropReasonEmptyKey);
    XCTAssertNil(result.cleanedData);
}

#pragma mark - warningWithSubResults:data:

- (void)test_warningWithSubResults_setsOutcomeAndSubResults {
    CTValidationResult *sub = [CTValidationResult resultWithErrorCode:520 andMessage:@"sub warning"];
    CTValidationResult *result = [CTValidationResult warningWithSubResults:@[sub] data:@"data"];
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
    XCTAssertEqual(result.subResults.count, 1u);
    XCTAssertEqualObjects(result.cleanedData, @"data");
    XCTAssertEqual(result.errorCode, 520); // aggregated from first sub-result
}

#pragma mark - shouldDrop

- (void)test_shouldDrop_dropOutcome_returnsYES {
    CTValidationResult *result = [CTValidationResult dropWithCode:513 message:@"drop" reason:CTDropReasonEmptyKey];
    XCTAssertTrue([result shouldDrop]);
}

- (void)test_shouldDrop_warningOutcome_returnsNO {
    CTValidationResult *result = [CTValidationResult resultWithErrorCode:512 andMessage:@"warn"];
    XCTAssertFalse([result shouldDrop]);
}

- (void)test_shouldDrop_successOutcome_returnsNO {
    CTValidationResult *result = [CTValidationResult success];
    XCTAssertFalse([result shouldDrop]);
}

@end
