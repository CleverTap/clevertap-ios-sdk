//
//  UIImageView+CTWebCache.swift
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

import UIKit

// Operation key — mirrors SDWebImage using NSStringFromClass as the operation key
// so that each UIImageView tracks exactly one image-load operation at a time.
private let kCTImageViewOperationKey = "UIImageView"

// ---------------------------------------------------------------------------
// Failed-URL blacklist — mirrors SDWebImageManager.failedURLs + failedURLsLock
// A URL is added when a download fails; removed when it succeeds.
// If CTWebImageRetryFailed is set in options, the blacklist is bypassed.
//
// The ObjC original lazily initialized these in +initialize. Swift file-scope
// `let` globals are lazily initialized exactly once in a thread-safe manner, so
// they replace the category +initialize cleanly.
// ---------------------------------------------------------------------------
private let ctFailedURLs = NSMutableSet()
private let ctFailedURLsLock = NSRecursiveLock()

// ---------------------------------------------------------------------------
// GIF magic bytes helper — "GIF8" (47 49 46 38), mirrors SDImageGIFCoder check
// ---------------------------------------------------------------------------
private func CTImageDataIsGIF(_ data: Data) -> Bool {
    if data.count < 4 { return false }
    // GIF87a = 47 49 46 38 37 61, GIF89a = 47 49 46 38 39 61
    let start = data.startIndex
    return data[start] == 0x47
        && data[start + 1] == 0x49
        && data[start + 2] == 0x46
        && data[start + 3] == 0x38
}

// ---------------------------------------------------------------------------
// Error domain for load failures surfaced through the completion handler.
// Mirrors the role of SDWebImageErrorDomain (callers only check for non-nil error).
// ---------------------------------------------------------------------------
private let kCTWebImageErrorDomain = "com.clevertap.CTWebImage"

private func CTWebImageError(_ code: Int, _ message: String?) -> NSError {
    return NSError(domain: kCTWebImageErrorDomain,
                   code: code,
                   userInfo: message != nil ? [NSLocalizedDescriptionKey: message!] : nil)
}

// Completion handler for an image load. Mirrors SDWebImage's SDExternalCompletionBlock /
// the ObjC CTWebImageCompletionBlock typedef. Called on the main thread after the load
// finishes (success or failure).
private typealias CTWebImageCompletionClosure = (UIImage?, Error?, CTImageCacheType, URL?) -> Void

/**
 * UIImageView category for async URL image loading.
 *
 * Mirrors UIImageView+WebCache from SDWebImage. Uses CTWebImageCache for memory
 * caching, CTWebImageOperation for cancellation, UIView+CTWebCacheOperation for
 * per-view operation tracking, and CTAnimatedImage for GIF decoding.
 */
extension UIImageView {

    // ---------------------------------------------------------------------------
    // Public API convenience overloads — mirror UIImageView+WebCache.m convenience methods
    // ---------------------------------------------------------------------------

    /// Load image from URL. Mirrors -[UIImageView sd_setImageWithURL:].
    @objc(ct_setImageWithURL:)
    public func ct_setImage(withURL url: URL?) {
        ct_setImage(withURL: url, placeholderImage: nil, options: 0, context: nil)
    }

    /// Load image from URL with a placeholder shown until the download completes.
    /// Mirrors -[UIImageView sd_setImageWithURL:placeholderImage:].
    @objc(ct_setImageWithURL:placeholderImage:)
    public func ct_setImage(withURL url: URL?, placeholderImage placeholder: UIImage?) {
        ct_setImage(withURL: url, placeholderImage: placeholder, options: 0, context: nil)
    }

    /// Full-featured image loading with options and context.
    /// Mirrors -[UIImageView sd_setImageWithURL:placeholderImage:options:context:].
    ///
    /// The `options`/`context` parameters use primitive types (`UInt` / `NSDictionary`)
    /// rather than the ObjC `CTWebImageOptions` / `CTWebImageContextOption` types so the
    /// generated `CleverTapSDK-Swift.h` does not need to import the framework umbrella.
    /// NS_OPTIONS is an NSUInteger typedef, so ObjC callers passing `CTWebImageRetryFailed`
    /// remain source-compatible; the real option type is reconstructed inside.
    @objc(ct_setImageWithURL:placeholderImage:options:context:)
    public func ct_setImage(withURL url: URL?,
                     placeholderImage placeholder: UIImage?,
                     options: UInt,
                     context: [AnyHashable: Any]?) {
        ct_internalSetImage(withURL: url,
                            placeholderImage: placeholder,
                            options: CTWebImageOptions(rawValue: options),
                            context: context,
                            completed: nil)
    }

