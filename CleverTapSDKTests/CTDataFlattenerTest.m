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

- (void)test_flatten_dateStringValue_processesDatePrefix {
    // $D_ strings are processed by CTProfileOperationUtils.processDatePrefixes
    NSDictionary *input = @{@"dob": @"$D_1000"};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqualObjects(result[@"dob"], @1000LL);
}

- (void)test_flatten_arrayWithDateString_processesDatePrefixes {
    NSDictionary *input = @{@"dates": @[@"$D_2000", @"plain"]};
    NSDictionary *result = [CTDataFlattener flatten:input];
    NSArray *dates = result[@"dates"];
    XCTAssertEqualObjects(dates[0], @2000LL);
    XCTAssertEqualObjects(dates[1], @"plain");
}

- (void)test_flatten_multipleFlatKeys_returnsAll {
    NSDictionary *input = @{@"a": @1, @"b": @"two", @"c": @3.0};
    NSDictionary *result = [CTDataFlattener flatten:input];
    XCTAssertEqual(result.count, 3u);
    XCTAssertEqualObjects(result[@"a"], @1);
    XCTAssertEqualObjects(result[@"b"], @"two");
}

@end
