//
//  CTInAppTimerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInAppTimer.h"

@interface CTInAppTimerTest : XCTestCase
@end

@implementation CTInAppTimerTest

#pragma mark - init

- (void)test_initWithDelay_storesDelay {
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:0.05 completion:^{}];
    XCTAssertEqualWithAccuracy(timer.delay, 0.05, 1e-9);
}

- (void)test_initWithDelay_remainingTimeEqualsDelay {
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:0.05 completion:^{}];
    XCTAssertEqualWithAccuracy(timer.remainingTime, 0.05, 1e-9);
}

- (void)test_initWithDelay_isPausedIsFalse {
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:0.05 completion:^{}];
    XCTAssertFalse(timer.isPaused);
}

#pragma mark - cancel (sync)

- (void)test_cancel_clearsCompletionHandler {
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:1.0 completion:^{}];
    [timer cancel];
    XCTAssertNil(timer.completionHandler);
}

- (void)test_cancel_remainingTimeIsZero {
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:1.0 completion:^{}];
    [timer cancel];
    XCTAssertEqualWithAccuracy(timer.remainingTime, 0.0, 1e-9);
}

- (void)test_cancel_isPausedIsFalse {
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:1.0 completion:^{}];
    [timer cancel];
    XCTAssertFalse(timer.isPaused);
}

#pragma mark - start (async)

- (void)test_start_completionHandlerCalledAfterDelay {
    XCTestExpectation *exp = [self expectationWithDescription:@"completion called"];
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:0.05 completion:^{
        [exp fulfill];
    }];
    [timer start];
    [self waitForExpectations:@[exp] timeout:0.5];
}

- (void)test_cancel_beforeFiring_completionNotCalled {
    XCTestExpectation *exp = [self expectationWithDescription:@"completion not called"];
    exp.inverted = YES;
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:0.5 completion:^{
        [exp fulfill];
    }];
    [timer start];
    [timer cancel];
    [self waitForExpectations:@[exp] timeout:0.1];
}

- (void)test_startTwice_completionCalledOnce {
    XCTestExpectation *exp = [self expectationWithDescription:@"completion called once"];
    exp.expectedFulfillmentCount = 1;
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:0.05 completion:^{
        [exp fulfill];
    }];
    [timer start];
    [timer start]; // second call is a no-op (timer already exists)
    [self waitForExpectations:@[exp] timeout:0.5];
}

@end
