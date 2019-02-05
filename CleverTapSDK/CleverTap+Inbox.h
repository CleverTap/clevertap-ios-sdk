@import Foundation;
#import "CleverTap.h"
@class CleverTapInboxMessageContent;

/*!
 
 @abstract
 The `CleverTapInboxMessage` represents the inbox message object.
 */

@interface CleverTapInboxMessage : NSObject

@property (nullable, nonatomic, copy, readonly) NSDictionary *json;
@property (nullable, nonatomic, copy, readonly) NSDictionary *customData;

@property (nonatomic, assign, readonly) BOOL isRead;
@property (nonatomic, assign, readonly) NSUInteger date;
@property (nonatomic, assign, readonly) NSUInteger expires;
@property (nullable, nonatomic, copy, readonly) NSString *relativeDate;
@property (nullable, nonatomic, copy, readonly) NSString *type;
@property (nullable, nonatomic, copy, readonly) NSString *messageId;
@property (nullable, nonatomic, copy, readonly) NSString *campaignId;
@property (nullable, nonatomic, copy, readonly) NSString *tagString;
@property (nullable, nonatomic, copy, readonly) NSArray *tags;
@property (nullable, nonatomic, copy, readonly) NSString *orientation;
@property (nullable, nonatomic, copy, readonly) NSString *backgroundColor;
@property (nullable, nonatomic, copy, readonly) NSArray<CleverTapInboxMessageContent *> *content;

- (void)setRead:(BOOL)read;

@end

/*!
 
 @abstract
  The `CleverTapInboxMessageContent` represents the inbox message content.
 */

@interface CleverTapInboxMessageContent : NSObject

@property (nullable, nonatomic, copy, readonly) NSString *title;
@property (nullable, nonatomic, copy, readonly) NSString *titleColor;
@property (nullable, nonatomic, copy, readonly) NSString *message;
@property (nullable, nonatomic, copy, readonly) NSString *messageColor;
@property (nullable, nonatomic, copy, readonly) NSString *backgroundColor;
@property (nullable, nonatomic, copy, readonly) NSString *mediaUrl;
@property (nullable, nonatomic, copy, readonly) NSString *videoPosterUrl;
@property (nullable, nonatomic, copy, readonly) NSString *iconUrl;
@property (nullable, nonatomic, copy, readonly) NSString *actionUrl;
@property (nullable, nonatomic, copy, readonly) NSArray *links;
@property (nonatomic, readonly, assign) BOOL mediaIsAudio;
@property (nonatomic, readonly, assign) BOOL mediaIsVideo;
@property (nonatomic, readonly, assign) BOOL mediaIsImage;
@property (nonatomic, readonly, assign) BOOL mediaIsGif;
@property (nonatomic, readonly, assign) BOOL actionHasUrl;
@property (nonatomic, readonly, assign) BOOL actionHasLinks;

- (NSString*)urlForLinkAtIndex:(int)index;

@end

@protocol CleverTapInboxViewControllerDelegate <NSObject>
- (void)messageDidSelect:(CleverTapInboxMessage *)message atIndex:(int)index withButtonIndex:(int)buttonIndex;
@end

/*!
 
 @abstract
 The `CleverTapInboxStyleConfig` has all the parameters required to configure the styling of your Inbox ViewController
 */

@interface CleverTapInboxStyleConfig : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *cellBackgroundColor;
@property (nonatomic, strong) NSArray *messageTags;
@property (nonatomic, strong) UIColor *navigationBarTintColor;
@property (nonatomic, strong) UIColor *navigationTintColor;
@property (nonatomic, strong) UIColor *tabBackgroundColor;
@property (nonatomic, strong) UIColor *tabSelectedBgColor;
@property (nonatomic, strong) UIColor *tabSelectedTextColor;
@property (nonatomic, strong) UIColor *tabUnSelectedTextColor;

@end

@interface CleverTapInboxViewController : UITableViewController

@end

typedef void (^CleverTapInboxSuccessBlock)(BOOL success);
typedef void (^CleverTapInboxUpdatedBlock)(void);

@interface CleverTap (Inbox)

/*!
 @method
 
 @abstract
 Initialized the inbox controller and sends a callback.
 
 @discussion
 Use this method to initialize the inbox controller.
 You must call this method separately for each instance of CleverTap.
 */

- (void)initializeInboxWithCallback:(CleverTapInboxSuccessBlock _Nonnull)callback;

/*!
 @method
 
 @abstract
 This method returns the total number of inbox messages for the user.
 */

- (NSUInteger)getInboxMessageCount;

/*!
 @method
 
 @abstract
 This method returns the total number of unread inbox messages for the user.
 */

- (NSUInteger)getInboxMessageUnreadCount;

/*!
 @method
 Get all the inbox messages.
 
 @abstract
 This method returns an array of `CleverTapInboxMessage` objects for the user.
 */

- (NSArray<CleverTapInboxMessage *> * _Nonnull )getAllInboxMessages;

/*!
 @method
 Get all the unread inbox messages.
 
 @abstract
 This method returns an array of unread `CleverTapInboxMessage` objects for the user.
 */

- (NSArray<CleverTapInboxMessage *> * _Nonnull )getUnreadInboxMessages;

/*!
 @method
 
 @abstract
 This method returns `CleverTapInboxMessage` object that belongs to the given messageId.
 */

- (CleverTapInboxMessage * _Nullable )getInboxMessageForId:(NSString *)messageId;

/*!
 @method
 
 @abstract
 This method deletes the given `CleverTapInboxMessage` object.
 */

- (void)deleteInboxMessage:(CleverTapInboxMessage * _Nonnull )message;

/*!
 @method
 
 @abstract
 This method marks the given `CleverTapInboxMessage` object as read.
 */

- (void)markReadInboxMessage:(CleverTapInboxMessage * _Nonnull) message;

/*!
 @method
 
 @abstract
 Register a callback block when inbox messages are updated.
 */

- (void)registerInboxUpdatedBlock:(CleverTapInboxUpdatedBlock _Nonnull)block;

/**
 
 @method
 This method opens the controller to display the inbox messages.
 
 @abstract
 The `CleverTapInboxViewControllerDelegate` protocol provides a method for notifying
 your application when a inbox message is clicked (or tapped).
 
 The `CleverTapInboxStyleConfig` has all the parameters required to configure the styling of your Inbox ViewController
 */

- (CleverTapInboxViewController * _Nullable)newInboxViewControllerWithConfig:(CleverTapInboxStyleConfig * _Nullable )config andDelegate:(id<CleverTapInboxViewControllerDelegate> _Nullable )delegate;


@end
