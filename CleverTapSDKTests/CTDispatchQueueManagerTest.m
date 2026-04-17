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
