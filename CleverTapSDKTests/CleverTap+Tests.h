#import <Foundation/Foundation.h>
#import <CleverTapSDK/CleverTap.h>
#import "CTValidationResult.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"
#import "CleverTapInternal.h"

@interface CleverTap (Tests)

@property (nonatomic, strong) CTDeviceInfo * deviceInfo;

- (NSDictionary *)getCachedGUIDs;
- (NSString *)getCachedIdentitiesForConfig:(CleverTapInstanceConfig*)config;
+ (void)notfityTestAppLaunch;
- (NSDictionary *)getBatchHeader;
- (void)pushValidationResults:(NSArray<CTValidationResult *> * _Nonnull )results;
- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type;

@end
