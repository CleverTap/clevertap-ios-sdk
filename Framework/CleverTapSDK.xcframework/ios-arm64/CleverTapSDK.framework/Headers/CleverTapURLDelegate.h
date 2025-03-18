#import <Foundation/Foundation.h>

@protocol CleverTapURLDelegate <NSObject>

/*!
 @method
 
 @abstract
 Implement custom handling of URLs.
 
 @discussion
 Use this method if you would like to implement custom handling for URLs in case of in-app notification CTAs, push notifications and App inbox.
 
 Use the following enum values of type CleverTapChannel to optionally implement URL handling based on the corresponding CleverTap channel.
 
 CleverTapPushNotification - Remote Notifications,
 CleverTapAppInbox - App Inbox,
 CleverTapInAppNotification - In-App Notification
 
 @param url                     the NSURL object
 @param channel            the CleverTapChannel enum value
 */
- (BOOL)shouldHandleCleverTapURL:(NSURL *_Nullable )url forChannel:(CleverTapChannel)channel;

@end
