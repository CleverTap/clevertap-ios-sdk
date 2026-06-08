//
//  CTLimitAdapterTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTLimitAdapter.h"

@interface CTLimitAdapterTest : XCTestCase
@end

@implementation CTLimitAdapterTest

#pragma mark - limitType enum mappings

- (void)test_limitType_ever {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"ever"}];
    XCTAssertEqual([a limitType], CTLimitTypeEver);
}

- (void)test_limitType_session {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"session"}];
    XCTAssertEqual([a limitType], CTLimitTypeSession);
}

- (void)test_limitType_seconds {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"seconds"}];
    XCTAssertEqual([a limitType], CTLimitTypeSeconds);
}

- (void)test_limitType_minutes {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"minutes"}];
    XCTAssertEqual([a limitType], CTLimitTypeMinutes);
}

- (void)test_limitType_hours {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"hours"}];
    XCTAssertEqual([a limitType], CTLimitTypeHours);
}

- (void)test_limitType_days {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"days"}];
    XCTAssertEqual([a limitType], CTLimitTypeDays);
}

- (void)test_limitType_weeks {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"weeks"}];
    XCTAssertEqual([a limitType], CTLimitTypeWeeks);
}

- (void)test_limitType_onEvery {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"onEvery"}];
    XCTAssertEqual([a limitType], CTLimitTypeOnEvery);
}

- (void)test_limitType_onExactly {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"onExactly"}];
    XCTAssertEqual([a limitType], CTLimitTypeOnExactly);
}

- (void)test_limitType_unknown_defaultsToEver {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"unknownType"}];
    XCTAssertEqual([a limitType], CTLimitTypeEver);
}

- (void)test_limitType_missingKey_defaultsToEver {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{}];
    XCTAssertEqual([a limitType], CTLimitTypeEver);
}

#pragma mark - limit and frequency

- (void)test_limit_returnsIntegerValue {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"ever", @"limit": @5}];
    XCTAssertEqual([a limit], 5);
}

- (void)test_limit_missingKey_returnsZero {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"ever"}];
    XCTAssertEqual([a limit], 0);
}

- (void)test_frequency_returnsIntegerValue {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"seconds", @"frequency": @30}];
    XCTAssertEqual([a frequency], 30);
}

#pragma mark - isEmpty

- (void)test_isEmpty_emptyDict_returnsYes {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{}];
    XCTAssertTrue([a isEmpty]);
}

- (void)test_isEmpty_withData_returnsNo {
    CTLimitAdapter *a = [[CTLimitAdapter alloc] initWithJSON:@{@"type": @"ever"}];
    XCTAssertFalse([a isEmpty]);
}

@end
