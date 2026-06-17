/*
 * CTGIFDecoder
 * Ported from SDWebImage's SDImageIOAnimatedCoder + SDImageGIFCoder.
 *
 * Key SDWebImage source references:
 *   - frameDurationAtIndex:source:      → SDImageIOAnimatedCoder.m:416–446
 *   - imageLoopCountWithSource:         → SDImageIOAnimatedCoder.m:403–413
 *   - createFrameAtIndex:source:...     → SDImageIOAnimatedCoder.m:448–570
 *   - initWithAnimatedImageData:options → SDImageIOAnimatedCoder.m:994–1066
 *   - SDCGImageCreateMutableCopy        → SDImageIOAnimatedCoder.m:40–54
 *   - didReceiveMemoryWarning:          → SDImageIOAnimatedCoder.m:314–320
 *   - GIF property keys                 → SDImageGIFCoder.m:38–56
 *
 * Provides per-frame access to an animated image. Conforms to CTAnimatedImageProviding.
 * Decodes GIF frames lazily using the ImageIO framework.
 */

import UIKit
import ImageIO

@objc(CTGIFDecoder)
@objcMembers
final class CTGIFDecoder: NSObject {

    private(set) var frameCount: Int = 0
    private(set) var loopCount: Int = 0

    private var imageSource: CGImageSource?
    // Serializes all access to imageSource. CGImageSource is not thread-safe:
    // frameAtIndex: decodes on a background queue (CTImageFramePool.fetchQueue) while
    // didReceiveMemoryWarning: purges ImageIO's cache on the main thread. Mirrors
    // SDImageIOAnimatedCoder which guards _imageSource with SD_LOCK(_lock) (a dispatch_semaphore).
    private let lock = DispatchSemaphore(value: 1)
    private var imageData: Data?
    // Scale factor applied to each decoded UIImage frame.
    // Mirrors SDImageIOAnimatedCoder which passes scale to UIImage initWithCGImage:scale:orientation:.
    private var scale: CGFloat = 1
    // Lightweight per-frame duration storage — mirrors SDImageIOCoderFrame (index+duration only).
    // SDImageIOAnimatedCoder.scanAndCheckFramesValidWithImageSource: (line 1076) uses a private
    // SDImageIOCoderFrame with only `index` and `duration`; no UIImage placeholder is allocated
    // during the scan phase (images are decoded lazily in frameAtIndex:).
    private var frameDurations: [Double] = [] // per-frame duration in seconds

    @available(*, unavailable)
    override init() {
        fatalError("init() is unavailable; use init(data:) / init(data:scale:)")
    }

    // Mirrors SDAnimatedImage.initWithData: → initWithData:scale:1.
    // Scale defaults to 1.0 for raw data (same as SD; file-based loading would derive scale from filename).
    convenience init?(data: Data) {
        self.init(data: data, scale: 1)
    }

