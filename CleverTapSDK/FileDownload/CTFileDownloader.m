#import "CTFileDownloader.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTFileDownloadManager.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import <SDWebImage/SDImageCache.h>
#endif

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
    
    NSArray<NSURL *> *urls = [self fileURLs:fileURLs];
    [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *, NSNumber *> *status) {
        [self updateFilesExpiry:status];
        [self updateFilesExpiryInPreference];
        
        long lastDeletedTime = [self lastDeletedTimestamp];
        [self removeInactiveExpiredAssets:lastDeletedTime];

        if (completion) {
            completion(status);
        }
    }];
}

- (BOOL)isFileAlreadyPresent:(NSString *)url
         andUpdateExpiryTime:(BOOL)updateExpiryTime {
    NSURL *fileUrl = [NSURL URLWithString:url];
    BOOL fileExists = [self.fileDownloadManager isFileAlreadyPresent:fileUrl];

    // For PE File vars when fileExists returns true, we are not calling downloadFiles for existing files
    // so we need to update file expiry time for those existing files.
    if (fileExists && updateExpiryTime) {
        [self updateFilesExpiry:@{url:@1}];
        [self updateFilesExpiryInPreference];
    }
    return fileExists;
}

- (void)clearFileAssets:(BOOL)expiredOnly {
    if (expiredOnly) {
        // Disregard the last deleted timestamp to force delete the expired files
        // currentTime - lastDeletedTime > self.fileExpiryTime
        long forceLastDeleted = ([self currentTimeInterval] - self.fileExpiryTime) - 1;
        [self removeInactiveExpiredAssets:forceLastDeleted];
    } else {
        [self removeAllAssetsWithCompletion:nil];
    }
}

- (nullable NSString *)fileDownloadPath:(NSString *)url {
    if ([self isFileAlreadyPresent:url andUpdateExpiryTime:NO]) {
        NSURL *fileURL = [NSURL URLWithString:url];
        return [self.fileDownloadManager filePath:fileURL];
    } else {
        CleverTapLogInternal(self.config.logLevel, @"%@ File %@ is not present.", self, url);
    }
    return nil;
}

- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL {
    NSURL *URL = [NSURL URLWithString:imageURL];
    NSString *imagePath = [self.fileDownloadManager filePath:URL];
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
    
#if !CLEVERTAP_NO_INAPP_SUPPORT
    [self removeLegacyAssets:nil];
#endif
    
    @synchronized (self) {
        NSDictionary *cachedUrlsExpiry = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
        if (cachedUrlsExpiry) {
            self.urlsExpiry = [cachedUrlsExpiry mutableCopy];
        } else {
            self.urlsExpiry = [NSMutableDictionary new];
        }
    }
    
    // Check for expired files and delete them at every start of session.
    long lastDeletedTime = [self lastDeletedTimestamp];
    [self removeInactiveExpiredAssets:lastDeletedTime];
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

- (void)removeAllAssetsWithCompletion:(void(^)(NSDictionary<NSString *,NSNumber *> *status))completion {
    [self.fileDownloadManager removeAllFilesWithCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
        [self.urlsExpiry removeAllObjects];
        [self updateFilesExpiryInPreference];
        [self updateLastDeletedTimestamp];
        if (completion) {
            completion(status);
        }
        CleverTapLogInternal(self.config.logLevel, @"%@ Remove all files completed with status: %@", self, status);
    }];
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

- (NSArray<NSURL *> *)fileURLs:(NSArray<NSString *> *)fileURLs {
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

- (long)lastDeletedTimestamp {
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

#if !CLEVERTAP_NO_INAPP_SUPPORT
- (void)removeLegacyAssets:(void (^)(void))completion {
    NSArray<NSString *> *activeAssetsArray = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]];
    NSArray<NSString *> *inactiveAssetsArray = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]];
    NSMutableSet<NSString *> *urls = [NSMutableSet new];
    if (activeAssetsArray && activeAssetsArray.count > 0) {
        [urls addObjectsFromArray:activeAssetsArray];
    }
    if (inactiveAssetsArray && inactiveAssetsArray.count > 0) {
        [urls addObjectsFromArray:inactiveAssetsArray];
    }
    
    if (!inactiveAssetsArray && !activeAssetsArray) {
        return;
    }
    
    dispatch_group_t deleteGroup = dispatch_group_create();
    dispatch_queue_t deleteConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    SDImageCache *sdImageCache = [SDImageCache sharedImageCache];
    for (NSString *url in urls) {
        dispatch_group_enter(deleteGroup);
        dispatch_async(deleteConcurrentQueue, ^{
            if ([sdImageCache diskImageDataExistsWithKey:url]) {
                [sdImageCache removeImageForKey:url
                                       fromDisk:YES
                                 withCompletion:^{
                    dispatch_group_leave(deleteGroup);
                }];
            } else {
                dispatch_group_leave(deleteGroup);
            }
        });
    }
    
    dispatch_group_notify(deleteGroup, deleteConcurrentQueue, ^{
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]];
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]];
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]];
        if (completion) {
            completion();
        }
    });
}
#endif

@end