    /// Full-featured image loading with a completion handler.
    /// Mirrors -[UIImageView sd_setImageWithURL:placeholderImage:options:completed:].
    ///
    /// The completion block's cache-type argument is `Int` (not `CTImageCacheType`) for the
    /// same umbrella-avoidance reason. NS_ENUM is an NSInteger typedef, so ObjC callers'
    /// `^(UIImage*, NSError*, CTImageCacheType, NSURL*)` blocks stay compatible.
    @objc(ct_setImageWithURL:placeholderImage:options:context:completed:)
    public func ct_setImage(withURL url: URL?,
                     placeholderImage placeholder: UIImage?,
                     options: UInt,
                     context: [AnyHashable: Any]?,
                     completed completedBlock: ((UIImage?, Error?, Int, URL?) -> Void)?) {
        let wrapped: CTWebImageCompletionClosure?
        if let completedBlock = completedBlock {
            wrapped = { image, error, cacheType, imageURL in
                completedBlock(image, error, cacheType.rawValue, imageURL)
            }
        } else {
            wrapped = nil
        }
        ct_internalSetImage(withURL: url,
                            placeholderImage: placeholder,
                            options: CTWebImageOptions(rawValue: options),
                            context: context,
                            completed: wrapped)
    }

    // ---------------------------------------------------------------------------
    // ct_cancelCurrentImageLoad — mirrors UIImageView+WebCache.m:74–76
    // ---------------------------------------------------------------------------

    /// Cancels the current image-load operation for this image view.
    /// Mirrors -[UIImageView sd_cancelCurrentImageLoad].
    @objc(ct_cancelCurrentImageLoad)
    public func ct_cancelCurrentImageLoad() {
        ct_cancelImageLoadOperation(withKey: kCTImageViewOperationKey)
    }

    // ---------------------------------------------------------------------------
    // ct_internalSetImageWithURL: — core loading logic.
    // Mirrors UIView+WebCache.m:sd_internalSetImageWithURL: and SDWebImageManager flow.
    // ---------------------------------------------------------------------------

