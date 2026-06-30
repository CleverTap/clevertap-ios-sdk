/*
 * CTAnimatedImageView
 * Ported from SDWebImage's SDAnimatedImageView (iOS path only).
 *
 * Key SDWebImage source references:
 *   - commonInit               → SDAnimatedImageView.m:159–172
 *   - setImage:                → SDAnimatedImageView.m:177–274
 *   - displayLayer:            → SDAnimatedImageView.m:562–579
 *   - checkPlay/updateShouldAnimate → SDAnimatedImageView.m:495–518
 *   - didMoveToSuperview/Window, setAlpha:, setHidden: → SDAnimatedImageView.m:343–395
 *   - startAnimating/stopAnimating/isAnimating → SDAnimatedImageView.m:413–458
 *   - traitCollectionDidChange → SDAnimatedImageView.m:582–590
 *   - imageViewLayer (iOS)     → SDAnimatedImageView.m:620–622
 *
 * macOS and watchOS paths omitted.
 */

import UIKit
import ObjectiveC

@objc(CTAnimatedImageView)
@objcMembers
public final class CTAnimatedImageView: UIImageView {
    // Note: UIImageView (via UIView) already conforms to CALayerDelegate, so the
    // ObjC `@interface UIImageView () <CALayerDelegate>` hack is unnecessary here.

    // MARK: - Public surface

    /// The internal animation player. Available after a CTAnimatedImage is set.
    private(set) var player: CTAnimatedImagePlayer?

    /// Currently displayed frame. KVO compliant.
    dynamic private(set) var currentFrame: UIImage?
    /// Currently displayed frame index. KVO compliant.
    dynamic private(set) var currentFrameIndex: UInt = 0
    /// Current loop count. KVO compliant.
    dynamic private(set) var currentLoopCount: UInt = 0

    /// Auto-play when view becomes visible. Default is YES.
    var autoPlayAnimatedImage: Bool = false

    /// Whether to reset the frame index to 0 when stopAnimating is called.
    var resetFrameIndexWhenStopped: Bool = false

    /// Whether to clear the frame buffer when stopAnimating is called.
    var clearBufferWhenStopped: Bool = false

    // MARK: - Backing storage (mirrors the ObjC ivars)

    private var _initFinished: Bool = false
    private var _runLoopMode: RunLoop.Mode?
    private var _maxBufferSize: UInt = 0
    private var _playbackRate: Double = 0

    private var shouldAnimate: Bool = false

    // MARK: - Initializers

    public override init(image: UIImage?) {
        super.init(image: image)
        commonInit()
    }

    public override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // Mirrors SDAnimatedImageView.commonInit (line 159).
    private func commonInit() {
        self.autoPlayAnimatedImage = true
        self.playbackRate = 1.0
        _initFinished = true
    }

    // MARK: - Image Setting

    // Mirrors SDAnimatedImageView.setImage: (line 177).
    public override var image: UIImage? {
        get {
            return super.image
        }
        set {
            if super.image === newValue { return }

            // Stop any current animation
            self.player = nil
            self.currentFrame = nil
            self.currentFrameIndex = 0
            self.currentLoopCount = 0

            super.image = newValue

            // Check if the new image is a CTAnimatedImage with multiple frames.
            // Mirrors SDAnimatedImageView.setImage: (line 196): [image.class conformsToProtocol:...]
            // In Swift, `as?` performs the equivalent runtime conformance check on the instance.
            if let provider = newValue as? CTAnimatedImageProviding,
               provider.animatedImageFrameCount > 1 {

                guard let player = CTAnimatedImagePlayer.player(withProvider: provider) else { return }

                player.runLoopMode = self.runLoopMode
                player.maxBufferSize = self.maxBufferSize
                player.playbackRate = self.playbackRate

                player.animationFrameHandler = { [weak self] index, frame in
                    guard let self = self else { return }
                    self.currentFrameIndex = index
                    self.currentFrame = frame
                    self.layer.setNeedsDisplay()
                }
                player.animationLoopHandler = { [weak self] loopCount in
                    guard let self = self else { return }
                    self.currentLoopCount = loopCount
                }

                self.player = player
                super.isHighlighted = false
                self.stopAnimating()
                self.checkPlay()
            }

            self.layer.setNeedsDisplay()
        }
    }

    // MARK: - Configuration

    var runLoopMode: RunLoop.Mode {
        get {
            if _runLoopMode == nil {
                _runLoopMode = CTAnimatedImageView.defaultRunLoopMode
            }
            return _runLoopMode!
        }
        set {
            _runLoopMode = newValue
            self.player?.runLoopMode = newValue
        }
    }

