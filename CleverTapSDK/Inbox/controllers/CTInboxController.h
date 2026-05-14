#import <Foundation/Foundation.h>
#import "CleverTap.h"
#import "CTEncryptionManager.h"

@protocol CTInboxDelegate <NSObject>
@required
- (void)inboxMessagesDidUpdate;
@end

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, assign, readonly) NSInteger count;
@property (nonatomic, assign, readonly) NSInteger unreadCount;
@property (nonatomic, assign, readonly, nullable) NSArray<NSDictionary *> *messages;
@property (nonatomic, assign, readonly, nullable) NSArray<NSDictionary *> *unreadMessages;

@property (nonatomic, weak) id<CTInboxDelegate> delegate;


- (instancetype) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithAccountId:(NSString *)accountId
                                       guid:(NSString *)guid
                            encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel
                    previousEncryptionLevel:(CleverTapEncryptionLevel)previousEncryptionLevel
                          encryptionManager:(CTEncryptionManager*)encryptionManager;

- (void)updateMessages:(NSArray<NSDictionary*> *)messages;
- (NSDictionary * _Nullable )messageForId:(NSString *)messageId;
- (void)deleteMessageWithId:(NSString *)messageId;
- (void)deleteMessagesWithId:(NSArray *_Nonnull)messageIds;
- (void)markReadMessageWithId:(NSString *)messageId;
- (void)markReadMessagesWithId:(NSArray *_Nonnull)messageIds;
- (void)performExpiryPurge;

- (BOOL)isV2MessageId:(NSString *)messageId;
- (void)addV2MessageIds:(NSArray<NSString *> *)messageIds;
- (void)removeV2MessageId:(NSString *)messageId;
- (void)deleteAbsentPersistentV2MessagesFromResponseIds:(NSSet<NSString *> *)responseIds;

@end

NS_ASSUME_NONNULL_END
