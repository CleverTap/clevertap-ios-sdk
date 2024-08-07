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
#import "CTMultiDelegateManager+Tests.h"

@interface CTInAppFCManagerMock : CTInAppFCManager
@property (nonatomic, assign) int globalSessionMax;
@property (nonatomic, assign) int maxPerDayCount;

- (BOOL)hasInAppFrequencyLimitsMaxedOut:(CTInAppNotification *)inApp;

@end

@implementation CTInAppFCManagerMock
@end

@interface CTInAppFCManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppFCManagerMock *inAppFCManager;
@property (nonatomic, strong) CTFileDownloader *fileDownloader;
@property (nonatomic, strong) InAppHelper *helper;
@end

@implementation CTInAppFCManagerTest

#pragma mark Setup
- (void)setUp {
    InAppHelper *helper = [InAppHelper new];
    self.helper = helper;
    self.inAppFCManager = [[CTInAppFCManagerMock alloc] initWithConfig:helper.config delegateManager:helper.delegateManager deviceId:helper.deviceId impressionManager:helper.impressionManager inAppTriggerManager:helper.inAppTriggerManager];
    // Set to the reset values
    self.inAppFCManager.globalSessionMax = 1;
    self.inAppFCManager.maxPerDayCount = 1;
    self.fileDownloader = helper.fileDownloader;
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

#pragma mark Tests
- (void)testLocalInAppCount {
    int inAppCount = [self.inAppFCManager localInAppCount];
    [self.inAppFCManager incrementLocalInAppCount];
    
    XCTAssertEqual(inAppCount + 1, [self.inAppFCManager localInAppCount]);
}

- (void)testDidShow {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
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

#pragma mark Stale In-apps Tests
- (void)testRemoveStaleInAppCounts {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    [self.inAppFCManager didShow:notif];
    XCTAssertNotNil(self.inAppFCManager.inAppCounts[@"1"]);

    [self.inAppFCManager removeStaleInAppCounts:@[@1]];
    XCTAssertNil(self.inAppFCManager.inAppCounts[@"1"]);
}

- (void)testRemoveStaleInAppCountsRemovesTriggersAndImpressions {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    [self.helper.inAppTriggerManager incrementTrigger:@"1"];
    [self.inAppFCManager didShow:notif];
    XCTAssertNotNil(self.inAppFCManager.inAppCounts[@"1"]);
    XCTAssertEqual(1, [[self.helper.impressionManager getImpressions:@"1"] count]);

    [self.inAppFCManager removeStaleInAppCounts:@[@1]];
    XCTAssertNil(self.inAppFCManager.inAppCounts[@"1"]);
    XCTAssertEqual(0, [[self.helper.impressionManager getImpressions:@"1"] count]);
    XCTAssertEqual(0, [self.helper.inAppTriggerManager getTriggers:@"1"]);
}

#pragma mark Daily Counters Tests
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

#pragma mark Delegates Tests
- (void)testDelegatesAdded {
    CTMultiDelegateManager *delegateManager = [[CTMultiDelegateManager alloc] init];
    NSUInteger batchHeaderDelegatesCount = [[delegateManager attachToHeaderDelegates] count];
    NSUInteger switchUserDelegatesCount = [[delegateManager switchUserDelegates] count];

    InAppHelper *helper = [InAppHelper new];
    __unused CTInAppFCManager *manager = [[CTInAppFCManagerMock alloc] initWithConfig:helper.config delegateManager:delegateManager deviceId:helper.deviceId impressionManager:helper.impressionManager inAppTriggerManager:helper.inAppTriggerManager];
    
    XCTAssertEqual([[delegateManager attachToHeaderDelegates] count], batchHeaderDelegatesCount + 1);
    XCTAssertEqual([[delegateManager switchUserDelegates] count], switchUserDelegatesCount + 1);
}

#pragma mark OnBatchHeader Tests
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

#pragma mark Session Capacity Tests
- (void)testSessionCapacityMaxedOutGlobal {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    self.inAppFCManager.globalSessionMax = 5;
    
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
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
    
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
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
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
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
    notif = [[CTInAppNotification alloc] initWithJSON:inAppMdc1000];
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
    notif = [[CTInAppNotification alloc] initWithJSON:inAppMdc3];
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
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inAppMdc3];
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

#pragma mark Lifetime Capacity Tests
- (void)testLifetimeCapacityMaxedOut {
    NSDictionary *inApp = @{
        @"ti": @1,
        @"tlc": @5
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    XCTAssertEqual(5, notif.totalLifetimeCount);
    XCTAssertFalse([self.inAppFCManager hasLifetimeCapacityMaxedOut:notif]);
    
    // Record 4 impressions
    [self recordImpressions:4];
    XCTAssertFalse([self.inAppFCManager hasLifetimeCapacityMaxedOut:notif]);
    
    // Record 1 more = 5
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasLifetimeCapacityMaxedOut:notif]);
}

#pragma mark Daily Capacity Tests
- (void)testDailyCapacityMaxedOutGlobalDefault {
    NSDictionary *inApp = @{
        @"ti": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
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
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
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
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    XCTAssertEqual(5, notif.totalDailyCount);
    
    // Record 4 impressions
    [self recordImpressions:4];
    XCTAssertFalse([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
    
    // Record 1 more = 5
    [self recordImpressions:1];
    XCTAssertTrue([self.inAppFCManager hasDailyCapacityMaxedOut:notif]);
}

#pragma mark InApp Frequency Tests
- (void)testHasInAppFrequencyLimitsMaxedOut {
    NSDictionary *inApp = @{
        @"ti": @1,
        @"frequencyLimits": @[
            @{
                @"type": @"ever",
                @"limit": @2
            }
        ]
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    
    // 1 impression is in limit
    [self.inAppFCManager.impressionManager recordImpression:notif.Id];
    XCTAssertFalse([self.inAppFCManager hasInAppFrequencyLimitsMaxedOut:notif]);

    // 2 impressions is not in limit
    [self.inAppFCManager.impressionManager recordImpression:notif.Id];
    XCTAssertTrue([self.inAppFCManager hasInAppFrequencyLimitsMaxedOut:notif]);
}

#pragma mark CanShow Tests
- (void)testCanShowExcludeCaps {
    NSDictionary *inApp = @{
        @"ti": @1,
        @"efc": @1,
        @"tdc": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    
    [self.inAppFCManager recordImpression:notif.Id];
    XCTAssertTrue([self.inAppFCManager canShow:notif]);
}

- (void)testCanShowExcludeGlobalCaps {
    NSDictionary *inApp = @{
        @"ti": @1,
        @"excludeGlobalFCaps": @1,
        @"tdc": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    
    [self.inAppFCManager recordImpression:notif.Id];
    XCTAssertTrue([self.inAppFCManager canShow:notif]);
}

- (void)testCanShowMaxedOut {
    NSDictionary *inApp = @{
        @"ti": @1,
        @"tdc": @1
    };
    CTInAppNotification *notif = [[CTInAppNotification alloc] initWithJSON:inApp];
    
    [self.inAppFCManager recordImpression:notif.Id];
    XCTAssertFalse([self.inAppFCManager canShow:notif]);
}

#pragma mark Switch User Tests
- (void)testSwitchUser {
    NSString *firstDeviceId = self.inAppFCManager.deviceId;
    NSString *secondDeviceId = [NSString stringWithFormat:@"%@_2", firstDeviceId];
    
    // Update in-app counts for first user
    [self.inAppFCManager recordImpression:@"1"];
    [self.inAppFCManager recordImpression:@"2"];
    XCTAssertEqual([[self.inAppFCManager inAppCounts] count], 2);

    // Switch to second user
    [self.inAppFCManager deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([[self.inAppFCManager inAppCounts] count], 0);
    [self.inAppFCManager recordImpression:@"1"];
    XCTAssertEqual([[self.inAppFCManager inAppCounts] count], 1);

    // Switch to first user to ensure cached in-apps for first user are loaded
    [self.inAppFCManager deviceIdDidChange:firstDeviceId];
    XCTAssertEqual([[self.inAppFCManager inAppCounts] count], 2);
    
    // Switch to second user to ensure cached in-apps for second user are loaded
    [self.inAppFCManager deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([[self.inAppFCManager inAppCounts] count], 1);

    // Clear in-apps for the second user
    [self.inAppFCManager.impressionManager removeImpressions:@"1"];
    [self.inAppFCManager.impressionManager removeImpressions:@"2"];
    [self.inAppFCManager removeStaleInAppCounts: @[@1, @2]];
    // Switch back to first user to tear down
    [self.inAppFCManager deviceIdDidChange:firstDeviceId];
}

@end
