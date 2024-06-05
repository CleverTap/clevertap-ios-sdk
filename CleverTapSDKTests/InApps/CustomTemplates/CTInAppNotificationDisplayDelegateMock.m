//
//  CTInAppNotificationDisplayDelegateMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 5.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTInAppNotificationDisplayDelegateMock.h"

@implementation CTInAppNotificationDisplayDelegateMock

- (void)handleNotificationAction:(CTNotificationAction *)action forNotification:(CTInAppNotification *)notification withExtras:(NSDictionary *)extras {
    self.handleNotificationActionInvocations++;
    if (self.handleNotificationAction) {
        self.handleNotificationAction(action, notification, extras);
    }
}

- (void)notificationDidDismiss:(CTInAppNotification *)notification fromViewController:(CTInAppDisplayViewController *)controller {
}

- (void)notificationDidShow:(CTInAppNotification *)notification {
//    self.notificationDidShowInvocations++;
//    if (self.notificationDidShow) {
//        self.notificationDidShow(notification);
//    }
}

- (void)handleInAppPushPrimer:(CTInAppNotification *)notification fromViewController:(CTInAppDisplayViewController *)controller withFallbackToSettings:(BOOL)isFallbackToSettings {
}

- (void)inAppPushPrimerDidDismissed {
}

@end
