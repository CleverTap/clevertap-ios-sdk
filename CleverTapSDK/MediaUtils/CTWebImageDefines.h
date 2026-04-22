//
//  CTWebImageDefines.h
//  CleverTapSDK
//
//  Ported from SDWebImage's SDWebImageDefine.h + SDImageCacheDefine.h (iOS path only).
//  Defines the minimal subset of SDWebImage options and context keys used by the Inbox module.
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// ---------------------------------------------------------------------------
// CTWebImageOptions — mirrors SDWebImageOptions (subset used by Inbox)
// ---------------------------------------------------------------------------

typedef NS_OPTIONS(NSUInteger, CTWebImageOptions) {
    /**
     * By default, when a URL fails to load it is blacklisted so it will not be
     * retried. This flag disables that blacklisting. Mirrors SDWebImageRetryFailed.
     */
    CTWebImageRetryFailed = 1 << 0,
};

// ---------------------------------------------------------------------------
// CTImageCacheType — mirrors SDImageCacheType
// ---------------------------------------------------------------------------

typedef NS_ENUM(NSInteger, CTImageCacheType) {
    /// Image not available in cache
    CTImageCacheTypeNone   = 0,
    /// Image was obtained from the on-disk cache. Mirrors SDImageCacheTypeDisk = 1.
    CTImageCacheTypeDisk   = 1,
    /// Image was obtained from the in-memory cache. Mirrors SDImageCacheTypeMemory = 2.
    CTImageCacheTypeMemory = 2,
    /// Image was obtained from either memory or disk cache
    CTImageCacheTypeAll    = 3,
};

// ---------------------------------------------------------------------------
// CTWebImageContextOption — mirrors SDWebImageContextOption
// ---------------------------------------------------------------------------

typedef NSString * CTWebImageContextOption NS_STRING_ENUM;

/**
 * A CTImageCacheType NSNumber value specifying where to store the image after
 * it is downloaded. Mirrors SDWebImageContextStoreCacheType.
 * Default: CTImageCacheTypeMemory.
 */
FOUNDATION_EXPORT CTWebImageContextOption const CTWebImageContextStoreCacheType;

// ---------------------------------------------------------------------------
// CTWebImageContext — mirrors SDWebImageContext
// ---------------------------------------------------------------------------

typedef NSDictionary<CTWebImageContextOption, id> CTWebImageContext;
typedef NSMutableDictionary<CTWebImageContextOption, id> CTMutableWebImageContext;

NS_ASSUME_NONNULL_END
