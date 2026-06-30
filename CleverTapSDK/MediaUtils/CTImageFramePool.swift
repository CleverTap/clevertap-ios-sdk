/*
 * CTImageFramePool
 * Ported from SDWebImage's SDImageFramePool.
 * Simplified: per-player instance, no static provider→pool map.
 *
 * Key SDWebImage source references:
 *   - init                    → SDImageFramePool.m:41–53
 *   - prefetchFrameAtIndex:   → SDImageFramePool.m:99–128
 *   - setFrame:atIndex:       → SDImageFramePool.m:142–146
 *   - frameAtIndex:           → SDImageFramePool.m:148–154
 *   - removeAllFrames         → SDImageFramePool.m:162–166
 *   - didReceiveMemoryWarning → SDImageFramePool.m:61–63
 */

import UIKit

@objc(CTImageFramePool)
@objcMembers
final class CTImageFramePool: NSObject {

    /// Maximum number of decoded frames to keep in the buffer. Default is unlimited.
    var maxBufferCount: UInt = 0

    /// Current number of buffered frames.
    var currentFrameCount: UInt {
        lock.lock()
        defer { lock.unlock() }
        return UInt(frameBuffer.count)
    }

    private weak var provider: CTAnimatedImageProviding?
    private var frameBuffer: [NSNumber: UIImage] = [:]
    private let fetchQueue: OperationQueue = OperationQueue()
    private let lock = NSLock()

    init(provider: CTAnimatedImageProviding) {
        self.provider = provider
        super.init()
        fetchQueue.maxConcurrentOperationCount = 1
        fetchQueue.name = "com.clevertap.CTImageFramePool.fetchQueue"
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning(_:)),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didReceiveMemoryWarningNotification,
                                                  object: nil)
    }

    @available(*, unavailable)
    override init() {
        fatalError("init() is unavailable")
    }

    func didReceiveMemoryWarning(_ notification: Notification) {
        removeAllFrames()
    }

    // Mirrors SDImageFramePool.prefetchFrameAtIndex: (line 99).
    @objc(prefetchFrameAtIndex:)
    func prefetchFrame(at index: UInt) {
        do {
            lock.lock()
            defer { lock.unlock() }
            let count = UInt(frameBuffer.count)
            if maxBufferCount > 0 && count > maxBufferCount {
                // Evict adjacent frames (same naive strategy as SDImageFramePool.m:105–107)
                if index > 0 { frameBuffer[NSNumber(value: index - 1)] = nil }
                frameBuffer[NSNumber(value: index + 1)] = nil
            }
        }

        if fetchQueue.operationCount == 0 {
            let operation = BlockOperation { [weak self] in
                guard let strongSelf = self else { return }
                guard let provider = strongSelf.provider else { return }
                let frame = provider.animatedImageFrame(at: index)
                strongSelf.setFrame(frame, at: index)
            }
            fetchQueue.addOperation(operation)
        }
    }

    @objc(setFrame:atIndex:)
    func setFrame(_ frame: UIImage?, at index: UInt) {
        lock.lock()
        defer { lock.unlock() }
        frameBuffer[NSNumber(value: index)] = frame
    }

    @objc(frameAtIndex:)
    func frame(at index: UInt) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return frameBuffer[NSNumber(value: index)]
    }

    func removeAllFrames() {
        lock.lock()
        defer { lock.unlock() }
        frameBuffer.removeAll()
    }
}
