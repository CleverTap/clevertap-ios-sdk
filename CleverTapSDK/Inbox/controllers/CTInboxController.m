
@import CoreData;
#import "CTInboxController.h"
#import "CTConstants.h"
#import "CTUserMO.h"
#import "CTMessageMO.h"
#import "CTInboxUtils.h"


// Keep the persistent store coordinator static since the inbox file location is shared
static NSPersistentStoreCoordinator *sharedCoordinator;
static dispatch_once_t coordinatorOnceToken;
static NSLock *coordinatorLock;

@interface CTInboxController ()

@property (nonatomic, copy, readonly) NSString *accountId;
@property (nonatomic, copy, readonly) NSString *guid;
@property (nonatomic, copy, readonly) NSString *userIdentifier;
@property (nonatomic, strong, readonly) CTUserMO *user;

// Instance-specific context
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation CTInboxController

@synthesize count=_count;
@synthesize unreadCount=_unreadCount;
@synthesize messages=_messages;
@synthesize unreadMessages=_unreadMessages;

#pragma mark - Initialization

+ (void)initialize {
    if (self == [CTInboxController class]) {
        coordinatorLock = [[NSLock alloc] init];
    }
}

// blocking, call off main thread
- (instancetype)initWithAccountId:(NSString *)accountId guid:(NSString *)guid {
    
    if (self = [super init]) {
        // Initialize shared coordinator if needed
        [CTInboxController initializeSharedCoordinator];
        
        _isInitialized = (sharedCoordinator != nil);
        
        if (_isInitialized) {
            _accountId = [accountId copy];
            _guid = [guid copy];
            
            NSString *userIdentifier = [NSString stringWithFormat:@"%@:%@", accountId, guid];
            _userIdentifier = userIdentifier;
            
            // Create instance-specific context with private queue
            _context = [[NSManagedObjectContext alloc]
                        initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _context.persistentStoreCoordinator = sharedCoordinator;
            
            // Configure merge policy for conflict resolution
            _context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            
            // Automatically merge changes from other contexts (iOS 10+)
            if (@available(iOS 10.0, *)) {
                _context.automaticallyMergesChangesFromParent = YES;
            }
            
            // Create or fetch user on the context's queue
            __weak typeof(self) weakSelf = self;
            [_context performBlockAndWait:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                strongSelf->_user = [CTUserMO fetchOrCreateFromJSON:@{
                    @"accountId": accountId,
                    @"guid": guid,
                    @"identifier": userIdentifier
                } forContext:strongSelf.context];
                
                [strongSelf _save];
            }];
        }
    }
    return self;
}

+ (void)initializeSharedCoordinator {
    dispatch_once(&coordinatorOnceToken, ^{
        @try {
            // Load Core Data model
            NSURL *modelURL = [[CTInboxUtils bundle:self.class]
                               URLForResource:@"Inbox" withExtension:@"momd"];
            NSManagedObjectModel *mom = [[NSManagedObjectModel alloc]
                                         initWithContentsOfURL:modelURL];
            
            if (!mom) {
                CleverTapLogStaticDebug(@"Failed to load Core Data model from bundle");
                return;
            }
            
            // Create persistent store coordinator
            sharedCoordinator = [[NSPersistentStoreCoordinator alloc]
                                 initWithManagedObjectModel:mom];
            
            // Get store URL
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory
                                                        inDomains:NSUserDomainMask] lastObject];
            NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"CleverTap-Inbox.sqlite"];
            
            // Configure store options with WAL mode for better concurrency. This is backward compatible
            NSDictionary *options = @{
                NSMigratePersistentStoresAutomaticallyOption: @YES,
                NSInferMappingModelAutomaticallyOption: @YES,
                NSSQLitePragmasOption: @{@"journal_mode": @"WAL"}
            };
            
            NSError *error = nil;
            NSPersistentStore *store = [sharedCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                       configuration:nil
                                                                                 URL:storeURL
                                                                             options:options
                                                                               error:&error];
            
            if (!store) {
                CleverTapLogStaticDebug(@"Failed to initialize Core Data persistent store: %@\n%@",
                                       [error localizedDescription], [error userInfo]);
                sharedCoordinator = nil;
            }
        } @catch (NSException *e) {
            CleverTapLogStaticDebug(@"Failed to initialize Core Data store: %@", e.debugDescription);
            sharedCoordinator = nil;
        }
    });
}

