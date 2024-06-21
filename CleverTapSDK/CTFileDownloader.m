#import "CTFileDownloader.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTFileDownloadManager.h"

static const NSInteger kDefaultFileExpiryTime = 60 * 60 * 24 * 7 * 2; // 2 weeks

@interface CTFileDownloader()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloadManager *fileDownloadManager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *activeUrls;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *inactiveUrls;
@property (nonatomic) NSTimeInterval fileExpiryTime;

@end

@implementation CTFileDownloader

- (nonnull instancetype)initWithConfig:(nonnull CleverTapInstanceConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        [self setup];
    }
    return self;
}

#pragma mark - Public

- (void)downloadFiles:(NSArray<NSString *> *)fileURLs
               ofType:(CTFileDownloadType)type
  withCompletionBlock:(void (^ _Nullable)(NSDictionary<NSString *,id> *status))completion {
    if (fileURLs.count == 0) return;
    
    NSArray<NSURL *> *urls = [self getFileURLs:fileURLs];
    [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> *status) {
        [self updateFileDownloadSets:status ofType:type];
        
        [self updateFileAssetsInPreference];
        long lastDeletedTime = [self getLastDeletedTimestamp];
        [self removeInactiveExpiredAssets:lastDeletedTime];
        if (type == CTFileVariables) {
            // Currently we need completion callback for `CTFileVariables` only.
            completion(status);
        }
    }];
}

- (BOOL)isFileAlreadyPresent:(NSString *)url {
    NSURL *fileUrl = [NSURL URLWithString:url];
    BOOL fileExists = [self.fileDownloadManager isFileAlreadyPresent:fileUrl];
    return fileExists;
}

- (void)clearFileAssets:(BOOL)expiredOnly {
    long lastDeletedTime = [self getLastDeletedTimestamp];
    if (!expiredOnly) {
        [self moveAllFilesToInactive];
        lastDeletedTime = ([self getLastDeletedTimestamp] - (kDefaultFileExpiryTime + 1));
    }

    if ([self.inactiveUrls count] > 0) {
        [self removeInactiveExpiredAssets:lastDeletedTime];
    }
}

- (NSString *)getFileDownloadPath:(NSString *)url {
    NSString *filePath = @"";
    if ([self isFileAlreadyPresent:url]) {
        NSString *fileName = [url lastPathComponent];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:fileName];
    } else {
        CleverTapLogInternal(self.config.logLevel, @"%@ File %@ is not present.", self, url);
    }
    return filePath;
}

- (void)setFileAssetsInactiveOfType:(CTFileDownloadType)type {
    // This method is used for cases like image preloading when mode is changed from CS to SS.
    [self moveFilesToInactiveOfType:type];
    
    // Check for expired images, if any delete them.
    [self clearFileAssets:YES];
}

- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *imagePath = [documentsPath stringByAppendingPathComponent:[imageURL lastPathComponent]];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:imagePath]];
    if (image) {
        return image;
    }
    
    CleverTapLogInternal(self.config.logLevel, @"%@ Failed to load image from path %@", self, imagePath);
    return nil;
}

#pragma mark - Private

- (void)setup {
    self.fileDownloadManager = [CTFileDownloadManager sharedInstanceWithConfig:self.config];
    self.fileExpiryTime = kDefaultFileExpiryTime;
    self.activeUrls = [NSMutableDictionary new];
    self.inactiveUrls = [NSMutableDictionary new];
    
    [self addActiveFileAssets];
    [self addInactiveFileAssets];
}

- (void)removeInactiveExpiredAssets:(long)lastDeletedTime {
    if (lastDeletedTime > 0) {
        long currentTime = (long) [[NSDate date] timeIntervalSince1970];
        if (currentTime - lastDeletedTime > self.fileExpiryTime) {
            NSArray<NSString *> *inactiveUrls = [self.inactiveUrls allKeys];
            [self.fileDownloadManager deleteFiles:inactiveUrls withCompletionBlock:^(NSDictionary<NSString *,id> *status) {
                [self updateFileDeleteSets:status];
                [self moveAllFilesToInactive];
                [self updateLastDeletedTimestamp];
            }];
        }
    }
}

- (NSArray<NSURL *> *)getFileURLs:(NSArray<NSString *> *)fileURLs {
    NSMutableSet<NSURL *> *urls = [NSMutableSet new];
    for (NSString *urlString in fileURLs) {
        NSURL *url = [NSURL URLWithString:urlString];
        [urls addObject:url];
    }
    return [urls allObjects];
}

