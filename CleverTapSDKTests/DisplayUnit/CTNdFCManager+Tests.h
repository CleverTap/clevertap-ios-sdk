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
@property (atomic, strong) NSMutableDictionary *campaignCounts;

- (int)globalSessionMax;
- (int)maxPerDayCount;
- (int)todayCountForCampaign:(NSString *)campaignId;
- (int)lifetimeCountForCampaign:(NSString *)campaignId;
- (NSString *)todaysFormattedDate;
- (void)resetDailyCounters:(NSString *)today;

@end

#endif /* CTNdFCManager_Tests_h */
