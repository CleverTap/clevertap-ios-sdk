#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTInAppImagePrefetchManager.h"
#import "CTMultiDelegateManager.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageManager.h>

static const NSInteger kDefaultInAppExpiryTime = 60 * 60 * 24 * 7 * 2; // 2 weeks

@interface CTInAppImagePrefetchManager()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, assign) SDWebImageOptions sdWebImageOptions;
@property (nonatomic, strong) SDWebImageContext *sdWebImageContext;
@property (nonatomic, strong) SDWebImageManager *sdWebImageManager;
@property (nonatomic, strong) SDImageCache *sdImageCache;
@property (nonatomic, strong) NSMutableSet<NSString *> *activeImageSet;
@property (nonatomic, strong) NSMutableSet<NSString *> *inactiveImageSet;
@property (nonatomic) NSTimeInterval inAppExpiryTime;

@end

@implementation CTInAppImagePrefetchManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;

        [self setup];
    }
    
    return self;
}

#pragma mark - Public

- (void)preloadClientSideInAppImages:(NSArray *)csInAppNotifs {
    if (csInAppNotifs.count == 0) return;

    NSArray<NSString *> *mediaURLs = [self getImageURLs:csInAppNotifs];
    [self prefetchURLs:mediaURLs];
}

- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL {
    UIImage *image = [self.sdImageCache imageFromDiskCacheForKey:imageURL];
    if (image) return image;
    
    CleverTapLogInternal(self.config.logLevel, @"%@: Image not found in Disk Cache for URL: %@", self, imageURL);
    return nil;
}

- (void)setImageAssetsInactiveAndClearExpired {
    // Move all active image url to inactive and store it in preference.
    // Images will be deleted from Disk cache when expiration check is done.
    // Check for expired images, if any delete them from disk cache.
    [self moveAssetsToInactive];

    if ([self.inactiveImageSet allObjects].count > 0) {
        long lastDeletedTime = [self getLastDeletedTimestamp];
        [self removeInactiveExpiredAssets:lastDeletedTime];
    }
}

- (void)_clearImageAssets:(BOOL)expiredOnly {
    // When expiredOnly is true, delete inapp images from disk cache which are present in inactive set.
    // When expiredOnly is false, delete all inapp images from disk cache for current user.
    long lastDeletedTime = [self getLastDeletedTimestamp];
    if (!expiredOnly) {
        [self moveAssetsToInactive];
        lastDeletedTime = ([self getLastDeletedTimestamp] - (kDefaultInAppExpiryTime + 1));
    }

    if ([self.inactiveImageSet allObjects].count > 0) {
        [self removeInactiveExpiredAssets:lastDeletedTime];
    }
}

#pragma mark - Private

- (void)setup {
    self.inAppExpiryTime = kDefaultInAppExpiryTime;
    self.activeImageSet = [NSMutableSet new];
    self.inactiveImageSet = [NSMutableSet new];
    
    [self addActiveImageAssets];
    [self addInactiveImageAssets];
    
    self.sdWebImageOptions = (SDWebImageRetryFailed);
    self.sdWebImageContext = @{SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)};
    self.sdWebImageManager = [SDWebImageManager sharedManager];
    self.sdImageCache = [SDImageCache sharedImageCache];
    // Setting this to a negative value means no expiring. We will handle expired images at our side.
    [[self.sdImageCache config] setMaxDiskAge:-1];
}

- (void)prefetchURLs:(NSArray<NSString *> *)mediaURLs {
    if (mediaURLs.count == 0) return;

    // Download the images which are not present in Disk cache.
    // Steps:
    // 1. Check if new image url is present in inactiveImageSet
    // 2. If present move image url to activeImageSet, else download and add it to activeImageSet
    // 3. Check for expired images in inactiveImageSet when all images are downloaded
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (NSString *url in mediaURLs) {
        // Check if image is present in disk cache or not.
        // If present, add the url in `activeImageSet` and remove from `inactiveImageSet` if present.
        UIImage *image = [self loadImageFromDisk:url];
        if (image) {
            [self.activeImageSet addObject:url];
            if ([self.inactiveImageSet containsObject:url]) {
                [self.inactiveImageSet removeObject:url];
            }
        } else {
            dispatch_group_enter(group);
            dispatch_async(concurrentQueue, ^{
                [self.sdWebImageManager loadImageWithURL:[NSURL URLWithString:url]
                                                 options:self.sdWebImageOptions
                                                 context:self.sdWebImageContext
                                                progress:nil
                                               completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                    if (image) {
                        [self.activeImageSet addObject:imageURL.absoluteString];
                    }
                    dispatch_group_leave(group);
                }];
            });
        }
    }
    dispatch_group_notify(group, concurrentQueue, ^{
        // This block will be executed when all images are prefetched.
        [self updateImageAssetsInPreference];
        long lastDeletedTime = [self getLastDeletedTimestamp];
        [self removeInactiveExpiredAssets:lastDeletedTime];
    });
}

