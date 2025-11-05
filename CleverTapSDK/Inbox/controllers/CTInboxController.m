
@import CoreData;
#import "CTInboxController.h"
#import "CTConstants.h"
#import "CTUserMO.h"
#import "CTMessageMO.h"
#import "CTInboxUtils.h"


// Keep the persistent store coordinator static since the inbox file location is shared
static NSPersistentStoreCoordinator *sharedCoordinator;
static dispatch_once_t coordinatorOnceToken;

@interface CTInboxController ()

@property (nonatomic, copy, readonly) NSString *accountId;
@property (nonatomic, copy, readonly) NSString *guid;
@property (nonatomic, copy, readonly) NSString *userIdentifier;
@property (nonatomic, assign) CleverTapEncryptionLevel encryptionLevel;
@property (nonatomic, assign) CleverTapEncryptionLevel previousEncryptionLevel;
@property (nonatomic, strong) CTEncryptionManager *encryptionManager;
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

// blocking, call off main thread
- (instancetype)initWithAccountId:(NSString *)accountId
                             guid:(NSString *)guid
                  encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel
           previousEncryptionLevel:(CleverTapEncryptionLevel)previousEncryptionLevel
                encryptionManager:(nonnull CTEncryptionManager *)encryptionManager {
    
    if (self = [super init]) {
        // Initialize shared coordinator if needed
        [CTInboxController initializeSharedCoordinator];
        
        _isInitialized = (sharedCoordinator != nil);
        
        if (_isInitialized) {
            _accountId = [accountId copy];
            _guid = [guid copy];
            _encryptionLevel = encryptionLevel;
            _previousEncryptionLevel = previousEncryptionLevel;
            _encryptionManager = encryptionManager;
            
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
                } forContext:strongSelf.context encryptionManager:encryptionManager];
                
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
        
        // Pre-process messages for encryption if needed
        NSArray<NSDictionary*> *processedMessages = [strongSelf processMessagesForEncryption:messages];
        
        BOOL haveUpdates = [strongSelf.user updateMessages:processedMessages
                                                 forContext:strongSelf.context];
        
        if (haveUpdates) {
            [strongSelf _save];
            [strongSelf _notifyUpdate];
        }
    }];
}

- (NSArray<NSDictionary*> *)processMessagesForEncryption:(NSArray<NSDictionary*> *)messages {
    // If not CleverTapEncryptionHigh, return messages unchanged
    if (self.encryptionLevel != CleverTapEncryptionHigh || !self.encryptionManager) {
        return messages;
    }
    
    NSMutableArray *processedMessages = [NSMutableArray arrayWithCapacity:messages.count];
    
    for (NSDictionary *message in messages) {
        // Encrypt the message dictionary and create a wrapper
        NSString *encryptedJSON = [self.encryptionManager encryptObject:message];
        if (encryptedJSON) {
            // Create a new message dictionary with encrypted JSON
            NSMutableDictionary *processedMessage = [message mutableCopy];
            
            // Replace the original message data with encrypted version
            // but keep the _id and other lookup fields unencrypted for CoreData queries
            processedMessage[@"_ct_encrypted_payload"] = encryptedJSON;
            processedMessage[@"_ct_is_encrypted"] = @YES;
            
            CleverTapLogStaticInternal(@"Pre-encrypted message for ID: %@", message[@"_id"]);
            [processedMessages addObject:processedMessage];
        } else {
            // If encryption fails, store unencrypted
            CleverTapLogStaticDebug(@"Failed to encrypt message ID: %@, storing unencrypted", message[@"_id"]);
            [processedMessages addObject:message];
        }
    }
    
    return [processedMessages copy];
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
            [strongSelf _notifyUpdate];
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
            [strongSelf _notifyUpdate];
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
    [self _notifyUpdate];
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
        [self _deleteMessages:toDelete];
    }
    
    return messages;
}

// Always call from inside context performBlock
- (BOOL)_save {
    // Handle encryption level transitions for existing messages
    if (self.encryptionLevel != self.previousEncryptionLevel && [self.user.messages count] > 0) {
        [self migrateMessagesEncryption];
        
        // Update previousEncryptionLevel to prevent repeated migrations
        self.previousEncryptionLevel = self.encryptionLevel;
        CleverTapLogStaticDebug(@"Migration completed, updated previousEncryptionLevel to %d", (int)self.encryptionLevel);
    }
    
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

- (void)migrateMessagesEncryption {
    CleverTapLogStaticDebug(@"Migrating inbox messages encryption from level %d to %d",
                              (int)self.previousEncryptionLevel, (int)self.encryptionLevel);
    
    for (CTMessageMO *msg in self.user.messages) {
        [self migrateMessageEncryption:msg
                           fromLevel:self.previousEncryptionLevel
                             toLevel:self.encryptionLevel];
    }
}

- (void)migrateMessageEncryption:(CTMessageMO *)msg
                       fromLevel:(CleverTapEncryptionLevel)fromLevel
                         toLevel:(CleverTapEncryptionLevel)toLevel {
    
    // Scenario 1: None/Medium → High (need to encrypt json)
    if ((fromLevel == CleverTapEncryptionNone || fromLevel == CleverTapEncryptionMedium) &&
        toLevel == CleverTapEncryptionHigh) {
        
        if (msg.json && ![self isJSONPropertyEncrypted:msg.json]) {
            NSString *encryptedJSON = [self.encryptionManager encryptObject:msg.json];
            if (encryptedJSON) {
                msg.json = encryptedJSON;
                CleverTapLogStaticDebug(@"Encrypted inbox message json for message ID: %@", msg.id);
            }
        }
    }
    
    // Scenario 2: High → None/Medium (need to decrypt json)
    else if (fromLevel == CleverTapEncryptionHigh &&
             (toLevel == CleverTapEncryptionNone || toLevel == CleverTapEncryptionMedium)) {
        
        if (msg.json && [self isJSONPropertyEncrypted:msg.json]) {
            id decryptedJSON = [self.encryptionManager decryptObject:(NSString *)msg.json];
            if (decryptedJSON) {
                msg.json = decryptedJSON;
                CleverTapLogStaticDebug(@"Decrypted inbox message json for message ID: %@", msg.id);
            }
        }
    }
}

- (BOOL)isJSONPropertyEncrypted:(id)jsonProperty {
    if ([jsonProperty isKindOfClass:[NSString class]]) {
        NSString *jsonString = (NSString *)jsonProperty;
        return [self.encryptionManager isTextAESGCMEncrypted:jsonString];
    }
    return NO;
}

#pragma mark - Delegate Notification

- (void)_notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(inboxMessagesDidUpdate)]) {
        [self.delegate inboxMessagesDidUpdate];
    }
}

@end
