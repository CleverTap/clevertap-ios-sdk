//
//  CTDelayedInAppResultTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDelayedInAppResult.h"

@interface CTDelayedInAppResultTest : XCTestCase
@end

@implementation CTDelayedInAppResultTest

- (void)test_success_setsTypeIdAndData {
    NSDictionary *data = @{@"k": @"v"};
    CTDelayedInAppResult *result = [CTDelayedInAppResult successWithId:@"id1" data:data];
    XCTAssertEqual(result.type, CTDelayedInAppResultTypeSuccess);
    XCTAssertEqualObjects(result.resultId, @"id1");
    XCTAssertEqualObjects(result.data, data);
    XCTAssertNil(result.exception);
    XCTAssertNil(result.message);
}

- (void)test_success_withNilData_setsNilData {
    CTDelayedInAppResult *result = [CTDelayedInAppResult successWithId:@"id1" data:nil];
    XCTAssertEqual(result.type, CTDelayedInAppResultTypeSuccess);
    XCTAssertNil(result.data);
}

- (void)test_error_setsTypeReasonAndException {
    NSError *error = [NSError errorWithDomain:@"TestDomain" code:42 userInfo:nil];
    CTDelayedInAppResult *result = [CTDelayedInAppResult errorWithId:@"id2"
                                                              reason:CTErrorReasonDataNotFound
                                                           exception:error];
    XCTAssertEqual(result.type, CTDelayedInAppResultTypeError);
    XCTAssertEqualObjects(result.resultId, @"id2");
    XCTAssertEqual(result.reason, CTErrorReasonDataNotFound);
    XCTAssertNotNil(result.exception);
    XCTAssertEqual(result.exception.code, 42);
}

- (void)test_error_withNilException_setsNilException {
    CTDelayedInAppResult *result = [CTDelayedInAppResult errorWithId:@"id2"
                                                              reason:CTErrorReasonUnknown
                                                           exception:nil];
    XCTAssertEqual(result.type, CTDelayedInAppResultTypeError);
    XCTAssertEqual(result.reason, CTErrorReasonUnknown);
    XCTAssertNil(result.exception);
}

- (void)test_discarded_setsTypeIdAndMessage {
    CTDelayedInAppResult *result = [CTDelayedInAppResult discardedWithId:@"id3"
                                                                 message:@"some reason"];
    XCTAssertEqual(result.type, CTDelayedInAppResultTypeDiscarded);
    XCTAssertEqualObjects(result.resultId, @"id3");
    XCTAssertEqualObjects(result.message, @"some reason");
    XCTAssertNil(result.exception);
    XCTAssertNil(result.data);
}

- (void)test_discarded_withNilMessage_setsNilMessage {
    CTDelayedInAppResult *result = [CTDelayedInAppResult discardedWithId:@"id3"
                                                                 message:nil];
    XCTAssertEqual(result.type, CTDelayedInAppResultTypeDiscarded);
    XCTAssertNil(result.message);
}

@end
