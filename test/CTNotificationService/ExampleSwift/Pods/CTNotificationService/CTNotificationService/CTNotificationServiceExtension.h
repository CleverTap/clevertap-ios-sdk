
#import <UserNotifications/UserNotifications.h>

@interface CTNotificationServiceExtension : UNNotificationServiceExtension

@property (nonatomic, retain) NSString * _Nullable mediaUrlKey;
@property (nonatomic, retain) NSString * _Nullable mediaTypeKey;

NS_ASSUME_NONNULL_BEGIN

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler;

@end

NS_ASSUME_NONNULL_END
