//
//  CTInActionResultTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInActionResult.h"

@interface CTInActionResultTest : XCTestCase
@end

@implementation CTInActionResultTest

- (void)test_readyToFetch_setsTypeIdAndData {
    NSDictionary *data = @{@"key": @"value"};
    CTInActionResult *result = [CTInActionResult readyToFetchWithId:@"action1" data:data];
    XCTAssertEqual(result.type, CTInActionResultTypeReadyToFetch);
    XCTAssertEqualObjects(result.inActionId, @"action1");
    XCTAssertEqualObjects(result.data, data);
    XCTAssertNil(result.message);
}

- (void)test_error_setsTypeIdAndMessage {
    CTInActionResult *result = [CTInActionResult errorWithId:@"action2" message:@"something failed"];
    XCTAssertEqual(result.type, CTInActionResultTypeError);
    XCTAssertEqualObjects(result.inActionId, @"action2");
    XCTAssertEqualObjects(result.message, @"something failed");
    XCTAssertNil(result.data);
}

- (void)test_cancelled_setsTypeIdAndMessage {
    CTInActionResult *result = [CTInActionResult cancelledWithId:@"action3" message:@"cancelled by user"];
    XCTAssertEqual(result.type, CTInActionResultTypeCancelled);
    XCTAssertEqualObjects(result.inActionId, @"action3");
    XCTAssertEqualObjects(result.message, @"cancelled by user");
    XCTAssertNil(result.data);
}

- (void)test_discarded_setsTypeIdAndMessage {
    CTInActionResult *result = [CTInActionResult discardedWithId:@"action4" message:@"discarded reason"];
    XCTAssertEqual(result.type, CTInActionResultTypeDiscarded);
    XCTAssertEqualObjects(result.inActionId, @"action4");
    XCTAssertEqualObjects(result.message, @"discarded reason");
    XCTAssertNil(result.data);
}

@end
