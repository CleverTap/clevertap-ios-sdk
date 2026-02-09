//
//  CTInAppNotificationDisplayDelegate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTInAppNotificationDisplayDelegate_h
#define CTInAppNotificationDisplayDelegate_h

@class CTInAppDisplayViewController;
@class CTInAppNotification;
@class CTNotificationAction;

@protocol CTInAppNotificationDisplayDelegate <NSObject>

- (void)notificationDidShow:(CTInAppNotification *)notification;

- (void)handleNotificationAction:(CTNotificationAction *)action forNotification:(CTInAppNotification *)notification withExtras:(NSDictionary *)extras;

- (void)notificationDidDismiss:(CTInAppNotification *)notification fromViewController:(CTInAppDisplayViewController *)controller;

/**
 Called when in-app button is tapped for requesting push permission.
 */
- (void)handleInAppPushPrimer:(CTInAppNotification *)notification
           fromViewController:(CTInAppDisplayViewController *)controller
       withFallbackToSettings:(BOOL)isFallbackToSettings;

/**
 Called to notify that local in-app push primer is dismissed.
 */
- (void)inAppPushPrimerDidDismissed;

@end

#endif /* Header_h */
