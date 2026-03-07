//
//  CTDataFlattenerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDataFlattener.h"

@interface CTDataFlattenerTest : XCTestCase
@end

@implementation CTDataFlattenerTest

- (void)test_flatten_emptyDict_returnsEmpty {
    NSDictionary *result = [CTDataFlattener flatten:@{}];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, 0u);
}

- (void)test_flatten_flatDictWithNumber_returnsFlat {
    NSDictionary *input = @{@"age": @30};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqualObjects(result[@"age"], @30);
    XCTAssertEqual(result.count, 1u);
}

- (void)test_flatten_nestedDict_usesDotNotation {
    NSDictionary *input = @{@"user": @{@"name": @"Alice"}};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqualObjects(result[@"user.name"], @"Alice");
    XCTAssertNil(result[@"user"]);
}

- (void)test_flatten_deeplyNested_usesDotNotation {
    NSDictionary *input = @{@"a": @{@"b": @{@"c": @1}}};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqualObjects(result[@"a.b.c"], @1);
    XCTAssertEqual(result.count, 1u);
}

- (void)test_flatten_nsNullValue_isSkipped {
    NSDictionary *input = @{@"k": [NSNull null]};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqual(result.count, 0u);
}

- (void)test_flatten_mixedTypes_handlesEachBranch {
    NSDictionary *input = @{
        @"num": @42,
        @"nullVal": [NSNull null],
        @"nested": @{@"x": @99}
    };
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqualObjects(result[@"num"], @42);
    XCTAssertNil(result[@"nullVal"]);
    XCTAssertEqualObjects(result[@"nested.x"], @99);
    XCTAssertNil(result[@"nested"]);
}

- (void)test_flatten_stringValue_includesInResult {
    NSDictionary *input = @{@"name": @"Alice"};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqualObjects(result[@"name"], @"Alice");
}

- (void)test_flatten_arrayValue_includesInResult {
    NSArray *tags = @[@"a", @"b"];
    NSDictionary *input = @{@"tags": tags};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertNotNil(result[@"tags"]);
    XCTAssertEqualObjects(result[@"tags"], tags);
}

@end
