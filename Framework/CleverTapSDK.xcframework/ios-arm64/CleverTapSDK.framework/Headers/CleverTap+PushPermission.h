#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import "CleverTap.h"

@protocol CleverTapPushPermissionDelegate <NSObject>

/*!
 @discussion
 When an user either allow or deny permission for push notifications,
 this method will be called.
 
 @param accepted The boolean will be true/false if notification permission is granted/denied.
 */
@optional
- (void)onPushPermissionResponse:(BOOL)accepted;
@end


@interface CleverTap (PushPermission)

/*!
 
 @method
 
 @abstract
 The `CleverTapPushPermissionDelegate` protocol provides methods for notifying
 your application (the adopting delegate) about push permission response.
 
 @discussion
 This sets the CleverTapPushPermissionDelegate.
 
 @param delegate an object conforming to the CleverTapPushPermissionDelegate Protocol
 */
- (void)setPushPermissionDelegate:(id <CleverTapPushPermissionDelegate> _Nullable)delegate;

/*!
 @method
 
 @abstract
 This method will create a push primer asking user to enable push notification.
 
 @param json A NSDictionary which have all fields needed to display push primer.
 */
- (void)promptPushPrimer:(NSDictionary *_Nonnull)json;

/*!
 @method
 
 @abstract
 This method will directly show OS hard dialog for requesting push permission.
 
 @param showFallbackSettings If YES and permission is denied already, then we fallback to app’s notification settings.
 */
- (void)promptForPushPermission:(BOOL)showFallbackSettings;

/*!
 @method
 
 @abstract
 Returns the push notification permission status inside completion block.
 This method can be called before creating push primer and prompt push primer only if permission is denied.
 
 @param completion the completion block to be executed when push permission status is retrieved.
 */

- (void)getNotificationPermissionStatusWithCompletionHandler:(void (^_Nonnull)(UNAuthorizationStatus status))completion API_AVAILABLE(ios(10.0));

@end

