/*
 * CTAnimatedImagePlayer
 * Ported from SDWebImage's SDAnimatedImagePlayer.
 *
 * Key SDWebImage source references:
 *   - initWithProvider:         → SDAnimatedImagePlayer.m:37–53
 *   - displayLink lazy getter   → SDAnimatedImagePlayer.m:67–74
 *   - runLoopMode getter/setter → SDAnimatedImagePlayer.m:76–96
 *   - setupCurrentFrame         → SDAnimatedImagePlayer.m:100–126
 *   - resetCurrentFrameStatus   → SDAnimatedImagePlayer.m:128–136
 *   - startPlaying/stopPlaying/pausePlaying → SDAnimatedImagePlayer.m:143–162
 *   - displayDidRefresh:        → SDAnimatedImagePlayer.m:175–281
 *   - prefetchFrameAtIndex:next → SDAnimatedImagePlayer.m:286–303
 *   - calculateMaxBufferCount   → SDAnimatedImagePlayer.m:319–348
 *   - defaultRunLoopMode        → SDAnimatedImagePlayer.m:350–353
 *
 * Simplification: only SDAnimatedImagePlaybackModeNormal implemented (no Bounce/Reverse).
 */

import UIKit
import Darwin

// Mirrors SDDeviceHelper.freeMemory — queries actual available RAM via mach_host_statistics.
// Returns 0 on failure; callers fall back to total * 0.2 in that case.
private func CTFreeMemory() -> UInt {
    let hostPort = mach_host_self()
    var hostSize = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
    var pageSize: vm_size_t = 0
    var vmStat = vm_statistics_data_t()
    if host_page_size(hostPort, &pageSize) != KERN_SUCCESS { return 0 }
    let result = withUnsafeMutablePointer(to: &vmStat) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostSize)) {
            host_statistics(hostPort, HOST_VM_INFO, $0, &hostSize)
        }
    }
    if result != KERN_SUCCESS { return 0 }
    return UInt(vmStat.free_count) * UInt(pageSize)
}

@objc(CTAnimatedImagePlayer)
@objcMembers
final class CTAnimatedImagePlayer: NSObject {

    /// Currently displayed frame. KVO compliant.
    dynamic private(set) var currentFrame: UIImage?
    /// Index of the currently displayed frame (zero-based). KVO compliant.
    dynamic private(set) var currentFrameIndex: UInt = 0
    /// Loop count since animation started. KVO compliant.
    dynamic private(set) var currentLoopCount: UInt = 0

    /// Total frame count. Defaults to the provider's frame count.
    var totalFrameCount: UInt = 0
    /// Total loop count. 0 = infinite. Defaults to the provider's loop count.
    var totalLoopCount: UInt = 0

    /// Playback rate. 1.0 = normal speed. 0.0 stops animation. Default is 1.0.
    var playbackRate: Double = 0

    /// RunLoop mode for the display link. Defaults to NSRunLoopCommonModes on
    /// multi-core devices, NSDefaultRunLoopMode on single-core.
    var runLoopMode: RunLoop.Mode {
        get {
            if _runLoopMode == nil {
                _runLoopMode = CTAnimatedImagePlayer.defaultRunLoopMode
            }
            return _runLoopMode!
        }
        set {
            if _runLoopMode == newValue { return }
            if let displayLink = _displayLink {
                if let oldMode = _runLoopMode {
                    displayLink.remove(from: .main, forMode: oldMode)
                }
                if !newValue.rawValue.isEmpty {
                    displayLink.add(to: .main, forMode: newValue)
                }
            }
            _runLoopMode = newValue
        }
    }

    /// Max buffer size in bytes (mirrors SDAnimatedImagePlayer.maxBufferSize).
    /// 0 = auto-calculate. NSUIntegerMax = cache all. Default is 0.
    var maxBufferSize: UInt = 0

    /// Called whenever the current frame changes.
    var animationFrameHandler: ((UInt, UIImage) -> Void)?
    /// Called whenever a loop completes.
    var animationLoopHandler: ((UInt) -> Void)?

