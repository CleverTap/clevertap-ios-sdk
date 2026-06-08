//
//  CleverTapConfigValueTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTap+ProductConfig.h"

// Expose private initializer for testing
@interface CleverTapConfigValue (Test)
- (instancetype)initWithData:(NSData *)data;
@end

@interface CleverTapConfigValueTest : XCTestCase
@end

@implementation CleverTapConfigValueTest

- (NSData *)dataForString:(NSString *)string {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - init

- (void)test_init_withNilData_stringValueIsEmpty {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:nil];
    XCTAssertEqualObjects([value stringValue], @"");
}

- (void)test_defaultInit_stringValueIsEmpty {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] init];
    XCTAssertEqualObjects([value stringValue], @"");
}

#pragma mark - stringValue

- (void)test_stringValue_returnsUTF8DecodedString {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"hello"]];
    XCTAssertEqualObjects([value stringValue], @"hello");
}

- (void)test_stringValue_emptyString_returnsEmptyString {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@""]];
    XCTAssertEqualObjects([value stringValue], @"");
}

#pragma mark - numberValue

- (void)test_numberValue_integerString_returnsDouble {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"42"]];
    XCTAssertEqualWithAccuracy([value numberValue].doubleValue, 42.0, 1e-9);
}

- (void)test_numberValue_floatString_returnsDouble {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"3.14"]];
    XCTAssertEqualWithAccuracy([value numberValue].doubleValue, 3.14, 1e-9);
}

- (void)test_numberValue_nonNumericString_returnsZero {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"abc"]];
    XCTAssertEqualWithAccuracy([value numberValue].doubleValue, 0.0, 1e-9);
}

#pragma mark - boolValue

- (void)test_boolValue_oneString_returnsYes {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"1"]];
    XCTAssertTrue([value boolValue]);
}

- (void)test_boolValue_zeroString_returnsNo {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"0"]];
    XCTAssertFalse([value boolValue]);
}

- (void)test_boolValue_trueString_returnsYes {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"true"]];
    XCTAssertTrue([value boolValue]);
}

#pragma mark - dataValue

- (void)test_dataValue_returnsOriginalData {
    NSData *data = [self dataForString:@"test"];
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:data];
    XCTAssertEqualObjects([value dataValue], data);
}

- (void)test_dataValue_nilData_returnsNil {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:nil];
    XCTAssertNil([value dataValue]);
}

#pragma mark - jsonValue

- (void)test_jsonValue_validJsonDict_returnsDictionary {
    NSData *data = [self dataForString:@"{\"key\":\"value\"}"];
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:data];
    NSDictionary *json = [value jsonValue];
    XCTAssertNotNil(json);
    XCTAssertEqualObjects(json[@"key"], @"value");
}

- (void)test_jsonValue_validJsonArray_returnsArray {
    NSData *data = [self dataForString:@"[1,2,3]"];
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:data];
    NSArray *json = [value jsonValue];
    XCTAssertNotNil(json);
    XCTAssertEqual(json.count, 3U);
}

- (void)test_jsonValue_invalidJson_returnsNil {
    NSData *data = [self dataForString:@"not-json"];
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:data];
    XCTAssertNil([value jsonValue]);
}

- (void)test_jsonValue_nilData_returnsNil {
    CleverTapConfigValue *value = [[CleverTapConfigValue alloc] initWithData:nil];
    XCTAssertNil([value jsonValue]);
}

#pragma mark - copyWithZone

- (void)test_copy_returnsEqualStringValue {
    CleverTapConfigValue *original = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"copy_test"]];
    CleverTapConfigValue *copy = [original copy];
    XCTAssertEqualObjects([copy stringValue], [original stringValue]);
}

- (void)test_copy_returnsDistinctObject {
    CleverTapConfigValue *original = [[CleverTapConfigValue alloc] initWithData:[self dataForString:@"copy_test"]];
    CleverTapConfigValue *copy = [original copy];
    XCTAssertFalse(copy == original);
}

@end