- (void)updateFileDownloadSets:(NSDictionary<NSString *,id> *)status
                        ofType:(CTFileDownloadType)type {
    @synchronized (self) {
        for(NSString *key in [status allKeys]) {
            if(status[key]) {
                [self addTypeToActive:type forkey:key];
                if ([self.inactiveUrls objectForKey:key]) {
                    [self.inactiveUrls removeObjectForKey:key];
                }
            }
        }
    }
}

- (void)updateFileDeleteSets:(NSDictionary<NSString *,id> *)status {
    @synchronized (self) {
        for(NSString *key in [status allKeys]) {
            if(status[key]) {
                [self.inactiveUrls removeObjectForKey:key];
            }
        }
    }
}

- (void)moveFilesToInactiveOfType:(CTFileDownloadType)type {
    // This add files of given type to inactive dict and remove from active dict.
    @synchronized (self) {
        for(NSString *key in [self.activeUrls allKeys]) {
            NSMutableArray *activeTypes = [self.activeUrls[key] mutableCopy];
            if ([activeTypes containsObject:[NSNumber numberWithInt:type]]) {
                // Add url to inactive dict only when url is not used by other types.
                if ([activeTypes count] == 1) {
                    NSMutableArray *types = [NSMutableArray new];
                    [types addObject:[NSNumber numberWithInt:type]];
                    [self addTypesToInactive:types forKey:key];
                }
                [self removeTypeFromActive:type forKey:key];
            }
        }
    }
    [self updateFileAssetsInPreference];
}

- (void)moveAllFilesToInactive {
    // Move all file urls from active to inactive dictionary.
    @synchronized (self) {
        for(NSString *key in [self.activeUrls allKeys]) {
            NSMutableArray *activeTypes = [self.activeUrls[key] mutableCopy];
            [self addTypesToInactive:activeTypes forKey:key];
        }
        self.activeUrls = [NSMutableDictionary new];
    }
    
    [self updateFileAssetsInPreference];
}

- (void)addActiveFileAssets {
    // Add only active dict from preferences in `activeUrls`
    @synchronized (self) {
        NSDictionary *activeUrlsDict = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
        self.activeUrls = [NSMutableDictionary dictionaryWithDictionary:activeUrlsDict];
    }
}

- (void)addInactiveFileAssets {
    // Add only inactive dict from preferences in `inactiveUrls`
    @synchronized (self) {
        NSDictionary *inactiveUrlsDict = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
        self.inactiveUrls = [NSMutableDictionary dictionaryWithDictionary:inactiveUrlsDict];
    }
}

- (void)updateFileAssetsInPreference {
    @synchronized (self) {
        [CTPreferences putObject:self.activeUrls
                          forKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
        [CTPreferences putObject:self.inactiveUrls
                          forKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
    }
}

- (long)getLastDeletedTimestamp {
    long now = (long) [[NSDate date] timeIntervalSince1970];
    long lastDeletedTime = [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]
                                           withResetValue:now];
    return lastDeletedTime;
}

- (void)updateLastDeletedTimestamp {
    long now = (long) [[NSDate date] timeIntervalSince1970];
    [CTPreferences putInt:now
                   forKey:[self storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]];
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

- (void)addTypeToActive:(CTFileDownloadType)type
                 forkey:(NSString *)key {
    // Adds the type to the file url key array in Active dictionary.
    NSMutableArray *types = [NSMutableArray new];
    if ([self.activeUrls objectForKey:key]) {
        types = [self.activeUrls[key] mutableCopy];
    }
    [types addObject:[NSNumber numberWithInt:type]];
    self.activeUrls[key] = (NSMutableArray *)[[NSSet setWithArray:types] allObjects];
}

- (void)removeTypeFromActive:(CTFileDownloadType)type
                      forKey:(NSString *)key {
    // Removes the type from file url key array,
    // Removes the file url key if array is empty after deleting type.
    NSMutableArray *types = [self.activeUrls[key] mutableCopy];
    [types removeObject:[NSNumber numberWithInt:type]];
    if (types.count > 0) {
        self.activeUrls[key] = types;
    } else {
        [self.activeUrls removeObjectForKey:key];
    }
}

- (void)addTypesToInactive:(NSMutableArray *)types
                    forKey:(NSString *)key {
    // Adds the array types to the file url key in Inactive dictionary.
    if ([self.inactiveUrls objectForKey:key]) {
        NSMutableArray *inactiveTypes = [self.inactiveUrls[key] mutableCopy];
        [inactiveTypes addObjectsFromArray:types];
        self.inactiveUrls[key] = (NSMutableArray *)[[NSSet setWithArray:inactiveTypes] allObjects];
    } else {
        self.inactiveUrls[key] = types;
    }
}

@end
