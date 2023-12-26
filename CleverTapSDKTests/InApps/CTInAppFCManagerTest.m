//
//  CTInAppFCManagerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 9.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTInAppFCManager.h"
#import "CleverTapInstanceConfig.h"
#import "CTImpressionManager.h"
#import "CTInAppFCManager.h"
#import "CTInAppTriggerManager.h"
#import "InAppHelper.h"
#import "CTInAppNotification.h"
#import "CTInAppFCManager+Tests.h"
#import "CTImpressionManager+Tests.h"
#import "CTPreferences.h"

@interface CTInAppFCManagerMock : CTInAppFCManager
@property (nonatomic, assign) int globalSessionMax;
@property (nonatomic, assign) int maxPerDayCount;
@end

@implementation CTInAppFCManagerMock
@end

@interface CTInAppFCManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppFCManagerMock *inAppFCManager;
@property (nonatomic, strong) CTInAppImagePrefetchManager *prefetchManager;
@end

@implementation CTInAppFCManagerTest

- (void)setUp {
    InAppHelper *helper = [InAppHelper new];
    self.inAppFCManager = [[CTInAppFCManagerMock alloc] initWithConfig:helper.config delegateManager:helper.delegateManager deviceId:helper.deviceId impressionManager:helper.impressionManager inAppTriggerManager:helper.inAppTriggerManager];
    // Set to the reset values
    self.inAppFCManager.globalSessionMax = 1;
    self.inAppFCManager.maxPerDayCount = 1;
    self.prefetchManager = helper.imagePrefetchManager;
}

- (void)tearDown {
    [self.inAppFCManager.impressionManager removeImpressions:@"1"];
    [self.inAppFCManager.impressionManager removeImpressions:@"2"];
    [self.inAppFCManager removeStaleInAppCounts: @[@1, @2]];
    [self.inAppFCManager resetDailyCounters:self.inAppFCManager.todaysFormattedDate];
}

- (void)recordImpressions:(int)count {
    for (int i = 0; i < count; i++) {
        [self.inAppFCManager recordImpression:@"1"];
    }
}

- (void)testLocalInAppCount {
    int inAppCount = [self.inAppFCManager localInAppCount];
    [self.inAppFCManager incrementLocalInAppCount];
    
    XCTAssertEqual(inAppCount + 1, [self.inAppFCManager localInAppCount]);
}

- (void)testDidShow {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    [self.inAppFCManager didShow:notif];
    XCTAssertEqual(1, [[self.inAppFCManager.impressionManager getImpressions:@"1"] count]);
    XCTAssertEqual(1, [self.inAppFCManager shownTodayCount]);
    XCTAssertEqualObjects(@1, self.inAppFCManager.inAppCounts[@"1"][0]);
    XCTAssertEqualObjects(@1, self.inAppFCManager.inAppCounts[@"1"][1]);
    
    [self.inAppFCManager didShow:notif];
    XCTAssertEqual(2, [[self.inAppFCManager.impressionManager getImpressions:@"1"] count]);
    XCTAssertEqual(2, [self.inAppFCManager shownTodayCount]);
    XCTAssertEqualObjects(@2, self.inAppFCManager.inAppCounts[@"1"][0]);
    XCTAssertEqualObjects(@2, self.inAppFCManager.inAppCounts[@"1"][1]);
}

- (void)testRecordImpression {
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"2"];
    XCTAssertEqual(3, [self.inAppFCManager shownTodayCount]);
    
    XCTAssertEqual(2, [[self.inAppFCManager.impressionManager getImpressions:@"1"] count]);
    XCTAssertEqualObjects(@2, self.inAppFCManager.inAppCounts[@"1"][0]);
    XCTAssertEqualObjects(@2, self.inAppFCManager.inAppCounts[@"1"][1]);
    
    XCTAssertEqual(1, [[self.inAppFCManager.impressionManager getImpressions:@"2"] count]);
    XCTAssertEqualObjects(@1, self.inAppFCManager.inAppCounts[@"2"][0]);
    XCTAssertEqualObjects(@1, self.inAppFCManager.inAppCounts[@"2"][1]);
}

- (void)testRemoveStaleInAppCounts {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    [self.inAppFCManager didShow:notif];
    XCTAssertNotNil(self.inAppFCManager.inAppCounts[@"1"]);

    [self.inAppFCManager removeStaleInAppCounts:@[@1]];
    XCTAssertNil(self.inAppFCManager.inAppCounts[@"1"]);
}

- (void)testResetDailyCounters {
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"2"];

    [self.inAppFCManager resetDailyCounters:@"20231119"];
    XCTAssertEqualObjects(@0, self.inAppFCManager.inAppCounts[@"1"][0]);
    XCTAssertEqualObjects(@2, self.inAppFCManager.inAppCounts[@"1"][1]);
    XCTAssertEqualObjects(@0, self.inAppFCManager.inAppCounts[@"2"][0]);
    XCTAssertEqualObjects(@1, self.inAppFCManager.inAppCounts[@"2"][1]);
}

- (void)testOnBatchHeaderCreationForQueue {
    NSDictionary *expected = @{
        @"af.LIAMC": @0,
        @"imp": @4,
        @"tlc": @[
            @[
                @"1",
                @3,
                @3
            ],
            @[
                @"2",
                @1,
                @1
            ]
        ]
    };
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"2"];

    NSDictionary *actual = (NSDictionary *)[self.inAppFCManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];
    XCTAssertTrue([expected isEqualToDictionary:actual]);
}

