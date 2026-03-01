//
//  CTWebImageCache.h
//  CleverTapSDK
//
//  Ported from SDWebImage's SDImageCache (memory layer only).
//  Key source references:
//    - storeImage:imageData:forKey:options:context:cacheType:completion: → SDImageCache.m:236–321
//    - imageFromMemoryCacheForKey:                                       → SDImageCache.m:440–442
//    - Memory cost (sd_memoryCost equivalent)                           → SDWebImage UIImage+Metadata
//    - Memory warning observer                                           → SDImageCache.m:127–131
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CTWebImageCache — singleton NSCache-backed memory image cache.
 *
 * Faithful port of SDImageCache's memory-only layer. The Inbox module uses
 * memory-only caching exclusively (SDWebImageContextStoreCacheType = SDImageCacheTypeMemory),
 * so disk persistence is intentionally not implemented.
 */
@interface CTWebImageCache : NSObject

/// Shared singleton. Mirrors [SDImageCache sharedImageCache].
+ (instancetype)sharedImageCache;

/**
 * Returns the image stored in the memory cache for the given key, or nil.
 * Mirrors SDImageCache.imageFromMemoryCacheForKey: (SDImageCache.m:440).
 * This method is synchronous and safe to call from any thread.
 */
- (nullable UIImage *)imageFromMemoryCacheForKey:(nullable NSString *)key;

/**
 * Returns the image stored in the memory cache (no disk check).
 * Mirrors SDImageCache.imageFromCacheForKey: when only memory is queried.
 */
- (nullable UIImage *)imageFromCacheForKey:(nullable NSString *)key;

/**
 * Stores the image in the memory cache under the given key.
 * Mirrors SDImageCache.storeImage:forKey:toDisk:completion: (SDImageCache.m:236–321).
 *
 * @param image      The image to cache (ignored if nil).
 * @param key        The cache key, typically the image URL absolute string.
 * @param toDisk     Ignored — disk caching is not implemented (inbox uses memory-only).
 * @param completion Optional block called on the calling queue when done.
 */
- (void)storeImage:(nullable UIImage *)image
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable void (^)(void))completionBlock;

/**
 * Removes all objects from the memory cache.
 * Mirrors [SDImageCache.memCache removeAllObjects] called on memory warning.
 */
- (void)clearMemory;

@end

NS_ASSUME_NONNULL_END
