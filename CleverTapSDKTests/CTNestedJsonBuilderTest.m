//
//  CTNestedJsonBuilderTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTNestedJsonBuilder.h"

@interface CTNestedJsonBuilderTest : XCTestCase
@property (nonatomic, strong) CTNestedJsonBuilder *builder;
@end

@implementation CTNestedJsonBuilderTest

- (void)setUp {
    [super setUp];
    self.builder = [[CTNestedJsonBuilder alloc] init];
}

- (void)tearDown {
    self.builder = nil;
    [super tearDown];
}

#pragma mark - Simple paths

- (void)test_buildFromPath_simplePath_setsValue {
    NSDictionary *result = [self.builder buildFromPath:@"key" value:@"hello"];
    XCTAssertEqualObjects(result[@"key"], @"hello");
}

- (void)test_buildFromPath_nestedPath_buildsNestedDicts {
    NSDictionary *result = [self.builder buildFromPath:@"a.b.c" value:@42];
    NSDictionary *a = result[@"a"];
    NSDictionary *b = a[@"b"];
    XCTAssertEqualObjects(b[@"c"], @42);
}

#pragma mark - Nil value

- (void)test_buildFromPath_nilValue_setsNSNull {
    NSDictionary *result = [self.builder buildFromPath:@"key" value:nil];
    XCTAssertEqualObjects(result[@"key"], [NSNull null]);
}

#pragma mark - Array paths

- (void)test_buildFromPath_arrayIndex_buildsArray {
    NSDictionary *result = [self.builder buildFromPath:@"items[0]" value:@"first"];
    NSArray *items = result[@"items"];
    XCTAssertNotNil(items);
    XCTAssertEqual(items.count, 1u);
    XCTAssertEqualObjects(items[0], @"first");
}

- (void)test_buildFromPath_arrayThenKey_buildsNestedStructure {
    NSDictionary *result = [self.builder buildFromPath:@"items[0].name" value:@"Alice"];
    NSArray *items = result[@"items"];
    XCTAssertNotNil(items);
    NSDictionary *first = items[0];
    XCTAssertEqualObjects(first[@"name"], @"Alice");
}

- (void)test_buildFromPath_multipleArrayIndices_padsWithNSNull {
    // path "arr[2]" → arr must have 3 elements, [0] and [1] are NSNull
    NSDictionary *result = [self.builder buildFromPath:@"arr[2]" value:@"v"];
    NSArray *arr = result[@"arr"];
    XCTAssertEqual(arr.count, 3u);
    XCTAssertEqualObjects(arr[0], [NSNull null]);
    XCTAssertEqualObjects(arr[1], [NSNull null]);
    XCTAssertEqualObjects(arr[2], @"v");
}

#pragma mark - Two-level nested array+dict

- (void)test_buildFromPath_arrayWithNestedKey_buildsCorrectStructure {
    // "data[0].value" — exercises the array→dict navigation
    NSDictionary *result = [self.builder buildFromPath:@"data[0].value" value:@100];
    NSArray *data = result[@"data"];
    XCTAssertNotNil(data);
    XCTAssertEqual(data.count, 1u);
    NSDictionary *item = data[0];
    XCTAssertEqualObjects(item[@"value"], @100);
}

#pragma mark - Consecutive array indices (matrix)

- (void)test_buildFromPath_consecutiveArrayIndices_buildsMatrix {
    // "matrix[0][1]" → @{@"matrix": @[[NSNull, @99]]}
    NSDictionary *result = [self.builder buildFromPath:@"matrix[0][1]" value:@99];
    NSArray *matrix = result[@"matrix"];
    XCTAssertNotNil(matrix);
    NSArray *row = matrix[0];
    XCTAssertTrue([row isKindOfClass:[NSArray class]]);
    XCTAssertEqualObjects(row[1], @99);
}

#pragma mark - Empty path (edge case)

- (void)test_buildFromPath_emptyStringPath_setsEmptyKeyEntry {
    // An empty path → single empty-string key
    NSDictionary *result = [self.builder buildFromPath:@"" value:@1];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result[@""], @1);
}

@end
