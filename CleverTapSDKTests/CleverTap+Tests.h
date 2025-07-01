#import <Foundation/Foundation.h>
#import <CleverTapSDK/CleverTap.h>
#import "CTValidationResult.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"
#import "CleverTapInternal.h"

@interface CleverTap (Tests)

@property (nonatomic, strong) CTDeviceInfo * deviceInfo;
@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@property (atomic, assign) BOOL currentUserOptedOut;
@property (atomic, assign) BOOL currentUserOptedOutAllowSystemEvents;

- (BOOL)_shouldDropEvent:(NSDictionary *)event withType:(CleverTapEventType)type;
- (BOOL)isMuted;
- (NSDictionary *)getCachedGUIDs;
- (NSString *)getCachedIdentitiesForConfig:(CleverTapInstanceConfig*)config;
+ (void)notfityTestAppLaunch;
- (NSDictionary *)getBatchHeader;
- (void)pushValidationResults:(NSArray<CTValidationResult *> * _Nonnull )results;
- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type;

@end