- (void)removeInactiveExpiredAssets:(long)lastDeletedTime {
    // Remove the images which are in inactive asset set and over default expiration period.
    // Steps:
    // 1. Initially set the lastDeletedTime as current time(first time)
    // 2. Check if lastDeletedTime + default expiry time has passed
    // 3. Delete all images from inactive asset
    // 4. Update lastDeletedTime as currentTime and image assets in preference
    dispatch_group_t deleteGroup = dispatch_group_create();
    dispatch_queue_t deleteConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if (lastDeletedTime > 0) {
        long currentTime = (long) [[NSDate date] timeIntervalSince1970];
        if (currentTime - lastDeletedTime > self.inAppExpiryTime) {
            // Delete all inactive expired images.
            NSArray<NSString *> *inactiveAsset = [self.inactiveImageSet allObjects];
            for (NSString *url in inactiveAsset) {
                dispatch_group_enter(deleteGroup);
                dispatch_async(deleteConcurrentQueue, ^{
                    [self.sdImageCache removeImageForKey:url
                                                fromDisk:YES
                                          withCompletion:^{
                        [self.inactiveImageSet removeObject:url];
                        dispatch_group_leave(deleteGroup);
                    }];
                });
            }
            CleverTapLogInternal(self.config.logLevel, @"%@: Expired Images are removed from disk cache", self);
            dispatch_group_notify(deleteGroup, deleteConcurrentQueue, ^{
                // This block will be executed when all images are removed.
                if ([self.inactiveImageSet allObjects].count == 0) {
                    // Move all images to inactive for the new expiration window
                    [self moveAssetsToInactive];
                    // Update last deleted time only when all inactive images are deleted
                    [self updateLastDeletedTimestamp];
                }
            });
        }
    }
}

- (NSArray<NSString *> *)getImageURLs:(NSArray *)csInAppNotifs {
    NSMutableSet<NSString *> *mediaURLs = [NSMutableSet new];
    for (NSDictionary *jsonInApp in csInAppNotifs) {
        NSDictionary *media = (NSDictionary*) jsonInApp[@"media"];
        if (media) {
            NSString *imageURL = [self getURLFromDictionary:media];
            if (imageURL) {
                [mediaURLs addObject:imageURL];
            }
        }
        NSDictionary *mediaLandscape = (NSDictionary*) jsonInApp[@"mediaLandscape"];
        if (mediaLandscape) {
            NSString *imageURL = [self getURLFromDictionary:mediaLandscape];
            if (imageURL) {
                [mediaURLs addObject:imageURL];
            }
        }
    }
    return [mediaURLs allObjects];
}

- (NSString *)getURLFromDictionary:(NSDictionary *)media {
    NSString *contentType = media[@"content_type"];
    NSString *mediaUrl = media[@"url"];
    if (mediaUrl && mediaUrl.length > 0) {
        // Preload contentType with image/jpeg or image/gif
        if ([contentType hasPrefix:@"image"]) {
            return mediaUrl;
        }
    }
    return nil;
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

- (long)getLastDeletedTimestamp {
    long now = (long) [[NSDate date] timeIntervalSince1970];
    long lastDeletedTime = [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]
                                           withResetValue:now];
    return lastDeletedTime;
}

- (void)updateLastDeletedTimestamp {
    long now = (long) [[NSDate date] timeIntervalSince1970];
    [CTPreferences putInt:now
                   forKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]];
}

- (void)moveAssetsToInactive {
    [self.inactiveImageSet unionSet:self.activeImageSet];
    self.activeImageSet = [NSMutableSet new];
    [self updateImageAssetsInPreference];
}

- (void)addInactiveImageAssets {
    // Add only inactive array from preferences in `inactiveImageSet`
    NSArray<NSString *> *inactiveAssetsArray = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]];
    [self.inactiveImageSet addObjectsFromArray:inactiveAssetsArray];
}

- (void)addActiveImageAssets {
    // Add only active array from preferences in `activeImageSet`
    NSArray<NSString *> *activeAssetsArray = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]];
    [self.activeImageSet addObjectsFromArray:activeAssetsArray];
}

- (void)updateImageAssetsInPreference {
    [CTPreferences putObject:[self.activeImageSet allObjects]
                      forKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]];
    [CTPreferences putObject:[self.inactiveImageSet allObjects]
                      forKey:[self storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]];
}

@end
