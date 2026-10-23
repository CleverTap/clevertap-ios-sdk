//
//  CTDispatchQueueManagerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDispatchQueueManager.h"
#import "CleverTapInstanceConfig.h"

@interface CTDispatchQueueManagerTest : XCTestCase
@property (nonatomic, strong) CTDispatchQueueManager *manager;
@end

@implementation CTDispatchQueueManagerTest

- (void)setUp {
    [super setUp];
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
                                       initWithAccountId:@"testAccount"
                                       accountToken:@"testToken"];
    self.manager = [[CTDispatchQueueManager alloc] initWithConfig:config];
}

- (void)tearDown {
    self.manager = nil;
    [super tearDown];
}

- (void)test_runSerialAsync_executesBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"block executed"];
    [self.manager runSerialAsync:^{
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_inSerialQueue_outsideQueue_returnsFalse {
    XCTAssertFalse([self.manager inSerialQueue]);
}

- (void)test_inSerialQueue_insideSerialBlock_returnsTrue {
    XCTestExpectation *exp = [self expectationWithDescription:@"inSerialQueue=YES"];
    __weak typeof(self) weakSelf = self;
    [self.manager runSerialAsync:^{
        if ([weakSelf.manager inSerialQueue]) {
            [exp fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_runSerialAsync_calledFromWithinQueue_executesDirectly {
    // Verifies no deadlock when runSerialAsync is called from inside the serial queue
    XCTestExpectation *outerExp = [self expectationWithDescription:@"outer block done"];
    XCTestExpectation *innerExp = [self expectationWithDescription:@"inner block done"];

    [self.manager runSerialAsync:^{
        [self.manager runSerialAsync:^{
            // If this runs directly (no async dispatch), there's no deadlock
            [innerExp fulfill];
        }];
        [outerExp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_runOnNotificationQueue_executesBlock {
    XCTestExpectation *exp = [self expectationWithDescription:@"notification queue block executed"];
    [self.manager runOnNotificationQueue:^{
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_runSerialAsync_multipleBlocks_executesAll {
    const NSInteger count = 5;
    NSMutableArray<XCTestExpectation *> *exps = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        [exps addObject:[self expectationWithDescription:
                         [NSString stringWithFormat:@"block %ld", (long)i]]];
    }
    for (NSInteger i = 0; i < count; i++) {
        NSInteger idx = i;
        [self.manager runSerialAsync:^{
            [exps[idx] fulfill];
        }];
    }
    [self waitForExpectations:exps timeout:5.0];
}

#pragma mark - Multiple instances

// Builds a manager with an account id that is easy to recognise in a queue label.
- (CTDispatchQueueManager *)managerForAccountId:(NSString *)accountId {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc]
                                       initWithAccountId:accountId
                                       accountToken:@"testToken"];
    return [[CTDispatchQueueManager alloc] initWithConfig:config];
}

- (void)test_runSerialAsync_twoManagers_eachRunsOnItsOwnQueue {
    CTDispatchQueueManager *managerA = [self managerForAccountId:@"accountA"];
    // The second manager is created after the first one.
    // The first manager must keep its own queue.
    CTDispatchQueueManager *managerB = [self managerForAccountId:@"accountB"];

    XCTestExpectation *expA = [self expectationWithDescription:@"block A ran"];
    XCTestExpectation *expB = [self expectationWithDescription:@"block B ran"];
    __block NSString *labelA = nil;
    __block NSString *labelB = nil;

    [managerA runSerialAsync:^{
        labelA = @(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        [expA fulfill];
    }];
    [managerB runSerialAsync:^{
        labelB = @(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        [expB fulfill];
    }];
    [self waitForExpectations:@[expA, expB] timeout:2.0];

    XCTAssertTrue([labelA containsString:@"accountA"],
                  @"Manager A ran on the queue of another instance: %@", labelA);
    XCTAssertTrue([labelB containsString:@"accountB"],
                  @"Manager B ran on the queue of another instance: %@", labelB);
    XCTAssertNotEqualObjects(labelA, labelB, @"Both managers used a single shared queue.");
}

- (void)test_inSerialQueue_isTrueOnlyForTheManagerThatOwnsTheQueue {
    CTDispatchQueueManager *managerA = [self managerForAccountId:@"accountA"];
    CTDispatchQueueManager *managerB = [self managerForAccountId:@"accountB"];

    XCTestExpectation *exp = [self expectationWithDescription:@"block A ran"];
    __block BOOL ownerSaysYes = NO;
    __block BOOL otherSaysYes = NO;

    [managerA runSerialAsync:^{
        ownerSaysYes = [managerA inSerialQueue];
        otherSaysYes = [managerB inSerialQueue];
        [exp fulfill];
    }];
    [self waitForExpectations:@[exp] timeout:2.0];

    XCTAssertTrue(ownerSaysYes, @"Manager A did not recognise its own queue.");
    XCTAssertFalse(otherSaysYes, @"Manager B claimed the queue of manager A.");
}

- (void)test_runSerialAsync_executesInOrder {
    NSMutableArray<NSNumber *> *order = [NSMutableArray array];
    XCTestExpectation *exp = [self expectationWithDescription:@"all blocks done"];

    [self.manager runSerialAsync:^{ [order addObject:@1]; }];
    [self.manager runSerialAsync:^{ [order addObject:@2]; }];
    [self.manager runSerialAsync:^{
        [order addObject:@3];
        [exp fulfill];
    }];

    [self waitForExpectations:@[exp] timeout:2.0];
    XCTAssertEqualObjects(order, (@[@1, @2, @3]));
}

@end
