#import <Foundation/Foundation.h>
#import "CTAttachToHeaderDelegate.h"
#import "CTSwitchUserDelegate.h"

@class CleverTap;
@class CleverTapInstanceConfig;
@class CTInAppNotification;
@class CTInAppEvaluationManager;
@class CTImpressionManager;

@interface CTInAppFCManager : NSObject <CTAttachToHeaderDelegate, CTSwitchUserDelegate>

@property (nonatomic, strong, readonly) CleverTapInstanceConfig *config;
@property (atomic, copy, readonly) NSString *deviceId;
@property (assign, readonly) int localInAppCount;

- (instancetype)initWithInstance:(CleverTap *)instance
                      deviceId:(NSString *)deviceId
               evaluationManager: (CTInAppEvaluationManager *)evaluationManager impressionManager:(CTImpressionManager *)impressionManager;

- (NSString *)storageKeyWithSuffix: (NSString *)suffix;
- (void)checkUpdateDailyLimits;
- (BOOL)canShow:(CTInAppNotification *)inapp;
- (void)incrementLocalInAppCount;
- (void)didShow:(CTInAppNotification *)inapp;
- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession;
- (void)removeStaleInAppCounts:(NSArray *)staleInApps;
- (BOOL)hasLifetimeCapacityMaxedOut:(CTInAppNotification *)dictionary;
- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)dictionary;
- (int)getLocalInAppCount;
- (void)incrementLocalInAppCount;
@end
