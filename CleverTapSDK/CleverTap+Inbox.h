@import Foundation;
#import "CleverTap.h"
@class CleverTapInboxMessageContent;

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

@interface CleverTapInboxMessageContent : NSObject

@property (nullable, nonatomic, copy, readonly) NSString *title;
@property (nullable, nonatomic, copy, readonly) NSString *titleColor;
@property (nullable, nonatomic, copy, readonly) NSString *message;
@property (nullable, nonatomic, copy, readonly) NSString *messageColor;
@property (nullable, nonatomic, copy, readonly) NSString *backgroundColor;
@property (nullable, nonatomic, copy, readonly) NSString *mediaUrl;
@property (nullable, nonatomic, copy, readonly) NSString *iconUrl;
@property (nullable, nonatomic, copy, readonly) NSString *actionUrl;
@property (nullable, nonatomic, copy, readonly) NSArray *links;
@property (nonatomic, readonly, assign) BOOL mediaIsAudio;
@property (nonatomic, readonly, assign) BOOL mediaIsVideo;
@property (nonatomic, readonly, assign) BOOL mediaIsImage;
@property (nonatomic, readonly, assign) BOOL mediaIsGif;
@property (nonatomic, readonly, assign) BOOL actionHasUrl;
@property (nonatomic, readonly, assign) BOOL actionHasLinks;

@end

@protocol CleverTapInboxViewControllerDelegate <NSObject>
- (void)messageDidSelect:(CleverTapInboxMessage *)message atIndex:(int)index withButtonIndex:(int)buttonIndex;
@end

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

- (void)initializeInboxWithCallback:(CleverTapInboxSuccessBlock _Nonnull)callback;

- (NSUInteger)getInboxMessageCount;

- (NSUInteger)getInboxMessageUnreadCount;

- (NSArray<CleverTapInboxMessage *> * _Nonnull )getAllInboxMessages;

- (NSArray<CleverTapInboxMessage *> * _Nonnull )getUnreadInboxMessages;

- (CleverTapInboxMessage * _Nullable )getInboxMessageForId:(NSString *)messageId;

- (void)deleteInboxMessage:(CleverTapInboxMessage * _Nonnull )message;

- (void)markReadInboxMessage:(CleverTapInboxMessage * _Nonnull) message;

- (void)registerInboxUpdatedBlock:(CleverTapInboxUpdatedBlock _Nonnull)block;

- (CleverTapInboxViewController * _Nullable)newInboxViewControllerWithConfig:(CleverTapInboxStyleConfig * _Nullable )config andDelegate:(id<CleverTapInboxViewControllerDelegate> _Nullable )delegate;


@end
