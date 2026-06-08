//
//  CTTimerResultTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTTimerResult.h"

@interface CTTimerResultTest : XCTestCase
@end

@implementation CTTimerResultTest

- (void)test_completed_setsTypeIdAndScheduledAt {
    CTTimerResult *result = [CTTimerResult completedWithId:@"id1" scheduledAt:42.0];
    XCTAssertEqual(result.type, CTTimerResultTypeCompleted);
    XCTAssertEqualObjects(result.resultId, @"id1");
    XCTAssertEqual(result.scheduledAt, 42.0);
    XCTAssertNil(result.exception);
}

- (void)test_error_setsTypeIdAndException {
    NSError *error = [NSError errorWithDomain:@"TestDomain" code:99 userInfo:nil];
    CTTimerResult *result = [CTTimerResult errorWithId:@"id2" exception:error];
    XCTAssertEqual(result.type, CTTimerResultTypeError);
    XCTAssertEqualObjects(result.resultId, @"id2");
    XCTAssertNotNil(result.exception);
    XCTAssertEqual(result.exception.code, 99);
}

- (void)test_error_withNilException_setsNilException {
    CTTimerResult *result = [CTTimerResult errorWithId:@"id2" exception:nil];
    XCTAssertEqual(result.type, CTTimerResultTypeError);
    XCTAssertNil(result.exception);
}

- (void)test_discarded_setsTypeAndId {
    CTTimerResult *result = [CTTimerResult discardedWithId:@"id3"];
    XCTAssertEqual(result.type, CTTimerResultTypeDiscarded);
    XCTAssertEqualObjects(result.resultId, @"id3");
    XCTAssertNil(result.exception);
    XCTAssertEqual(result.scheduledAt, 0.0);
}

@end
