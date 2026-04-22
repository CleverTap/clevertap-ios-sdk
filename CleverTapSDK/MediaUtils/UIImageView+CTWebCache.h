//
//  UIImageView+CTWebCache.h
//  CleverTapSDK
//
//  Ported from SDWebImage's UIImageView+WebCache and UIView+WebCache (sd_internalSetImageWithURL:).
//  Provides URL-based image loading with memory caching and GIF support, using only
//  CT-prefixed classes to eliminate the SDWebImage dependency for the Inbox module.
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTWebImageDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * UIImageView category for async URL image loading.
 *
 * Mirrors UIImageView+WebCache from SDWebImage. Uses CTWebImageCache for memory
 * caching, CTWebImageOperation for cancellation, UIView+CTWebCacheOperation for
 * per-view operation tracking, and CTAnimatedImage for GIF decoding.
 */
@interface UIImageView (CTWebCache)

/**
 * Load image from URL. Mirrors -[UIImageView sd_setImageWithURL:].
 */
- (void)ct_setImageWithURL:(nullable NSURL *)url;

/**
 * Load image from URL with a placeholder shown until the download completes.
 * Mirrors -[UIImageView sd_setImageWithURL:placeholderImage:].
 */
- (void)ct_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder;

/**
 * Full-featured image loading with options and context.
 * Mirrors -[UIImageView sd_setImageWithURL:placeholderImage:options:context:].
 *
 * @param url         The remote image URL. If nil, the placeholder is shown and loading stops.
 * @param placeholder Shown immediately while the image downloads. May be nil.
 * @param options     CTWebImageOptions bitmask (e.g. CTWebImageRetryFailed).
 * @param context     CTWebImageContext dictionary (e.g. CTWebImageContextStoreCacheType).
 */
- (void)ct_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(CTWebImageOptions)options
                   context:(nullable CTWebImageContext *)context;

/**
 * Cancels the current image-load operation for this image view.
 * Mirrors -[UIImageView sd_cancelCurrentImageLoad].
 * Call this in -prepareForReuse to prevent stale images appearing in recycled cells.
 */
- (void)ct_cancelCurrentImageLoad;

@end

NS_ASSUME_NONNULL_END