    static var defaultRunLoopMode: RunLoop.Mode {
        return ProcessInfo.processInfo.activeProcessorCount > 1
            ? .common
            : .default
    }

    var maxBufferSize: UInt {
        get {
            return _maxBufferSize
        }
        set {
            _maxBufferSize = newValue
            self.player?.maxBufferSize = newValue
        }
    }

    var playbackRate: Double {
        get {
            if !_initFinished { return 1.0 }
            return _playbackRate
        }
        set {
            _playbackRate = newValue
            self.player?.playbackRate = newValue
        }
    }

    // MARK: - UIView Overrides

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        checkPlay()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        checkPlay()
    }

    public override var alpha: CGFloat {
        get {
            return super.alpha
        }
        set {
            super.alpha = newValue
            checkPlay()
        }
    }

    public override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set {
            super.isHidden = newValue
            checkPlay()
        }
    }

    // MARK: - UIImageView Overrides

    public override func startAnimating() {
        if self.player != nil {
            updateShouldAnimate()
            if shouldAnimate {
                self.player?.startPlaying()
            }
        } else {
            super.startAnimating()
        }
    }

    // Mirrors SDAnimatedImageView.stopAnimating (SDAnimatedImageView.m:429–447).
    // resetFrameIndexWhenStopped → stopPlaying (resets frame index to 0).
    // default (NO)              → pausePlaying (holds current frame).
    // clearBufferWhenStopped    → clearFrameBuffer (releases buffered decoded frames).
    public override func stopAnimating() {
        if let player = self.player {
            if resetFrameIndexWhenStopped {
                player.stopPlaying()
            } else {
                player.pausePlaying()
            }
            if clearBufferWhenStopped {
                player.clearFrameBuffer()
            }
        } else {
            super.stopAnimating()
        }
    }

    public override var isAnimating: Bool {
        if let player = self.player {
            return player.isPlaying
        }
        return super.isAnimating
    }

    public override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if self.player == nil {
                super.isHighlighted = newValue
            }
        }
    }

    // MARK: - Private

    // Mirrors SDAnimatedImageView.checkPlay (line 495).
    private func checkPlay() {
        if self.player != nil && self.autoPlayAnimatedImage {
            updateShouldAnimate()
            if shouldAnimate {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }

    // Mirrors SDAnimatedImageView.updateShouldAnimate (line 510).
    private func updateShouldAnimate() {
        let isVisible = self.window != nil && self.superview != nil && !self.isHidden && self.alpha > 0.0
        self.shouldAnimate = (self.player != nil) && isVisible
    }

    // MARK: - CALayerDelegate

    // Mirrors SDAnimatedImageView.displayLayer: (line 562).
    // Pinned to the `displayLayer:` selector (the CALayer delegate callback). We avoid
    // referencing the `CALayerDelegate` Swift type / its renamed `display(_:)` requirement,
    // both of which are iOS 10+, since the deployment target is lower — matching the ObjC
    // `@selector(displayLayer:)`.
    @objc(displayLayer:)
    func displayLayer(_ layer: CALayer) {
        if let currentFrame = self.currentFrame {
            layer.contentsScale = currentFrame.scale
            layer.contents = currentFrame.cgImage
        } else {
            // No animated frame — fall back to default UIImageView rendering.
            let sel = NSSelectorFromString("displayLayer:")
            if UIImageView.instancesRespond(to: sel) {
                // Faithful equivalent of [super displayLayer:layer].
                // objc_msgSendSuper is unavailable in Swift, so we resolve UIImageView's
                // own IMP for displayLayer: and invoke it directly (this is the superclass
                // implementation, since CTAnimatedImageView is a direct UIImageView subclass).
                typealias DisplayLayerIMP = @convention(c) (AnyObject, Selector, CALayer) -> Void
                if let imp = class_getMethodImplementation(UIImageView.self, sel) {
                    let fn = unsafeBitCast(imp, to: DisplayLayerIMP.self)
                    fn(self, sel, layer)
                }
            } else {
                if let staticImage = super.image {
                    layer.contentsScale = staticImage.scale
                    layer.contents = staticImage.cgImage
                }
            }
        }
    }

    // iOS 17+: UIImageView resets layer.contents when entering background.
    // We re-set it so the animated frame is not replaced with self.image.CGImage.
    // Mirrors SDAnimatedImageView.traitCollectionDidChange: (line 582).
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.layer.setNeedsDisplay()
    }

    // iOS: the layer is the imageView's own layer.
    // Mirrors SDAnimatedImageView.imageViewLayer (iOS, line 620).
    public override var layer: CALayer {
        return super.layer
    }
}
