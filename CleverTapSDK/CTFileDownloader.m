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
  withCompletionBlock:(void (^)(NSDictionary<NSString *,id> *status))completion {
    if (fileURLs.count == 0) return;
    
    NSArray<NSURL *> *urls = [self getFileURLs:fileURLs];
    [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> *status) {
        [self updateFileDownloadSets:status ofType:type];
        
        [self updateFileAssetsInPreference];
        long lastDeletedTime = [self getLastDeletedTimestamp];
        [self removeInactiveExpiredAssets:lastDeletedTime];
        completion(status);
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
        [self moveAssetsToInactive];
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

#pragma mark - Private

- (void)setup {
    self.fileDownloadManager = [[CTFileDownloadManager alloc] initWithConfig:self.config];
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
                [self moveAssetsToInactive];
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
    for(NSString *key in [status allKeys]) {
        if(status[key]) {
            self.activeUrls[key] = [self addValue:type toDict:self.activeUrls andKey:key];
            if ([self.inactiveUrls objectForKey:key]) {
                [self.inactiveUrls removeObjectForKey:key];
            }
        }
    }
}

- (void)updateFileDeleteSets:(NSDictionary<NSString *,id> *)status {
    for(NSString *key in [status allKeys]) {
        if(status[key]) {
            [self.inactiveUrls removeObjectForKey:key];
        }
    }
}

- (void)moveAssetsToInactive {
    for(NSString *key in [self.activeUrls allKeys]) {
        NSMutableArray *activeTypes = [self.activeUrls[key] mutableCopy];
        if ([self.inactiveUrls objectForKey:key]) {
            NSMutableArray *inactiveTypes = [self.inactiveUrls[key] mutableCopy];
            [inactiveTypes addObjectsFromArray:activeTypes];
            self.inactiveUrls[key] = (NSMutableArray *)[[NSSet setWithArray:inactiveTypes] allObjects];
        } else {
            self.inactiveUrls[key] = activeTypes;
        }
    }
    self.activeUrls = [NSMutableDictionary new];
    
    [self updateFileAssetsInPreference];
}

- (void)addActiveFileAssets {
    // Add only active dict from preferences in `activeUrls`
    NSDictionary *activeUrlsDict = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
    self.activeUrls = [NSMutableDictionary dictionaryWithDictionary:activeUrlsDict];
}

- (void)addInactiveFileAssets {
    // Add only inactive dict from preferences in `inactiveUrls`
    NSDictionary *inactiveUrlsDict = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
    self.inactiveUrls = [NSMutableDictionary dictionaryWithDictionary:inactiveUrlsDict];
}

- (void)updateFileAssetsInPreference {
    [CTPreferences putObject:self.activeUrls
                      forKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
    [CTPreferences putObject:self.inactiveUrls
                      forKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
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

- (NSMutableArray *)addValue:(CTFileDownloadType)type
                      toDict:(NSDictionary *)dict
                      andKey:(NSString *)key {
    NSMutableArray *types = [NSMutableArray new];
    if ([dict objectForKey:key]) {
        types = [dict[key] mutableCopy];
    }
    [types addObject:[NSNumber numberWithInt:type]];
    return (NSMutableArray *)[[NSSet setWithArray:types] allObjects];
}

@end
