#import <Foundation/Foundation.h>

@protocol CleverTapPushNotificationDelegate <NSObject>

/*!
@discussion
When a push notification is clicked with custom extras, this method will be called.

@param extras The extra key/value pairs set in the CleverTap dashboard for this notification
*/
@optional
- (void)pushNotificationTappedWithCustomExtras:(NSDictionary *)customExtras;

@end
