//
//  UIImageView+CTWebCache.m
//  CleverTapSDK
//
//  Ported from SDWebImage's UIImageView+WebCache.m and UIView+WebCache.m.
//  Key source references:
//    - sd_setImageWithURL:placeholderImage:options:context:progress:completed:
//                                           → UIImageView+WebCache.m:49–66
//    - sd_internalSetImageWithURL:...       → UIView+WebCache.m (core loading logic)
//    - sd_cancelCurrentImageLoad            → UIImageView+WebCache.m:74–76
//    - failedURLs / failedURLsLock          → SDWebImageManager.m (failed URL blacklisting)
//    - GIF detection                        → SDImageGIFCoder (checks GIF magic bytes)
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "UIImageView+CTWebCache.h"
#import "UIView+CTWebCacheOperation.h"
#import "CTWebImageCache.h"
#import "CTWebImageOperation.h"
#import "CTAnimatedImage.h"

// Operation key — mirrors SDWebImage using NSStringFromClass as the operation key
// so that each UIImageView tracks exactly one image-load operation at a time.
static NSString * const kCTImageViewOperationKey = @"UIImageView";

// ---------------------------------------------------------------------------
// Failed-URL blacklist — mirrors SDWebImageManager.failedURLs + failedURLsLock
// A URL is added when a download fails; removed when it succeeds.
// If CTWebImageRetryFailed is set in options, the blacklist is bypassed.
// ---------------------------------------------------------------------------
static NSMutableSet<NSURL *> *_failedURLs;
static NSRecursiveLock *_failedURLsLock;

// ---------------------------------------------------------------------------
// GIF magic bytes helper — "GIF8" (47 49 46 38), mirrors SDImageGIFCoder check
// ---------------------------------------------------------------------------
static inline BOOL CTImageDataIsGIF(NSData *data) {
    if (data.length < 4) return NO;
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    // GIF87a = 47 49 46 38 37 61, GIF89a = 47 49 46 38 39 61
    return (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38);
}

@implementation UIImageView (CTWebCache)

// ---------------------------------------------------------------------------
// Class setup
// ---------------------------------------------------------------------------

+ (void)initialize {
    if (self == [UIImageView class]) {
        _failedURLs = [NSMutableSet new];
        _failedURLsLock = [NSRecursiveLock new];
    }
}

// ---------------------------------------------------------------------------
// Public API convenience overloads — mirror UIImageView+WebCache.m convenience methods
// ---------------------------------------------------------------------------

- (void)ct_setImageWithURL:(nullable NSURL *)url {
    [self ct_setImageWithURL:url placeholderImage:nil options:0 context:nil];
}

- (void)ct_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder {
    [self ct_setImageWithURL:url placeholderImage:placeholder options:0 context:nil];
}

- (void)ct_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(CTWebImageOptions)options
                   context:(nullable CTWebImageContext *)context {
    [self ct_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:context];
}

// ---------------------------------------------------------------------------
// ct_cancelCurrentImageLoad — mirrors UIImageView+WebCache.m:74–76
// ---------------------------------------------------------------------------

- (void)ct_cancelCurrentImageLoad {
    [self ct_cancelImageLoadOperationWithKey:kCTImageViewOperationKey];
}

// ---------------------------------------------------------------------------
// ct_internalSetImageWithURL: — core loading logic.
// Mirrors UIView+WebCache.m:sd_internalSetImageWithURL: and SDWebImageManager flow.
// ---------------------------------------------------------------------------

