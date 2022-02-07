#import "CleverTap+Tests.h"
#import "CTLoginInfoProvider.h"
#import "CTDeviceInfo.h"

@interface CleverTap (Tests)
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *profileQueue;
@property (nonatomic, strong) NSMutableArray *notificationsQueue;

+ (void)onDidFinishLaunchingNotification:(NSNotification *)notification;
- (NSDictionary *)batchHeader;

@end

@implementation CleverTap (Tests)

@dynamic eventsQueue;
@dynamic profileQueue;
@dynamic notificationsQueue;

+(void)notfityTestAppLaunch {
    [CleverTap onDidFinishLaunchingNotification:nil];
}

-(NSDictionary*)getBatchHeader {
    return [self batchHeader]; // just an example of exposing a private method for testing
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
