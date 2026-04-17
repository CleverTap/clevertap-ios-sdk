//
//  CTTriggerValueTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTTriggerValue.h"

@interface CTTriggerValueTest : XCTestCase
@end

@implementation CTTriggerValueTest

- (void)test_initWithString_setsStringValue {
    CTTriggerValue *tv = [[CTTriggerValue alloc] initWithValue:@"hello"];
    XCTAssertEqualObjects(tv.value, @"hello");
    XCTAssertEqualObjects(tv.stringValue, @"hello");
    XCTAssertNil(tv.numberValue);
    XCTAssertNil(tv.arrayValue);
    XCTAssertFalse([tv isArray]);
}

- (void)test_initWithNumber_setsNumberValue {
    CTTriggerValue *tv = [[CTTriggerValue alloc] initWithValue:@42];
    XCTAssertEqualObjects(tv.value, @42);
    XCTAssertEqualObjects(tv.numberValue, @42);
    XCTAssertNil(tv.stringValue);
    XCTAssertNil(tv.arrayValue);
    XCTAssertFalse([tv isArray]);
}

- (void)test_initWithArray_setsArrayValue_isArrayYes {
    NSArray *arr = @[@1, @2, @3];
    CTTriggerValue *tv = [[CTTriggerValue alloc] initWithValue:arr];
    XCTAssertEqualObjects(tv.value, arr);
    XCTAssertEqualObjects(tv.arrayValue, arr);
    XCTAssertNil(tv.stringValue);
    XCTAssertNil(tv.numberValue);
    XCTAssertTrue([tv isArray]);
}

- (void)test_initWithUnknownType_noSpecificValueSet {
    // NSDictionary is not string/number/array — all typed properties remain nil
    CTTriggerValue *tv = [[CTTriggerValue alloc] initWithValue:@{@"key": @"val"}];
    XCTAssertNotNil(tv.value);
    XCTAssertNil(tv.stringValue);
    XCTAssertNil(tv.numberValue);
    XCTAssertNil(tv.arrayValue);
    XCTAssertFalse([tv isArray]);
}

- (void)test_isArray_false_forString {
    CTTriggerValue *tv = [[CTTriggerValue alloc] initWithValue:@"text"];
    XCTAssertFalse([tv isArray]);
}

- (void)test_isArray_false_forNumber {
    CTTriggerValue *tv = [[CTTriggerValue alloc] initWithValue:@3.14];
    XCTAssertFalse([tv isArray]);
}

@end