- (void)ct_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(CTWebImageOptions)options
                           context:(nullable CTWebImageContext *)context {

    // URL type safety — mirrors SDWebImageManager.loadImageWithURL: (SDWebImageManager.m:199–206).
    // Very common mistake is to pass an NSString instead of NSURL; Xcode won't warn for this mismatch.
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    // Prevents crash when NSNull or other unexpected type is passed
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }

    // 1. Cancel any prior operation (mirrors sd_internalSetImageWithURL step 1)
    [self ct_cancelImageLoadOperationWithKey:kCTImageViewOperationKey];

    // 2. Show placeholder on main thread — mirrors dispatch_main_async_safe in SDWebImage.
    // Uses async (not sync) on the non-main path to avoid blocking the calling thread
    // and to prevent any risk of deadlock if the thread holds a resource the main thread needs.
    if ([NSThread isMainThread]) {
        self.image = placeholder;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = placeholder;
        });
    }

    if (!url) {
        return;
    }

    // 3. Failed-URL check — mirrors SDWebImageManager.loadImageWithURL (failedURLs logic)
    BOOL isFailedURL = NO;
    if (url) {
        [_failedURLsLock lock];
        isFailedURL = [_failedURLs containsObject:url];
        [_failedURLsLock unlock];
    }
    if (isFailedURL && !(options & CTWebImageRetryFailed)) {
        // URL previously failed, and caller didn't ask to retry — skip
        return;
    }

    // 4. Memory cache check (synchronous) — mirrors SDWebImageManager callCacheProcessForOperation:
    NSString *cacheKey = url.absoluteString;
    UIImage *cachedImage = [[CTWebImageCache sharedImageCache] imageFromMemoryCacheForKey:cacheKey];
    if (cachedImage) {
        // Cache hit — set image immediately on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = cachedImage;
        });
        return;
    }

    // 5. Cache miss — start download. Mirrors SDWebImageManager callDownloadProcessForOperation:
    CTWebImageOperation *operation = [CTWebImageOperation new];

    // Determine store cache type from context (mirrors SDWebImageManager's context reading)
    CTImageCacheType storeCacheType = CTImageCacheTypeMemory;
    NSNumber *storeTypeNumber = context[CTWebImageContextStoreCacheType];
    if (storeTypeNumber) {
        storeCacheType = (CTImageCacheType)storeTypeNumber.integerValue;
    }

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithURL:url
      completionHandler:^(NSData * _Nullable data,
                          NSURLResponse * _Nullable response,
                          NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        // Bail if this operation was cancelled (mirrors SDWebImageCombinedOperation check)
        if (operation.isCancelled) return;

        if (error) {
            // Blacklist only permanent failures — mirrors SDWebImageDownloader(SDImageLoader)
            // shouldBlockFailedURLWithURL:error: (SDWebImageDownloader.m:644–663).
            // Transient errors (timeout, no connectivity, roaming, network loss, host not found,
            // cannot connect) must NOT blacklist the URL so the next attempt can succeed.
            if (url && [error.domain isEqualToString:NSURLErrorDomain]) {
                BOOL shouldBlock = (error.code != NSURLErrorCancelled
                                    && error.code != NSURLErrorTimedOut
                                    && error.code != NSURLErrorNotConnectedToInternet
                                    && error.code != NSURLErrorInternationalRoamingOff
                                    && error.code != NSURLErrorDataNotAllowed
                                    && error.code != NSURLErrorCannotFindHost
                                    && error.code != NSURLErrorCannotConnectToHost
                                    && error.code != NSURLErrorNetworkConnectionLost);
                if (shouldBlock) {
                    [_failedURLsLock lock];
                    [_failedURLs addObject:url];
                    [_failedURLsLock unlock];
                }
            }
            // Restore placeholder on failure
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!operation.isCancelled) {
                    strongSelf.image = placeholder;
                }
            });
            return;
        }

        // Download succeeded — remove from failed-URL set
        if (url) {
            [_failedURLsLock lock];
            [_failedURLs removeObject:url];
            [_failedURLsLock unlock];
        }

        // 5a. Decode image — GIF → CTAnimatedImage, everything else → UIImage
        // Mirrors SDWebImageManager's image transformation step.
        UIImage *image = [strongSelf ct_decodeImageFromData:data response:response];

        // 5b. Cache the decoded image — mirrors SDWebImageManager's store step.
        // CTWebImageCache is memory-only. SD skips memory when cacheType == Disk;
        // we mirror that by only writing when the type includes memory.
        // (SDImageCache.m storeImage:forKey:cacheType:completion: check)
        if (image && cacheKey) {
            BOOL storeToMemory = (storeCacheType == CTImageCacheTypeMemory ||
                                  storeCacheType == CTImageCacheTypeAll);
            if (storeToMemory) {
                [[CTWebImageCache sharedImageCache] storeImage:image
                                                        forKey:cacheKey
                                                        toDisk:NO
                                                    completion:nil];
            }
        }

        // 5c. Set the image on the view — mirrors UIView+WebCache's setImageBlock path
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!operation.isCancelled) {
                strongSelf.image = image ?: placeholder;
            }
        });
    }];

    // Store the task in the operation so it can be cancelled
    operation.dataTask = task;

    // Register the operation — mirrors UIView+WebCache sd_setImageLoadOperation:forKey:
    [self ct_setImageLoadOperation:operation forKey:kCTImageViewOperationKey];

    [task resume];
}

// ---------------------------------------------------------------------------
// ct_decodeImageFromData:response: — image decoding step.
// Mirrors SDWebImageManager's image transform + GIF coder selection.
// For GIFs: uses CTAnimatedImage (our CTGIFDecoder-backed port of SDAnimatedImage).
// For all other types: uses standard UIImage.
// ---------------------------------------------------------------------------

- (nullable UIImage *)ct_decodeImageFromData:(nullable NSData *)data
                                    response:(nullable NSURLResponse *)response {
    if (!data) return nil;

    // Check MIME type from response header first, then fall back to magic bytes.
    // Mirrors how SDWebImageGIFCoder.canDecodeFromData works.
    BOOL isGIF = NO;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSString *mimeType = ((NSHTTPURLResponse *)response).MIMEType;
        isGIF = [mimeType isEqualToString:@"image/gif"];
    }
    if (!isGIF) {
        isGIF = CTImageDataIsGIF(data);
    }

    if (isGIF) {
        // Try to decode as animated GIF via CTAnimatedImage (port of SDAnimatedImage)
        CTAnimatedImage *gif = [CTAnimatedImage imageWithData:data];
        if (gif) return gif;
        // Fall through to UIImage if CTAnimatedImage decode fails
    }

    return [UIImage imageWithData:data];
}

@end
