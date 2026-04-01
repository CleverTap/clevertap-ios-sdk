//
//  CTSystemClockTests.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTSystemClock.h"

@interface CTSystemClockTests : XCTestCase

@property (nonatomic, strong) CTSystemClock *clock;

@end

@implementation CTSystemClockTests

- (void)setUp {
    [super setUp];
    self.clock = [[CTSystemClock alloc] init];
}

- (void)tearDown {
    self.clock = nil;
    [super tearDown];
}

- (void)test_timeIntervalSince1970_returnsNSNumber {
    NSNumber *result = [self.clock timeIntervalSince1970];
    XCTAssertNotNil(result);
    XCTAssertTrue([result isKindOfClass:[NSNumber class]]);
    XCTAssertGreaterThan([result doubleValue], 0);
}

- (void)test_timeIntervalSince1970_approximatesCurrentTime {
    NSTimeInterval before = [[NSDate date] timeIntervalSince1970];
    NSNumber *result = [self.clock timeIntervalSince1970];
    NSTimeInterval after = [[NSDate date] timeIntervalSince1970];

    XCTAssertGreaterThanOrEqual([result doubleValue], before);
    XCTAssertLessThanOrEqual([result doubleValue], after);
}

- (void)test_currentDate_returnsNSDate {
    NSDate *result = [self.clock currentDate];
    XCTAssertNotNil(result);
    XCTAssertTrue([result isKindOfClass:[NSDate class]]);
}

- (void)test_currentDate_approximatesNow {
    NSDate *before = [NSDate date];
    NSDate *result = [self.clock currentDate];
    NSDate *after = [NSDate date];

    XCTAssertLessThanOrEqual([before compare:result], NSOrderedSame);
    XCTAssertLessThanOrEqual([result compare:after], NSOrderedSame);
}

@end
