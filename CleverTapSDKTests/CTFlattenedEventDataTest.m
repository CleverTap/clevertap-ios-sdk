//
//  CTFlattenedEventDataTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTFlattenedEventData.h"

@interface CTFlattenedEventDataTest : XCTestCase
@end

@implementation CTFlattenedEventDataTest

#pragma mark - profileChanges factory

- (void)test_profileChanges_setsCorrectType {
    CTFlattenedEventData *event = [CTFlattenedEventData profileChanges:@{@"Name": @"Alice"}];
    XCTAssertEqual(event.type, CTFlattenedEventDataTypeProfileChanges);
}

- (void)test_profileChanges_returnsInputDictionary {
    NSDictionary *changes = @{@"Name": @"Alice", @"Age": @30};
    CTFlattenedEventData *event = [CTFlattenedEventData profileChanges:changes];
    XCTAssertEqualObjects([event profileChanges], changes);
}

- (void)test_profileChanges_eventPropertiesReturnsNil {
    CTFlattenedEventData *event = [CTFlattenedEventData profileChanges:@{@"Name": @"Alice"}];
    XCTAssertNil([event eventProperties]);
}

#pragma mark - eventProperties factory

- (void)test_eventProperties_setsCorrectType {
    CTFlattenedEventData *event = [CTFlattenedEventData eventProperties:@{@"key": @"value"}];
    XCTAssertEqual(event.type, CTFlattenedEventDataTypeEventProperties);
}

- (void)test_eventProperties_returnsInputDictionary {
    NSDictionary *props = @{@"event_key": @"event_value"};
    CTFlattenedEventData *event = [CTFlattenedEventData eventProperties:props];
    XCTAssertEqualObjects([event eventProperties], props);
}

- (void)test_eventProperties_profileChangesReturnsNil {
    CTFlattenedEventData *event = [CTFlattenedEventData eventProperties:@{@"key": @"value"}];
    XCTAssertNil([event profileChanges]);
}

#pragma mark - noData factory

- (void)test_noData_setsCorrectType {
    CTFlattenedEventData *event = [CTFlattenedEventData noData];
    XCTAssertEqual(event.type, CTFlattenedEventDataTypeNoData);
}

- (void)test_noData_returnsSingletonInstance {
    CTFlattenedEventData *first = [CTFlattenedEventData noData];
    CTFlattenedEventData *second = [CTFlattenedEventData noData];
    XCTAssertEqual(first, second);
}

#pragma mark - isNoData

- (void)test_isNoData_returnsTrueForNoData {
    XCTAssertTrue([[CTFlattenedEventData noData] isNoData]);
}

- (void)test_isNoData_returnsFalseForProfileChanges {
    CTFlattenedEventData *event = [CTFlattenedEventData profileChanges:@{}];
    XCTAssertFalse([event isNoData]);
}

- (void)test_isNoData_returnsFalseForEventProperties {
    CTFlattenedEventData *event = [CTFlattenedEventData eventProperties:@{}];
    XCTAssertFalse([event isNoData]);
}

@end
