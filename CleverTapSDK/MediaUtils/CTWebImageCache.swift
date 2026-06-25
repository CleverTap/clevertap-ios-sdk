//
//  CTWebImageCache.swift
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

import UIKit

/// CTWebImageCache — singleton NSCache-backed memory image cache.
///
/// Faithful port of SDImageCache's memory-only layer. The Inbox module uses
/// memory-only caching exclusively (SDWebImageContextStoreCacheType = SDImageCacheTypeMemory),
/// so disk persistence is intentionally not implemented.
@objc(CTWebImageCache)
@objcMembers
public final class CTWebImageCache: NSObject {

    private let memCache = NSCache<NSString, UIImage>()

    // ---------------------------------------------------------------------------
    // Singleton — mirrors [SDImageCache sharedImageCache]
    // ---------------------------------------------------------------------------

    private static let sharedInstance = CTWebImageCache()

    /// Shared singleton. Mirrors [SDImageCache sharedImageCache].
    public class func sharedImageCache() -> CTWebImageCache {
        return sharedInstance
    }

    override init() {
        super.init()
        memCache.name = "com.clevertap.CTWebImageCache"

        // Mirror SDImageCache: clear on memory warning (SDImageCache.m:127–131)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(clearMemory),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // ---------------------------------------------------------------------------
    // imageFromMemoryCacheForKey: — mirrors SDImageCache.m:440–442
    // ---------------------------------------------------------------------------

    func imageFromMemoryCache(forKey key: String?) -> UIImage? {
        guard let key = key else { return nil }
        return memCache.object(forKey: key as NSString)
    }

    // ---------------------------------------------------------------------------
    // imageFromCacheForKey: — memory-only query (mirrors SDImageCache queried with
    // SDImageCacheTypeMemory, which is what the Inbox always uses)
    // ---------------------------------------------------------------------------

    public func imageFromCache(forKey key: String?) -> UIImage? {
        return imageFromMemoryCache(forKey: key)
    }

    // ---------------------------------------------------------------------------
    // storeImage:forKey:toDisk:completion: — mirrors SDImageCache.m:236–321
    // (only the memory store path; disk path is a no-op for Inbox usage)
    // ---------------------------------------------------------------------------

    public func storeImage(_ image: UIImage?,
                    forKey key: String?,
                    toDisk: Bool,
                    completion completionBlock: (() -> Void)?) {
        guard let image = image, let key = key else {
            completionBlock?()
            return
        }

        // Store in memory — mirrors SDImageCache.m:259–265
        let cost = CTMemoryCostForImage(image)
        memCache.setObject(image, forKey: key as NSString, cost: cost)

        // toDisk:YES is intentionally not implemented — Inbox images are memory-only.
        // Mirrors the early-return path in SDImageCache when cacheType == SDImageCacheTypeMemory.
        completionBlock?()
    }

    // ---------------------------------------------------------------------------
    // clearMemory — mirrors SDImageCache's UIApplicationDidReceiveMemoryWarningNotification handler
    // ---------------------------------------------------------------------------

    func clearMemory() {
        memCache.removeAllObjects()
    }
}

// ---------------------------------------------------------------------------
// Memory cost helper — mirrors SDMemoryCacheCostForImage from UIImage+MemoryCacheCost.m
// SDWebImage: cost = CGImageGetBytesPerRow * CGImageGetHeight (real bytes), × deduped frameCount.
// Using actual bytes per row is more accurate than pixel_count because it accounts for
// row padding (e.g. 16-byte alignment) and the true bitsPerPixel of the CGImage.
// NSSet deduplication mirrors SD's handling of _UIAnimatedImage where the same frame
// object can appear multiple times in image.images.
// ---------------------------------------------------------------------------
private func CTMemoryCostForImage(_ image: UIImage) -> Int {
    guard let imageRef = image.cgImage else {
        return 0
    }
    let bytesPerFrame = imageRef.bytesPerRow * imageRef.height
    // Filter duplicate frame references — mirrors SDMemoryCacheCostForImage
    let frameCount = (image.images?.count ?? 0) > 1 ? Set(image.images ?? []).count : 1
    return bytesPerFrame * frameCount
}