- (void)dealloc {
    _context = nil;
    _user = nil;
}

#pragma mark - Public Methods

- (void)updateMessages:(NSArray<NSDictionary*> *)messages {
    if (!self.isInitialized) return;
    
    __weak typeof(self) weakSelf = self;
    [self.context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        CleverTapLogStaticInternal(@"%@: updating messages: %@", strongSelf.user, messages);
        BOOL haveUpdates = [strongSelf.user updateMessages:messages
                                                 forContext:strongSelf.context];
        
        if (haveUpdates) {
            [strongSelf _save];
            [strongSelf _notifyUpdateOnMainThread];
        }
    }];
}

- (void)deleteMessageWithId:(NSString *)messageId {
    if (!self.isInitialized || !messageId) return;
    
    __weak typeof(self) weakSelf = self;
    [self.context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        CTMessageMO *message = [strongSelf _messageForId:messageId];
        if (message) {
            [strongSelf _deleteMessages:@[message]];
        }
    }];
}

- (void)deleteMessagesWithId:(NSArray *)messageIds {
    if (!self.isInitialized || !messageIds || messageIds.count == 0) return;
    
    __weak typeof(self) weakSelf = self;
    [self.context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        NSMutableArray *toDelete = [NSMutableArray new];
        
        for (NSString *messageId in messageIds) {
            if (messageId && ![messageId isEqualToString:@""]) {
                CTMessageMO *msg = [strongSelf _messageForId:messageId];
                if (msg) {
                    [toDelete addObject:msg];
                } else {
                    CleverTapLogStaticDebug(@"Cannot delete App Inbox Message because Message ID %@ is invalid.", messageId);
                }
            } else {
                CleverTapLogStaticDebug(@"Cannot delete App Inbox Message because Message ID is null or not a string.");
            }
        }
        
        if (toDelete.count > 0) {
            [strongSelf _deleteMessages:toDelete];
        }
    }];
}

- (void)markReadMessageWithId:(NSString *)messageId {
    if (!self.isInitialized || !messageId) return;
    
    __weak typeof(self) weakSelf = self;
    [self.context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        CTMessageMO *message = [strongSelf _messageForId:messageId];
        if (message) {
            message.isRead = YES;
            [strongSelf _save];
            [strongSelf _notifyUpdateOnMainThread];
        }
    }];
}

- (void)markReadMessagesWithId:(NSArray *)messageIds {
    if (!self.isInitialized || !messageIds || messageIds.count == 0) return;
    
    __weak typeof(self) weakSelf = self;
    [self.context performBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        BOOL hasChanges = NO;
        
        for (NSString *messageId in messageIds) {
            if (messageId && ![messageId isEqualToString:@""]) {
                CTMessageMO *message = [strongSelf _messageForId:messageId];
                if (message) {
                    message.isRead = YES;
                    hasChanges = YES;
                } else {
                    CleverTapLogStaticDebug(@"Cannot mark App Inbox Message as read because Message ID %@ is invalid.", messageId);
                }
            } else {
                CleverTapLogStaticDebug(@"Cannot mark App Inbox Message as read because Message ID is null or not a string.");
            }
        }
        
        if (hasChanges) {
            [strongSelf _save];
            [strongSelf _notifyUpdateOnMainThread];
        }
    }];
}

- (NSDictionary *)messageForId:(NSString *)messageId {
    if (!self.isInitialized || !messageId) return nil;
    
    __block NSDictionary *result = nil;
    
    [self.context performBlockAndWait:^{
        CTMessageMO *msg = [self _messageForId:messageId];
        if (msg) {
            result = [msg toJSON];
        }
    }];
    
    return result;
}

