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

@protocol CTInAppNotificationDisplayDelegate <NSObject>

- (void)notificationDidShow:(CTInAppNotification *)notification;

- (void)handleNotificationCTA:(NSURL *)ctaURL buttonCustomExtras:(NSDictionary *)buttonCustomExtras forNotification:(CTInAppNotification *)notification fromViewController:(CTInAppDisplayViewController *)controller withExtras:(NSDictionary *)extras;

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
