#import "CTFileDownloader.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTFileDownloadManager.h"

@interface CTFileDownloader()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloadManager *fileDownloadManager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *urlsExpiry;
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

- (void)downloadFiles:(NSArray<NSString *> *)fileURLs withCompletionBlock:(void (^ _Nullable)(NSDictionary<NSString *, NSNumber *> *status))completion {
    if (fileURLs.count == 0) {
        if (completion) {
            completion(@{});
        }
        return;
    }
    
    NSArray<NSURL *> *urls = [self getFileURLs:fileURLs];
    [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *, NSNumber *> *status) {
        [self updateFilesExpiry:status];
        [self updateFilesExpiryInPreference];
        
        long lastDeletedTime = [self getLastDeletedTimestamp];
        [self removeInactiveExpiredAssets:lastDeletedTime];
        if (completion) {
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
    if (expiredOnly) {
        // Disregard the last deleted timestamp to force delete the expired files
        [self removeInactiveExpiredAssets:1];
    } else {
        [self removeAllAssets];
    }
}

// TODO: rename
- (nullable NSString *)getFileDownloadPath:(NSString *)url {
    NSString *filePath = nil;
    if ([self isFileAlreadyPresent:url]) {
        NSString *fileName = [url lastPathComponent];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filePath = [documentsPath stringByAppendingPathComponent:fileName];
    } else {
        CleverTapLogInternal(self.config.logLevel, @"%@ File %@ is not present.", self, url);
    }
    return filePath;
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
    self.fileExpiryTime = CLTAP_FILE_EXPIRY_OFFSET;

    [self migrateActiveAndInactiveUrls];
    
    @synchronized (self) {
        NSDictionary *cachedUrlsExpiry = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
        if (cachedUrlsExpiry) {
            self.urlsExpiry = [cachedUrlsExpiry mutableCopy];
        } else {
            self.urlsExpiry = [NSMutableDictionary new];
        }
    }
}

- (void)removeInactiveExpiredAssets:(long)lastDeletedTime {
    if (lastDeletedTime > 0) {
        long currentTime = [self currentTimeInterval];
        if (currentTime - lastDeletedTime > self.fileExpiryTime) {
            NSMutableArray *inactiveUrls = [NSMutableArray new];
            for (NSString *key in self.urlsExpiry) {
                long expiry = [self.urlsExpiry[key] longValue];
                if (currentTime > expiry) {
                    [inactiveUrls addObject:key];
                }
            }
            
            [self deleteFiles:inactiveUrls withCompletionBlock:nil];
        }
    }
}

- (void)deleteFiles:(NSArray<NSString *> *)urls withCompletionBlock:(CTFilesDeleteCompletedBlock)completion {
    [self.fileDownloadManager deleteFiles:urls withCompletionBlock:^(NSDictionary<NSString *, id> *status) {
        [self removeDeletedFilesFromExpiry:status];
        [self updateFilesExpiryInPreference];
        [self updateLastDeletedTimestamp];
        if (completion) {
            completion(status);
        }
    }];
}

- (void)removeAllAssets {
    NSArray *inactiveUrls = [self.urlsExpiry allKeys];
    [self deleteFiles:inactiveUrls withCompletionBlock:nil];
}

- (void)removeDeletedFilesFromExpiry:(NSDictionary<NSString *, NSNumber *> *)status {
    @synchronized (self) {
        for (NSString *key in status) {
            if ([status[key] boolValue]) {
                [self.urlsExpiry removeObjectForKey:key];
            }
        }
    }
}

// TODO: rename
- (NSArray<NSURL *> *)getFileURLs:(NSArray<NSString *> *)fileURLs {
    NSMutableSet<NSURL *> *urls = [NSMutableSet new];
    for (NSString *urlString in fileURLs) {
        NSURL *url = [NSURL URLWithString:urlString];
        [urls addObject:url];
    }
    return [urls allObjects];
}

- (void)updateFilesExpiry:(NSDictionary<NSString *, NSNumber *> *)status {
    @synchronized (self) {
        NSNumber *expiry = @([self currentTimeInterval] + self.fileExpiryTime);
        for (NSString *key in status) {
            // Update the expiry for urls with success status
            if ([status[key] boolValue]) {
                self.urlsExpiry[key] = expiry;
            }
        }
    }
}

- (void)updateFilesExpiryInPreference {
    @synchronized (self) {        
        [CTPreferences putObject:self.urlsExpiry forKey:[self storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
    }
}

// TODO: rename
- (long)getLastDeletedTimestamp {
    long lastDeletedTime = [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]
                                           withResetValue:[self currentTimeInterval]];
    return lastDeletedTime;
}

- (void)updateLastDeletedTimestamp {
    [CTPreferences putInt:[self currentTimeInterval]
                   forKey:[self storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]];
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

- (long)currentTimeInterval {
    return [[NSDate date] timeIntervalSince1970];
}

- (void)migrateActiveAndInactiveUrls {
    NSArray<NSString *> *activeAssetsArray = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]];
    NSArray<NSString *> *inactiveAssetsArray = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]];
    NSMutableSet<NSString *> *urls = [NSMutableSet new];
    if (activeAssetsArray && activeAssetsArray.count > 0) {
        [urls addObjectsFromArray:activeAssetsArray];
    }
    if (inactiveAssetsArray && inactiveAssetsArray.count > 0) {
        [urls addObjectsFromArray:inactiveAssetsArray];
    }
    NSMutableDictionary<NSString *, NSNumber *> *urlsExpiry = [NSMutableDictionary new];
    NSNumber *expiry = @([self currentTimeInterval] + self.fileExpiryTime);
    for (NSString *url in urls) {
        urlsExpiry[url] = expiry;
    }
    
    if (urlsExpiry.count > 0) {
        [CTPreferences putObject:urlsExpiry forKey:[self storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]];
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]];
    }
    id inAppAssetsDeletedTs = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]];
    if ([inAppAssetsDeletedTs isKindOfClass:[NSNumber class]]) {
        long ts = [inAppAssetsDeletedTs longLongValue];
        [CTPreferences putInt:ts forKey:[self storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]];
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]];
    }
}

@end
