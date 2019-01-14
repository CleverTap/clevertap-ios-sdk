#import <Foundation/Foundation.h>

@protocol CTInboxDelegate <NSObject>
@required
- (void)inboxMessagesDidUpdate;
@end

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, assign, readonly) NSUInteger count;
@property (nonatomic, assign, readonly) NSUInteger unreadCount;
@property (nonatomic, assign, readonly) NSArray<NSDictionary *> *messages;
@property (nonatomic, assign, readonly) NSArray<NSDictionary *> *unreadMessages;

@property (nonatomic, weak) id<CTInboxDelegate> delegate;


- (instancetype) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithAccountId:(NSString *)accountId
                                       guid:(NSString *)guid;

- (void)updateMessages:(NSArray<NSDictionary*> *)messages;
- (NSDictionary * _Nullable )messageForId:(NSString *)messageId;
- (void)deleteMessageWithId:(NSString *)messageId;
- (void)markReadMessageWithId:(NSString *)messageId;

@end

NS_ASSUME_NONNULL_END