    var isPlaying: Bool {
        return _displayLink?.isRunning ?? false
    }

    private var animatedProvider: CTAnimatedImageProviding?
    private var framePool: CTImageFramePool?
    private var _displayLink: CTDisplayLink?

    private var currentFrameBytes: UInt = 0
    private var currentTime: TimeInterval = 0
    private var bufferMiss: Bool = false
    private var needsDisplayWhenImageBecomesAvailable: Bool = false

    private var _runLoopMode: RunLoop.Mode?

    /// Returns nil if provider has fewer than 2 frames.
    init?(provider: CTAnimatedImageProviding) {
        super.init()
        let frameCount = provider.animatedImageFrameCount
        if frameCount <= 1 { return nil }
        self.totalFrameCount = frameCount
        self.totalLoopCount = provider.animatedImageLoopCount
        self.animatedProvider = provider
        self.playbackRate = 1.0
        self.framePool = CTImageFramePool(provider: provider)
    }

    @objc(playerWithProvider:)
    static func player(withProvider provider: CTAnimatedImageProviding) -> CTAnimatedImagePlayer? {
        return CTAnimatedImagePlayer(provider: provider)
    }

    @available(*, unavailable)
    override init() {
        fatalError("init() is unavailable")
    }

    // MARK: - Display Link