    // Mirrors SDImageIOAnimatedCoder.initWithAnimatedImageData:options: (line 994).
    // The scale is stored and applied per-frame in frameAtIndex: so UIImage reports the correct
    // logical size (matching SDImageIOAnimatedCoder.createFrameAtIndex:…:scale: line 576).
    init?(data: Data, scale: CGFloat) {
        super.init()
        if data.isEmpty { return nil }
        self.scale = max(scale, 1)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let valid = scanFrames(from: source)
        if !valid {
            return nil
        }
        imageSource = source
        imageData = data

        // Register for memory warnings to purge ImageIO's internal per-frame decode cache.
        // Mirrors SDImageIOAnimatedCoder.initWithAnimatedImageData:options: (line 1062).
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning(_:)),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }

    deinit {
        // Mirrors SDImageIOAnimatedCoder.dealloc — remove observer before releasing source.
        // The CGImageSource is released automatically by ARC (Swift manages CoreFoundation lifetimes).
        NotificationCenter.default.removeObserver(self)
    }

    // Mirrors SDImageIOAnimatedCoder.didReceiveMemoryWarning: (SDImageIOAnimatedCoder.m:314–320).
    // Calls CGImageSourceRemoveCacheAtIndex for every frame so ImageIO releases its internal
    // per-frame CGImage decode cache, reducing memory pressure during low-memory conditions.
    func didReceiveMemoryWarning(_ notification: Notification) {
        // Mirrors SDImageIOAnimatedCoder.didReceiveMemoryWarning:, which wraps this in SD_LOCK(_lock).
        lock.wait()
        if let imageSource = imageSource {
            for i in 0..<frameCount {
                CGImageSourceRemoveCacheAtIndex(imageSource, i)
            }
        }
        lock.signal()
    }

    // Mirrors SDImageIOAnimatedCoder.scanAndCheckFramesValidWithImageSource: (line 1068).
    // Uses lightweight NSNumber-boxed durations instead of full CTImageFrame objects,
    // matching SD's SDImageIOCoderFrame which only stores index + duration (no UIImage).
    private func scanFrames(from source: CGImageSource) -> Bool {
        let count = CGImageSourceGetCount(source)
        if count == 0 { return false }

        loopCount = CTGIFDecoder.loopCount(from: source)
        frameCount = count

        var durations = [Double]()
        durations.reserveCapacity(count)
        for i in 0..<count {
            let duration = CTGIFDecoder.frameDuration(at: i, source: source)
            durations.append(duration)
        }
        if durations.count != count { return false }
        frameDurations = durations
        return true
    }

    // Mirrors SDImageGIFCoder.defaultLoopCount = 1 and SDImageIOAnimatedCoder.imageLoopCountWithSource: (line 403).
    private static func loopCount(from source: CGImageSource) -> Int {
        var loopCount = 1 // GIF default (SDImageGIFCoder.defaultLoopCount)
        guard let properties = CGImageSourceCopyProperties(source, nil) as? [CFString: Any] else {
            return loopCount
        }
        if let gifProps = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
            if let count = gifProps[kCGImagePropertyGIFLoopCount] as? NSNumber {
                loopCount = count.intValue
            }
        }
        return loopCount
    }

    // Mirrors SDImageIOAnimatedCoder.frameDurationAtIndex:source: (line 416).
    private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        var duration: TimeInterval = 0.1
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
            return duration
        }
        let gifProps = props[kCGImagePropertyGIFDictionary] as? [CFString: Any]

        if let unclamped = gifProps?[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber {
            duration = unclamped.doubleValue
        } else if let clamped = gifProps?[kCGImagePropertyGIFDelayTime] as? NSNumber {
            duration = clamped.doubleValue
        }
        // Many ads specify 0 duration. Firefox heuristic: use 100ms for any frame <= 10ms.
        // Mirrors SDImageIOAnimatedCoder.m:440–441.
        if duration < 0.011 {
            duration = 0.1
        }
        return duration
    }

    @objc(durationAtIndex:)
    func duration(at index: Int) -> TimeInterval {
        if index >= frameDurations.count { return 0 }
        return frameDurations[index]
    }

    // Mirrors SDImageIOAnimatedCoder.safeAnimatedImageFrameAtIndex: and createFrameAtIndex:... (line 1148, 448).
    @objc(frameAtIndex:)
    func frame(at index: Int) -> UIImage? {
        if index >= frameCount { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceShouldCacheImmediately: true,
        ]
        // Guard the CGImageSource access — mirrors SDImageIOAnimatedCoder.animatedImageFrameAtIndex:
        // which wraps safeAnimatedImageFrameAtIndex: in SD_LOCK(_lock). The decode below contends
        // with didReceiveMemoryWarning:'s CGImageSourceRemoveCacheAtIndex on the same source.
        lock.wait()
        var cgImage: CGImage?
        if let imageSource = imageSource {
            cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, options as CFDictionary)
        }
        lock.signal()
        guard var image = cgImage else { return nil }

        // iOS 15+: CGImageRef retains the CGImageSourceRef internally, causing thread-safety issues.
        // Strip it by creating a plain copy. Mirrors SDImageIOAnimatedCoder.m:542–552.
        if #available(iOS 15, *) {
            if let stripped = CTCGImageCreateStrippedCopy(image) {
                image = stripped
            }
        }

        // Apply scale — mirrors SDImageIOAnimatedCoder.createFrameAtIndex:...: (line 576):
        //   UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];
        // GIFs do not carry EXIF orientation metadata, so UIImageOrientationUp is correct here.
        let frame = UIImage(cgImage: image, scale: scale, orientation: .up)
        return frame
    }
}

// Strips the internal CGImageSourceRef retained by CGImageRef on iOS 15+.
// This avoids thread-safety issues when rendering on a display link thread.
// Mirrors SDCGImageCreateMutableCopy from SDImageIOAnimatedCoder.m:40–54.
private func CTCGImageCreateStrippedCopy(_ image: CGImage) -> CGImage? {
    guard let space = image.colorSpace, let provider = image.dataProvider else {
        return nil
    }
    return CGImage(width: image.width,
                   height: image.height,
                   bitsPerComponent: image.bitsPerComponent,
                   bitsPerPixel: image.bitsPerPixel,
                   bytesPerRow: image.bytesPerRow,
                   space: space,
                   bitmapInfo: image.bitmapInfo,
                   provider: provider,
                   decode: image.decode,
                   shouldInterpolate: image.shouldInterpolate,
                   intent: image.renderingIntent)
}
