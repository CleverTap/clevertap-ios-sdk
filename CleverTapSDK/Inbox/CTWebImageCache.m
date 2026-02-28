//
//  CTWebImageCache.m
//  CleverTapSDK
//
//  Ported from SDWebImage's SDImageCache (memory layer only).
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTWebImageCache.h"

// ---------------------------------------------------------------------------
// Memory cost helper — mirrors sd_memoryCost from UIImage+MemoryCacheCost.m
// SDWebImage: cost = width * scale * height * scale * frameCount
// For animated images (GIFs), multiplied by frame count so NSCache correctly
// accounts for the true memory footprint of all decoded frames.
// ---------------------------------------------------------------------------
static inline NSUInteger CTMemoryCostForImage(UIImage *image) {
    CGFloat scale = image.scale;
    NSUInteger singleFrameCost = (NSUInteger)(image.size.width * scale * image.size.height * scale);
    NSUInteger frameCount = image.images.count > 1 ? image.images.count : 1;
    return singleFrameCost * frameCount;
}

@implementation CTWebImageCache {
    NSCache *_memCache;
}

// ---------------------------------------------------------------------------
// Singleton — mirrors [SDImageCache sharedImageCache]
// ---------------------------------------------------------------------------

+ (instancetype)sharedImageCache {
    static CTWebImageCache *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _memCache = [[NSCache alloc] init];
        _memCache.name = @"com.clevertap.CTWebImageCache";

        // Mirror SDImageCache: clear on memory warning (SDImageCache.m:127–131)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// ---------------------------------------------------------------------------
// imageFromMemoryCacheForKey: — mirrors SDImageCache.m:440–442
// ---------------------------------------------------------------------------

- (nullable UIImage *)imageFromMemoryCacheForKey:(nullable NSString *)key {
    if (!key) return nil;
    return [_memCache objectForKey:key];
}

// ---------------------------------------------------------------------------
// imageFromCacheForKey: — memory-only query (mirrors SDImageCache queried with
// SDImageCacheTypeMemory, which is what the Inbox always uses)
// ---------------------------------------------------------------------------

- (nullable UIImage *)imageFromCacheForKey:(nullable NSString *)key {
    return [self imageFromMemoryCacheForKey:key];
}

// ---------------------------------------------------------------------------
// storeImage:forKey:toDisk:completion: — mirrors SDImageCache.m:236–321
// (only the memory store path; disk path is a no-op for Inbox usage)
// ---------------------------------------------------------------------------

- (void)storeImage:(nullable UIImage *)image
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable void (^)(void))completionBlock {
    if (!image || !key) {
        if (completionBlock) completionBlock();
        return;
    }

    // Store in memory — mirrors SDImageCache.m:259–265
    NSUInteger cost = CTMemoryCostForImage(image);
    [_memCache setObject:image forKey:key cost:cost];

    // toDisk:YES is intentionally not implemented — Inbox images are memory-only.
    // Mirrors the early-return path in SDImageCache when cacheType == SDImageCacheTypeMemory.
    if (completionBlock) completionBlock();
}

// ---------------------------------------------------------------------------
// clearMemory — mirrors SDImageCache's UIApplicationDidReceiveMemoryWarningNotification handler
// ---------------------------------------------------------------------------

- (void)clearMemory {
    [_memCache removeAllObjects];
}

@end
