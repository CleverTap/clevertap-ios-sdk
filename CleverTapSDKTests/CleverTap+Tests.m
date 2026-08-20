#import "CleverTap+Tests.h"
#import "CTLoginInfoProvider.h"
#import "CTDeviceInfo.h"
#import "CTDomainFactory.h"
#import "CTQueueType.h"

@interface CleverTap (Tests)
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *profileQueue;
@property (nonatomic, strong) NSMutableArray *notificationsQueue;
@property (nonatomic, strong) CTDomainFactory *domainFactory;

+ (void)onDidFinishLaunchingNotification:(NSNotification *)notification;
- (NSDictionary *)batchHeaderForQueue:(CTQueueType)queueType;

@end

@implementation CleverTap (Tests)

@dynamic eventsQueue;
@dynamic profileQueue;
@dynamic notificationsQueue;
@dynamic domainFactory;

+(void)notfityTestAppLaunch {
    [CleverTap onDidFinishLaunchingNotification:nil];
}

-(NSDictionary*)getBatchHeader {
    return [self batchHeaderForQueue:CTQueueTypeUndefined];
}

- (NSDictionary *)getCachedGUIDs {
    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:nil] config:self.config];
    return [loginInfoProvider getCachedGUIDs];
}

- (NSString *)getCachedIdentitiesForConfig:(CleverTapInstanceConfig*)config {
   CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:nil] config:config];
   return [loginInfoProvider getCachedIdentities];
}

@end