    // Lazy-creates the display link and adds it to the run loop.
    // Mirrors SDAnimatedImagePlayer.displayLink getter (line 67).
    private var displayLink: CTDisplayLink {
        if _displayLink == nil {
            _displayLink = CTDisplayLink.displayLink(withTarget: self, selector: #selector(displayDidRefresh(_:)))
            _displayLink!.add(to: .main, forMode: self.runLoopMode)
            _displayLink!.stop()
        }
        return _displayLink!
    }

    static var defaultRunLoopMode: RunLoop.Mode {
        // Mirrors SDAnimatedImagePlayer.defaultRunLoopMode (line 350).
        return ProcessInfo.processInfo.activeProcessorCount > 1
            ? .common
            : .default
    }

    // MARK: - State Control

    // Caches the first frame into the pool and triggers immediate display.
    // Mirrors SDAnimatedImagePlayer.setupCurrentFrame (line 100).
    private func setupCurrentFrame() {
        if currentFrameIndex != 0 { return }
        if currentFrame == nil, let image = animatedProvider as? UIImage {
            if let cgImage = image.cgImage {
                let posterFrame = UIImage(cgImage: cgImage,
                                          scale: image.scale,
                                          orientation: image.imageOrientation)
                calculateMaxBufferCount(with: posterFrame)
                needsDisplayWhenImageBecomesAvailable = true
                framePool?.setFrame(posterFrame, at: currentFrameIndex)
            }
        }
    }

    // Mirrors SDAnimatedImagePlayer.resetCurrentFrameStatus (line 128).
    private func resetCurrentFrameStatus() {
        currentFrame = nil
        currentFrameIndex = 0
        currentLoopCount = 0
        currentTime = 0
        bufferMiss = false
        needsDisplayWhenImageBecomesAvailable = false
    }

    func clearFrameBuffer() {
        framePool?.removeAllFrames()
    }

    // MARK: - Animation Control

    func startPlaying() {
        displayLink.start()
        setupCurrentFrame()
    }

    func stopPlaying() {
        _displayLink?.stop()
        resetCurrentFrameStatus()
    }

    func pausePlaying() {
        _displayLink?.stop()
    }

    // MARK: - Core Render

    // Mirrors SDAnimatedImagePlayer.displayDidRefresh: (line 175).
    func displayDidRefresh(_ displayLink: CTDisplayLink) {
        if !isPlaying { return }

        let totalFrameCount = self.totalFrameCount
        if totalFrameCount <= 1 { stopPlaying(); return }

        let playbackRate = self.playbackRate
        if playbackRate <= 0 { stopPlaying(); return }

        let duration = displayLink.duration
        let currentFrameIndex = self.currentFrameIndex
        let nextFrameIndex = (currentFrameIndex + 1) % totalFrameCount

        if needsDisplayWhenImageBecomesAvailable {
            if let currentFrame = framePool?.frame(at: currentFrameIndex) {
                self.currentFrame = currentFrame
                handleFrameChange()
                bufferMiss = false
                needsDisplayWhenImageBecomesAvailable = false
            } else {
                bufferMiss = true
            }
        }

        if !bufferMiss {
            currentTime += duration
            let currentDuration = (animatedProvider?.animatedImageDuration(at: currentFrameIndex) ?? 0) / playbackRate
            if currentTime < currentDuration {
                prefetchFrame(at: currentFrameIndex, nextIndex: nextFrameIndex)
                return
            }

            needsDisplayWhenImageBecomesAvailable = true
            self.currentFrameIndex = nextFrameIndex
            currentTime -= currentDuration
            let nextDuration = (animatedProvider?.animatedImageDuration(at: nextFrameIndex) ?? 0) / playbackRate
            if currentTime > nextDuration {
                currentTime = nextDuration
            }

            if nextFrameIndex == 0 {
                currentLoopCount += 1
                handleLoopChange()
                let maxLoopCount = totalLoopCount
                if maxLoopCount != 0 && currentLoopCount >= maxLoopCount {
                    stopPlaying()
                    return
                }
            }
        }

        if !isPlaying { return }
        prefetchFrame(at: currentFrameIndex, nextIndex: nextFrameIndex)
    }

    // Mirrors SDAnimatedImagePlayer.prefetchFrameAtIndex:nextIndex: (line 286).
    private func prefetchFrame(at currentIndex: UInt, nextIndex: UInt) {
        var fetchIndex = currentIndex
        var fetchFrame: UIImage? = nil
        if !bufferMiss {
            fetchIndex = nextIndex
            fetchFrame = framePool?.frame(at: nextIndex)
        }
        let bufferFull = (framePool?.currentFrameCount == totalFrameCount)
        if fetchFrame == nil && !bufferFull {
            calculateMaxBufferCount(with: currentFrame)
            framePool?.prefetchFrame(at: fetchIndex)
        }
    }

    private func handleFrameChange() {
        if let animationFrameHandler = animationFrameHandler, let currentFrame = currentFrame {
            animationFrameHandler(currentFrameIndex, currentFrame)
        }
    }

    private func handleLoopChange() {
        if let animationLoopHandler = animationLoopHandler {
            animationLoopHandler(currentLoopCount)
        }
    }

    // MARK: - Buffer Sizing

    // Mirrors SDAnimatedImagePlayer.calculateMaxBufferCountWithFrame: (line 319).
    private func calculateMaxBufferCount(with frame: UIImage?) {
        guard let frame = frame else { return }
        var bytes = currentFrameBytes
        if bytes == 0 {
            if let cgImage = frame.cgImage {
                bytes = UInt(cgImage.bytesPerRow) * UInt(cgImage.height)
            }
            if bytes == 0 { bytes = 1024 }
            else { currentFrameBytes = bytes }
        }

        var maxBytes: UInt = 0
        if maxBufferSize > 0 {
            maxBytes = maxBufferSize
        } else {
            // Use 20% of total RAM or 60% of free RAM, whichever is smaller.
            // Mirrors SDAnimatedImagePlayer.m which uses SDDeviceHelper.freeMemory (mach_host_statistics).
            let total = UInt(ProcessInfo.processInfo.physicalMemory)
            var freeRAM = CTFreeMemory()
            if freeRAM == 0 { freeRAM = total / 4 } // fallback if mach query fails
            maxBytes = UInt(min(Double(total) * 0.2, Double(freeRAM) * 0.6))
        }

        var maxCount = UInt(Double(maxBytes) / Double(bytes))
        if maxCount == 0 { maxCount = 1 }
        framePool?.maxBufferCount = maxCount
    }
}
