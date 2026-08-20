//
//  CTBatchSentDelegateHelperTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTBatchSentDelegateHelper.h"

@interface CTBatchSentDelegateHelperTest : XCTestCase
@end

@implementation CTBatchSentDelegateHelperTest

- (void)test_emptyBatch_returnsFalse {
    XCTAssertFalse([CTBatchSentDelegateHelper isBatchWithAppLaunched:@[]]);
}

- (void)test_batchWithoutAppLaunched_returnsFalse {
    NSArray *batch = @[
        @{@"evtName": @"Product Viewed"},
        @{@"evtName": @"Charged"}
    ];
    XCTAssertFalse([CTBatchSentDelegateHelper isBatchWithAppLaunched:batch]);
}

- (void)test_batchWithAppLaunched_returnsYes {
    NSArray *batch = @[@{@"evtName": @"App Launched"}];
    XCTAssertTrue([CTBatchSentDelegateHelper isBatchWithAppLaunched:batch]);
}

- (void)test_batchWithAppLaunchedAmongOthers_returnsYes {
    NSArray *batch = @[
        @{@"evtName": @"Product Viewed"},
        @{@"evtName": @"App Launched"},
        @{@"evtName": @"Charged"}
    ];
    XCTAssertTrue([CTBatchSentDelegateHelper isBatchWithAppLaunched:batch]);
}

- (void)test_batchWithNonEventDicts_returnsFalse {
    NSArray *batch = @[
        @{@"type": @"header"},
        @{@"someOtherKey": @"App Launched"}
    ];
    XCTAssertFalse([CTBatchSentDelegateHelper isBatchWithAppLaunched:batch]);
}

@end
