#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CleverTap (InAppNotifications)

#if !CLEVERTAP_NO_INAPP_SUPPORT
/*!
 @method
 
 @abstract
 Suspends and saves inApp notifications until 'resumeInAppNotifications' is called for current session.
 
 Automatically resumes InApp notifications display on CleverTap shared instance creation. Pending inApp notifications are displayed only for current session.
 */
- (void)suspendInAppNotifications;

/*!
 @method
 
 @abstract
 Discards inApp notifications until 'resumeInAppNotifications' is called for current session.
 
 Automatically resumes InApp notifications display on CleverTap shared instance creation. Pending inApp notifications are not displayed.
 */
- (void)discardInAppNotifications;

/*!
 @method
 
 @abstract
 Resumes displaying inApps notifications and shows pending inApp notifications if any.
 */
- (void)resumeInAppNotifications;

/*!
 @method
 
 @abstract
 Clear inApps images stored in disk cache
 
 @param expiredOnly  when true, it delete the expired images only
 */
- (void)clearInAppResources:(BOOL)expiredOnly;

#endif

@end
