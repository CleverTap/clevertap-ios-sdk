//
//  CTNdFCManager+Tests.h
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#ifndef CTNdFCManager_Tests_h
#define CTNdFCManager_Tests_h

@class CTImpressionManager;
@class CTInAppTriggerManager;

@interface CTNdFCManager (Tests)

@property (atomic, strong) CTImpressionManager *impressionManager;
@property (atomic, strong) CTInAppTriggerManager *triggerManager;
@property (atomic, strong) NSMutableDictionary *targetCounts;

- (int)globalSessionMax;
- (int)maxPerDayCount;
- (int)todayCountForTarget:(NSString *)targetId;
- (int)lifetimeCountForTarget:(NSString *)targetId;
- (NSString *)todaysFormattedDate;
- (void)resetDailyCounters:(NSString *)today;

@end

#endif /* CTNdFCManager_Tests_h */
