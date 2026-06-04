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
 * Completion handler for an image load. Mirrors SDWebImage's SDExternalCompletionBlock.
 * Called on the main thread after the load finishes (success or failure).
 *
 * @param image     The loaded image, or nil if the load failed.
 * @param error     The error if the load failed, otherwise nil.
 * @param cacheType Where the image came from (memory cache vs. network).
 * @param imageURL  The URL that was loaded.
 */
typedef void(^CTWebImageCompletionBlock)(UIImage * _Nullable image,
                                         NSError * _Nullable error,
                                         CTImageCacheType cacheType,
                                         NSURL * _Nullable imageURL);

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
 * Full-featured image loading with a completion handler.
 * Mirrors -[UIImageView sd_setImageWithURL:placeholderImage:options:completed:].
 *
 * The completion block is called on the main thread once the load finishes. On
 * failure, image is nil and error is non-nil, so callers can show a fallback.
 *
 * @param url         The remote image URL. If nil, the placeholder is shown and
 *                    the completion is called with an error.
 * @param placeholder Shown immediately while the image downloads. May be nil.
 * @param options     CTWebImageOptions bitmask (e.g. CTWebImageRetryFailed).
 * @param context     CTWebImageContext dictionary (e.g. CTWebImageContextStoreCacheType).
 * @param completedBlock Called on the main thread when the load finishes. May be nil.
 */
- (void)ct_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(CTWebImageOptions)options
                   context:(nullable CTWebImageContext *)context
                 completed:(nullable CTWebImageCompletionBlock)completedBlock;

/**
 * Cancels the current image-load operation for this image view.
 * Mirrors -[UIImageView sd_cancelCurrentImageLoad].
 * Call this in -prepareForReuse to prevent stale images appearing in recycled cells.
 */
- (void)ct_cancelCurrentImageLoad;

@end

NS_ASSUME_NONNULL_END
