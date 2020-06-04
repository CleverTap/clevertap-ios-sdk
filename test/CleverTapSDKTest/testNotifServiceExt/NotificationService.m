#import "NotificationService.h"
//@import CleverTapSDK;

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
//    [CleverTap setDebugLevel:CleverTapLogDebug+22];
//    [CleverTap autoIntegrate];
//    [[CleverTap sharedInstance] recordEvent:@"testEventFromAppex"];
    [super didReceiveNotificationRequest:request withContentHandler:contentHandler];
    
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end
