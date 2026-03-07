//
//  CleverTapEventDetailTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTapEventDetail.h"

@interface CleverTapEventDetailTest : XCTestCase
@end

@implementation CleverTapEventDetailTest

#pragma mark - default values

- (void)test_defaultValues_countIsZero {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    XCTAssertEqual(detail.count, 0U);
}

- (void)test_defaultValues_firstTimeIsZero {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    XCTAssertEqualWithAccuracy(detail.firstTime, 0.0, 1e-9);
}

- (void)test_defaultValues_lastTimeIsZero {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    XCTAssertEqualWithAccuracy(detail.lastTime, 0.0, 1e-9);
}

- (void)test_defaultValues_eventNameIsNil {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    XCTAssertNil(detail.eventName);
}

- (void)test_defaultValues_normalizedEventNameIsNil {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    XCTAssertNil(detail.normalizedEventName);
}

- (void)test_defaultValues_deviceIDIsNil {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    XCTAssertNil(detail.deviceID);
}

#pragma mark - property assignment

- (void)test_eventName_setAndGet {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.eventName = @"Charged";
    XCTAssertEqualObjects(detail.eventName, @"Charged");
}

- (void)test_normalizedEventName_setAndGet {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.normalizedEventName = @"charged";
    XCTAssertEqualObjects(detail.normalizedEventName, @"charged");
}

- (void)test_firstTime_setAndGet {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.firstTime = 1700000000.0;
    XCTAssertEqualWithAccuracy(detail.firstTime, 1700000000.0, 1e-9);
}

- (void)test_lastTime_setAndGet {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.lastTime = 1700001234.0;
    XCTAssertEqualWithAccuracy(detail.lastTime, 1700001234.0, 1e-9);
}

- (void)test_count_setAndGet {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.count = 42;
    XCTAssertEqual(detail.count, 42U);
}

- (void)test_deviceID_setAndGet {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.deviceID = @"device-abc-123";
    XCTAssertEqualObjects(detail.deviceID, @"device-abc-123");
}

#pragma mark - description

- (void)test_description_containsEventName {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.eventName = @"Charged";
    XCTAssertTrue([detail.description containsString:@"Charged"]);
}

- (void)test_description_containsCount {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.count = 7;
    XCTAssertTrue([detail.description containsString:@"7"]);
}

- (void)test_description_containsDeviceID {
    CleverTapEventDetail *detail = [[CleverTapEventDetail alloc] init];
    detail.deviceID = @"myDevice";
    XCTAssertTrue([detail.description containsString:@"myDevice"]);
}

@end
