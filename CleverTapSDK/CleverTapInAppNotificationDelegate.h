#import <Foundation/Foundation.h>


@protocol CleverTapInAppNotificationDelegate <NSObject>

/*!
 @discussion
 This is called when an in-app notification is about to be rendered.
 If you'd like this notification to not be rendered, then return false.

 Returning true will cause this notification to be rendered immediately.

 @param extras The extra key/value pairs set in the CleverTap dashboard for this notification
 */
@optional
- (BOOL)shouldShowInAppNotificationWithExtras:(NSDictionary *)extras;

/*!
 @discussion
 When an in-app notification is dismissed (either by the close button, or a call to action),
 this method will be called.

 @param extras The extra key/value pairs set in the CleverTap dashboard for this notification
 @param actionExtras The extra key/value pairs from the notification
                     (for example, a rating widget might have some properties which can be read here).

                     Note: This can be nil if the notification was dismissed without taking any action
 */
@optional
- (void)inAppNotificationDismissedWithExtras:(NSDictionary *)extras andActionExtras:(NSDictionary *)actionExtras;

/*!
 @discussion
 When an in-app notification is dismissed by a call to action with custom extras,
 this method will be called.

 @param extras The extra key/value pairs set in the CleverTap dashboard for this notification
 */
@optional
- (void)inAppNotificationButtonTappedWithCustomExtras:(NSDictionary *)customExtras;

@end