- (NSInteger)count {
    if (!self.isInitialized) return -1;
    
    NSArray *msgs = self.messages;
    return msgs ? msgs.count : 0;
}

- (NSInteger)unreadCount {
    if (!self.isInitialized) return -1;
    
    NSArray *msgs = self.unreadMessages;
    return msgs ? msgs.count : 0;
}

- (NSArray<NSDictionary *> *)messages {
    if (!self.isInitialized) return nil;
    
    __block NSArray<NSDictionary *> *result = nil;
    
    [self.context performBlockAndWait:^{
        result = [self _messagesFilteredByPredicate:nil];
    }];
    
    return result;
}

- (NSArray<NSDictionary *> *)unreadMessages {
    if (!self.isInitialized) return nil;
    
    __block NSArray<NSDictionary *> *result = nil;
    
    [self.context performBlockAndWait:^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isRead == NO"];
        result = [self _messagesFilteredByPredicate:predicate];
    }];
    
    return result;
}

#pragma mark - Private Methods

// Always call from inside context performBlock/performBlockAndWait
- (CTMessageMO *)_messageForId:(NSString *)messageId {
    if (!messageId) return nil;
    
    BOOL hasMessages = ([[self.user.entity propertiesByName] objectForKey:@"messages"] != nil);
    if (!hasMessages) return nil;
    
    NSOrderedSet *results = [self.user.messages filteredOrderedSetUsingPredicate:
                             [NSPredicate predicateWithFormat:@"id == %@", messageId]];
    
    return (results && results.count > 0) ? results[0] : nil;
}

// Always call from inside context performBlock
- (void)_deleteMessages:(NSArray<CTMessageMO*>*)messages {
    if (!messages || messages.count == 0) return;
    
    for (CTMessageMO *msg in messages) {
        [self.context deleteObject:msg];
    }
    
    [self _save];
    [self _notifyUpdateOnMainThread];
}

// Always call from inside context performBlock/performBlockAndWait
- (NSArray<NSDictionary *> *)_messagesFilteredByPredicate:(NSPredicate *)predicate {
    NSTimeInterval now = (int)[[NSDate date] timeIntervalSince1970];
    NSMutableArray *messages = [NSMutableArray new];
    NSMutableArray *toDelete = [NSMutableArray new];
    
    BOOL hasMessages = ([[self.user.entity propertiesByName] objectForKey:@"messages"] != nil);
    if (!hasMessages) return nil;
    
    // Get messages (filtered or all)
    NSOrderedSet *results = predicate
        ? [self.user.messages filteredOrderedSetUsingPredicate:predicate]
        : self.user.messages;
    
    // Process messages and check for expired ones
    for (CTMessageMO *msg in results) {
        int ttl = (int)msg.expires;
        if (ttl > 0 && now >= ttl) {
            CleverTapLogStaticInternal(@"%@: message expires: %@, deleting", self, msg);
            [toDelete addObject:msg];
        } else {
            [messages addObject:[msg toJSON]];
        }
    }
    
    // Sort by date (newest first)
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [messages sortUsingDescriptors:@[sortDescriptor]];
    
    // Delete expired messages
    if (toDelete.count > 0) {
        for (CTMessageMO *msg in toDelete) {
            [self.context deleteObject:msg];
        }
        [self _save];
    }
    
    return messages;
}

// Always call from inside context performBlock
- (BOOL)_save {
    if (!self.context.hasChanges) {
        return YES;
    }
    
    NSError *error = nil;
    BOOL success = [self.context save:&error];
    
    if (!success) {
        CleverTapLogStaticDebug(@"Error saving Core Data context: %@\n%@",
                               [error localizedDescription], [error userInfo]);
    }
    
    return success;
}

#pragma mark - Delegate Notification

- (void)_notifyUpdateOnMainThread {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(inboxMessagesDidUpdate)]) {
            [self.delegate inboxMessagesDidUpdate];
        }
    });
}

@end
