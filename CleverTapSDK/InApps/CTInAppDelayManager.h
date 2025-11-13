#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CTDispatchQueueManager.h"
#import "CTInAppStore.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CTInAppDelayManagerDelegate <NSObject>
- (void)delayedInAppReady:(NSDictionary *)inApp;
@end

@interface CTInAppDelayManager : NSObject

@property (nonatomic, weak) id<CTInAppDelayManagerDelegate> delegate;
@property (nonatomic, strong) NSMutableSet<NSString *> *scheduledCampaigns;

- (instancetype)initWithInAppStore:(CTInAppStore *)inAppStore withConfig:(CleverTapInstanceConfig *)config;

// Schedule management
- (void)scheduleDelayedInApps:(NSArray<NSDictionary *> *)inApps;
- (NSInteger)scheduledCampaignCount;

@end

NS_ASSUME_NONNULL_END
