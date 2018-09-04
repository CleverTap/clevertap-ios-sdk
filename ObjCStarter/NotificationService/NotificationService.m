//
//  NotificationService.m
//  NotificationService
//
//  Created by Aditi Agrawal on 24/08/18.
//  Copyright © 2018 Aditi Agrawal. All rights reserved.
//

#import "NotificationService.h"
#import <CleverTapSDK/CleverTap.h>

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    [super didReceiveNotificationRequest:request withContentHandler:contentHandler];

    self.mediaUrlKey = @"myMediaUrlKey";
    self.mediaTypeKey = @"myMediaTypeKey";
    
    [CleverTap autoIntegrate];
    [[CleverTap sharedInstance] recordEvent:@"testEventFromAppex"];
    
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end