    private func ct_internalSetImage(withURL url: URL?,
                                     placeholderImage placeholder: UIImage?,
                                     options: CTWebImageOptions,
                                     context: [AnyHashable: Any]?,
                                     completed completedBlock: CTWebImageCompletionClosure?) {

        // Helper: always deliver the completion on the main thread (mirrors SDWebImage,
        // which calls the external completion block on the main queue).
        let callCompletion: CTWebImageCompletionClosure = { image, error, cacheType, imageURL in
            guard let completedBlock = completedBlock else { return }
            if Thread.isMainThread {
                completedBlock(image, error, cacheType, imageURL)
            } else {
                DispatchQueue.main.async {
                    completedBlock(image, error, cacheType, imageURL)
                }
            }
        }

        // URL type safety (mirrors SDWebImageManager.loadImageWithURL: NSString/NSNull guard):
        // unnecessary here because `url` is statically typed `URL?` — a non-URL value cannot
        // reach this method through the typed Swift API, so the runtime coercion is omitted.

        // 1. Cancel any prior operation (mirrors sd_internalSetImageWithURL step 1)
        ct_cancelImageLoadOperation(withKey: kCTImageViewOperationKey)

        // 2. Show placeholder on main thread — mirrors dispatch_main_async_safe in SDWebImage.
        // Uses async (not sync) on the non-main path to avoid blocking the calling thread
        // and to prevent any risk of deadlock if the thread holds a resource the main thread needs.
        if Thread.isMainThread {
            self.image = placeholder
        } else {
            DispatchQueue.main.async {
                self.image = placeholder
            }
        }

        guard let url = url else {
            callCompletion(nil, CTWebImageError(-1, "Image URL is nil or invalid"), .none, nil)
            return
        }

        // 3. Failed-URL check — mirrors SDWebImageManager.loadImageWithURL (failedURLs logic)
        var isFailedURL = false
        ctFailedURLsLock.lock()
        isFailedURL = ctFailedURLs.contains(url)
        ctFailedURLsLock.unlock()
        if isFailedURL && !options.contains(.retryFailed) {
            // URL previously failed, and caller didn't ask to retry — skip
            callCompletion(nil, CTWebImageError(-2, "Image URL previously failed and is blacklisted"), .none, url)
            return
        }

        // 4. Memory cache check (synchronous) — mirrors SDWebImageManager callCacheProcessForOperation:
        let cacheKey = url.absoluteString
        if let cachedImage = CTWebImageCache.sharedImageCache().imageFromMemoryCache(forKey: cacheKey) {
            // Cache hit — set image immediately on main thread
            DispatchQueue.main.async {
                self.image = cachedImage
            }
            callCompletion(cachedImage, nil, .memory, url)
            return
        }

        // 5. Cache miss — start download. Mirrors SDWebImageManager callDownloadProcessForOperation:
        let operation = CTWebImageOperation()

        // Determine store cache type from context (mirrors SDWebImageManager's context reading)
        var storeCacheType: CTImageCacheType = .memory
        if let raw = context?[CTWebImageContextOption.storeCacheType.rawValue] as? Int,
           let resolved = CTImageCacheType(rawValue: raw) {
            storeCacheType = resolved
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let strongSelf = self else { return }

            // Bail if this operation was cancelled (mirrors SDWebImageCombinedOperation check)
            if operation.isCancelled { return }

            if let error = error {
                // Blacklist only permanent failures — mirrors SDWebImageDownloader(SDImageLoader)
                // shouldBlockFailedURLWithURL:error: (SDWebImageDownloader.m:644–663).
                // Transient errors (timeout, no connectivity, roaming, network loss, host not found,
                // cannot connect) must NOT blacklist the URL so the next attempt can succeed.
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain {
                    let code = nsError.code
                    let shouldBlock = (code != NSURLErrorCancelled
                                       && code != NSURLErrorTimedOut
                                       && code != NSURLErrorNotConnectedToInternet
                                       && code != NSURLErrorInternationalRoamingOff
                                       && code != NSURLErrorDataNotAllowed
                                       && code != NSURLErrorCannotFindHost
                                       && code != NSURLErrorCannotConnectToHost
                                       && code != NSURLErrorNetworkConnectionLost)
                    if shouldBlock {
                        ctFailedURLsLock.lock()
                        ctFailedURLs.add(url)
                        ctFailedURLsLock.unlock()
                    }
                }
                // Restore placeholder on failure
                DispatchQueue.main.async {
                    if !operation.isCancelled {
                        strongSelf.image = placeholder
                    }
                }
                callCompletion(nil, error, .none, url)
                return
            }

            // NSURLSession only reports a non-nil error for transport-layer failures
            // (no connection, timeout, TLS). An HTTP 4xx/5xx arrives with error == nil and
            // the error-page body in `data`, so without this check it would fall through to
            // decode and be mis-reported as a decode failure, and never get blacklisted.
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode >= 400 {
                    // Blacklist permanent client errors (4xx); leave 5xx retryable.
                    if statusCode < 500 {
                        ctFailedURLsLock.lock()
                        ctFailedURLs.add(url)
                        ctFailedURLsLock.unlock()
                    }
                    DispatchQueue.main.async {
                        if !operation.isCancelled {
                            strongSelf.image = placeholder
                        }
                    }
                    callCompletion(nil, CTWebImageError(statusCode, "HTTP request failed with status code \(statusCode)"), .none, url)
                    return
                }
            }

            // Download succeeded — remove from failed-URL set
            ctFailedURLsLock.lock()
            ctFailedURLs.remove(url)
            ctFailedURLsLock.unlock()

            // 5a. Decode image — GIF → CTAnimatedImage, everything else → UIImage
            // Mirrors SDWebImageManager's image transformation step.
            let image = strongSelf.ct_decodeImage(fromData: data, response: response)

            // 5b. Cache the decoded image — mirrors SDWebImageManager's store step.
            // CTWebImageCache is memory-only. SD skips memory when cacheType == Disk;
            // we mirror that by only writing when the type includes memory.
            // (SDImageCache.m storeImage:forKey:cacheType:completion: check)
            if let image = image {
                let storeToMemory = (storeCacheType == .memory || storeCacheType == .all)
                if storeToMemory {
                    CTWebImageCache.sharedImageCache().storeImage(image,
                                                                  forKey: cacheKey,
                                                                  toDisk: false,
                                                                  completion: nil)
                }
            }

            // 5c. Set the image on the view — mirrors UIView+WebCache's setImageBlock path
            DispatchQueue.main.async {
                if !operation.isCancelled {
                    strongSelf.image = image ?? placeholder
                }
            }

            // 5d. Deliver completion. If the data came back but could not be decoded,
            // report it as an error so callers can show a fallback (mirrors SDWebImage,
            // which calls completed with a decode error in this case).
            if let image = image {
                callCompletion(image, nil, .none, url)
            } else {
                callCompletion(nil, CTWebImageError(-3, "Downloaded data could not be decoded into an image"), .none, url)
            }
        }

        // Store the task in the operation so it can be cancelled
        operation.dataTask = task

        // Register the operation — mirrors UIView+WebCache sd_setImageLoadOperation:forKey:
        ct_setImageLoadOperation(operation, forKey: kCTImageViewOperationKey)

        task.resume()
    }

    // ---------------------------------------------------------------------------
    // ct_decodeImageFromData:response: — image decoding step.
    // Mirrors SDWebImageManager's image transform + GIF coder selection.
    // For GIFs: uses CTAnimatedImage (our CTGIFDecoder-backed port of SDAnimatedImage).
    // For all other types: uses standard UIImage.
    // ---------------------------------------------------------------------------

    private func ct_decodeImage(fromData data: Data?, response: URLResponse?) -> UIImage? {
        guard let data = data else { return nil }

        // Check MIME type from response header first, then fall back to magic bytes.
        // Mirrors how SDWebImageGIFCoder.canDecodeFromData works.
        var isGIF = false
        if let httpResponse = response as? HTTPURLResponse {
            isGIF = (httpResponse.mimeType == "image/gif")
        }
        if !isGIF {
            isGIF = CTImageDataIsGIF(data)
        }

        if isGIF {
            // Try to decode as animated GIF via CTAnimatedImage (port of SDAnimatedImage)
            if let gif = CTAnimatedImage(data: data) {
                return gif
            }
            // Fall through to UIImage if CTAnimatedImage decode fails
        }

        return UIImage(data: data)
    }
}
