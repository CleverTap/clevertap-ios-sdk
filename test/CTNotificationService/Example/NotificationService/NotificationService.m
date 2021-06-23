
#import "NotificationService.h"

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler { 
    
    self.mediaUrlKey = @"myMediaUrlKey";
    self.mediaTypeKey = @"myMediaTypeKey";
    
    [super didReceiveNotificationRequest:request withContentHandler:contentHandler];
}

@end
