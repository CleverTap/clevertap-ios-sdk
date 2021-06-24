#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CleverTap (InAppNotification)

#if !CLEVERTAP_NO_INAPP_SUPPORT
/*!
 
 @method
 
 @abstract
 The `CleverTapInAppNotificationDelegate` protocol provides methods for notifying
 your application (the adopting delegate) about in-app notifications.
 
 @see CleverTapInAppNotificationDelegate.h
 
 @discussion
 This sets the CleverTapInAppNotificationDelegate.
 
 @param delegate     an object conforming to the CleverTapInAppNotificationDelegate Protocol
 */
- (void)setInAppNotificationDelegate:(id <CleverTapInAppNotificationDelegate> _Nullable)delegate;

/*!
 @method
 
 @abstract
 Manually initiate the display of any pending in app notifications.
 
 */
- (void)showInAppNotificationIfAny;

/*!
 @method
 
 @abstract
 Suspends and saves inApp notifications until 'resumeInAppNotifications' is called for current session.
 
 On app kill / session reset inApp notifications suspension is disabled. Pending inApp notifications are not displayed.
 */
- (void)suspendInAppNotifications;

/*!
 @method
 
 @abstract
 Discards inApp notifications until 'resumeInAppNotifications' is called for current session.
 
 On app kill / session reset inApp notifications discard is disabled. Pending inApp notifications are not displayed.
 */
- (void)discardInAppNotifications;

/*!
 @method
 
 @abstract
 Resumes displaying inApps notifications.
 
 On app kill / session reset inApp notifications displaying is resumed. Pending inApp notifications are not displayed.
 */
- (void)resumeInAppNotifications;

#endif

@end
