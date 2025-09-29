#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CTDispatchQueueManager.h"
#import "CTInAppStore.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CTInAppDelayManagerDelegate <NSObject>
- (void)delayedInAppReady:(NSDictionary *)inApp;
- (void)delayedInAppCancelled:(NSString *)campaignId;
@end

@interface CTInAppDelayManager : NSObject

@property (nonatomic, weak) id<CTInAppDelayManagerDelegate> delegate;
@property (nonatomic, readonly) NSDictionary<NSString *, NSNumber *> *activeDelays;
@property (nonatomic, strong) NSMutableSet<NSString *> *scheduledCampaigns;

- (instancetype)initWithDispatchQueue:(CTDispatchQueueManager *)dispatchQueue inAppStore:(CTInAppStore *)inAppStore withConfig:(CleverTapInstanceConfig *)config;

// Schedule management
- (void)scheduleMultipleDelayedInApps:(NSArray<NSDictionary *> *)inApps;
- (void)cancelDelayedInApp:(NSString *)campaignId;
- (void)cancelAllDelayedInApps;

// Lifecycle management
- (void)pauseAllTimers;
- (void)resumeAllTimers;

@end

NS_ASSUME_NONNULL_END
