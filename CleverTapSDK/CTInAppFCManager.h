#import <Foundation/Foundation.h>
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTSwitchUserDelegate.h"

@class CleverTap;
@class CleverTapInstanceConfig;
@class CTInAppNotification;
@class CTInAppEvaluationManager;
@class CTImpressionManager;
@class CTMultiDelegateManager;
@class CTInAppTriggerManager;

@interface CTInAppFCManager : NSObject <CTAttachToBatchHeaderDelegate, CTSwitchUserDelegate>

@property (nonatomic, strong, readonly) CleverTapInstanceConfig *config;
@property (atomic, copy, readonly) NSString *deviceId;
@property (assign, readonly) int localInAppCount;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId
               impressionManager:(CTImpressionManager *)impressionManager
           inAppTriggerManager:(CTInAppTriggerManager *)inAppTriggerManager;

- (NSString *)storageKeyWithSuffix: (NSString *)suffix;
- (void)checkUpdateDailyLimits;
- (BOOL)canShow:(CTInAppNotification *)inapp;
- (void)didShow:(CTInAppNotification *)inapp;
- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession;

/// Currently stored account cap per session. Lets a caller preserve it when a partial response
/// carries no opinion on it — see `updateGlobalLimitsPerDay:andPerSession:`.
- (int)globalSessionMax;

/// Currently stored account cap per day.
- (int)maxPerDayCount;
- (void)removeStaleInAppCounts:(NSArray *)staleInApps;
- (BOOL)hasLifetimeCapacityMaxedOut:(CTInAppNotification *)dictionary;
- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)dictionary;
- (int)getLocalInAppCount;
- (void)incrementLocalInAppCount;
@end
