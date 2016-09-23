
#import <CleverTapSDK.hostwatchos/CleverTap.h>
#import <WatchConnectivity/WatchConnectivity.h>

NS_ASSUME_NONNULL_BEGIN

@interface CleverTap (HostWatchOS)

- (BOOL)handleMessage:(NSDictionary<NSString *, id> *)message forWatchSession:(WCSession *)session;

@end

NS_ASSUME_NONNULL_END