- (void)testSessionCapacityMaxedOutGlobal {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    self.inAppFCManager.globalSessionMax = 5;
    
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(-1, notif.maxPerSession);
    // Record 4 impressions
    [self recordImpressions:4];
    XCTAssertFalse([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    // Record 1 more = 5
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
}

- (void)testSessionCapacityMaxedOutGlobalLegacy {
    NSDictionary *inApp = @{
        @"ti": @1,
        @"w": @{
            @"dk": @NO,
            @"sc": @YES,
            @"pos": @"c",
            @"xp": @90,
            @"yp": @85,
            @"mdc": @1000
        },
        @"d": @{
            @"html": @""
        }
    };
    self.inAppFCManager.globalSessionMax = 5;
    
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(1000, notif.maxPerSession);
    // Record 4 impressions
    [self recordImpressions:4];
    XCTAssertFalse([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    // Record 1 more = 5
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
}

- (void)testSessionCapacityMaxedOutInApp {
    // Testing in-app capacity only
    // Set sessionImpressions directly to keep sessionImpressionsTotal value
    self.inAppFCManager.globalSessionMax = 2000;
    self.inAppFCManager.impressionManager.sessionImpressionsTotal = 0;
    
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    self.inAppFCManager.impressionManager.sessionImpressions = [@{} mutableCopy];
    // InApp session max will default to -1 on notification level
    XCTAssertEqual(-1, notif.maxPerSession);
    XCTAssertFalse([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    self.inAppFCManager.impressionManager.sessionImpressions = [@{
        @"1": @2
    } mutableCopy];
    XCTAssertFalse([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    // It will default to 1000 in InAppFCManager
    self.inAppFCManager.impressionManager.sessionImpressions = [@{
        @"1": @1000
    } mutableCopy];
    XCTAssertTrue([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    NSDictionary *inAppMdc1000 = @{
        @"ti": @1,
        @"mdc": @1
    };
    notif = [[CTInAppNotification alloc] initWithJSON:inAppMdc1000 imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(1, notif.maxPerSession);
    
    self.inAppFCManager.impressionManager.sessionImpressions = [@{} mutableCopy];
    XCTAssertFalse([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    self.inAppFCManager.impressionManager.sessionImpressions = [@{
        @"1": @1
    } mutableCopy];
    XCTAssertTrue([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    NSDictionary *inAppMdc3 = @{
        @"ti": @1,
        @"mdc": @3
    };
    notif = [[CTInAppNotification alloc] initWithJSON:inAppMdc3 imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(3, notif.maxPerSession);
    self.inAppFCManager.impressionManager.sessionImpressions = [@{
        @"1": @2
    } mutableCopy];
    XCTAssertFalse([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    self.inAppFCManager.impressionManager.sessionImpressions = [@{
        @"1": @3
    } mutableCopy];
    XCTAssertTrue([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
}

- (void)testSessionCapacityMaxedOutInAppLegacy {
    // Testing in-app capacity only
    // Set sessionImpressions directly to keep sessionImpressionsTotal value
    self.inAppFCManager.globalSessionMax = 2000;
    self.inAppFCManager.impressionManager.sessionImpressionsTotal = 0;
    
    NSDictionary *inAppMdc3 = @{
        @"ti": @1,
        @"w": @{
            @"dk": @NO,
            @"sc": @YES,
            @"pos": @"c",
            @"xp": @90,
            @"yp": @85,
            @"mdc": @3
        },
        @"d": @{
            @"html": @""
        }
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inAppMdc3 imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(3, notif.maxPerSession);
    self.inAppFCManager.impressionManager.sessionImpressions = [@{
        @"1": @2
    } mutableCopy];
    XCTAssertFalse([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
    
    self.inAppFCManager.impressionManager.sessionImpressions = [@{
        @"1": @3
    } mutableCopy];
    XCTAssertTrue([self.inAppFCManager hasSessionCapacityMaxedOut:notif]);
}

- (void)testLifetimeCapacityMaxedOut {
    NSDictionary *inApp = @{
        @"ti": @1,
        @"tlc": @5
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(5, notif.totalLifetimeCount);
    XCTAssertFalse([self.inAppFCManager hasLifetimeCapacityMaxedOut:notif]);
    
    // Record 4 impressions
    [self recordImpressions:4];
    XCTAssertFalse([self.inAppFCManager hasLifetimeCapacityMaxedOut:notif]);
    
    // Record 1 more = 5
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasLifetimeCapacityMaxedOut:notif]);
}

- (void)testDailyCapacityMaxedOutGlobalDefault {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(-1, notif.totalDailyCount);
    XCTAssertFalse([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
    // Max Default is 1
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
}

- (void)testDailyCapacityMaxedOutGlobal {
    self.inAppFCManager.maxPerDayCount = 5;
    NSDictionary *inApp = @{
        @"ti": @1,
        @"tdc": @10
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(10, notif.totalDailyCount);
    XCTAssertFalse([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
    
    // Record 4 impressions
    [self recordImpressions:4];
    XCTAssertFalse([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
    
    // Record 1 more = 5
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
}

- (void)testDailyCapacityMaxedOutInApp {
    self.inAppFCManager.maxPerDayCount = 10;
    NSDictionary *inApp = @{
        @"ti": @1,
        @"tdc": @5
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp imagePrefetchManager:self.prefetchManager];
    XCTAssertEqual(5, notif.totalDailyCount);
    
    // Record 4 impressions
    [self recordImpressions:4];
    XCTAssertFalse([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
    
    // Record 1 more = 5
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
}

@end
