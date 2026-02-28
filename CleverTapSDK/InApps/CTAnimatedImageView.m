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

#import "CTAnimatedImageView.h"
#import "CTAnimatedImage.h"

@interface UIImageView () <CALayerDelegate>
@end

@interface CTAnimatedImageView () {
    BOOL _initFinished;
    NSRunLoopMode _runLoopMode;
    NSUInteger _maxBufferSize;
    double _playbackRate;
}

@property (nonatomic, strong, readwrite) CTAnimatedImagePlayer *player;
@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;
@property (nonatomic, assign, readwrite) NSUInteger currentLoopCount;
@property (nonatomic, assign) BOOL shouldAnimate;

@end

@implementation CTAnimatedImageView

#pragma mark - Initializers

- (instancetype)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithImage:(UIImage *)image highlightedImage:(nullable UIImage *)highlightedImage {
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) [self commonInit];
    return self;
}

// Mirrors SDAnimatedImageView.commonInit (line 159).
- (void)commonInit {
    self.autoPlayAnimatedImage = YES;
    self.playbackRate = 1.0;
    _initFinished = YES;
}

#pragma mark - Image Setting

// Mirrors SDAnimatedImageView.setImage: (line 177).
- (void)setImage:(UIImage *)image {
    if (self.image == image) return;

    // Stop any current animation
    self.player = nil;
    self.currentFrame = nil;
    self.currentFrameIndex = 0;
    self.currentLoopCount = 0;

    super.image = image;

    // Check if the new image is a CTAnimatedImage with multiple frames
    if ([image conformsToProtocol:@protocol(CTAnimatedImageProviding)] &&
        [(id<CTAnimatedImageProviding>)image animatedImageFrameCount] > 1) {

        id<CTAnimatedImageProviding> provider = (id<CTAnimatedImageProviding>)image;
        CTAnimatedImagePlayer *player = [CTAnimatedImagePlayer playerWithProvider:provider];
        if (!player) return;

        player.runLoopMode = self.runLoopMode;
        player.maxBufferSize = self.maxBufferSize;
        player.playbackRate = self.playbackRate;

        __weak typeof(self) weakSelf = self;
        player.animationFrameHandler = ^(NSUInteger index, UIImage *frame) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.currentFrameIndex = index;
            strongSelf.currentFrame = frame;
            [strongSelf.layer setNeedsDisplay];
        };
        player.animationLoopHandler = ^(NSUInteger loopCount) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.currentLoopCount = loopCount;
        };

        self.player = player;
        super.highlighted = NO;
        [self stopAnimating];
        [self checkPlay];
    }

    [self.layer setNeedsDisplay];
}

#pragma mark - Configuration

- (void)setRunLoopMode:(NSRunLoopMode)runLoopMode {
    _runLoopMode = [runLoopMode copy];
    self.player.runLoopMode = runLoopMode;
}

- (NSRunLoopMode)runLoopMode {
    if (!_runLoopMode) {
        _runLoopMode = [[self class] defaultRunLoopMode];
    }
    return _runLoopMode;
}

+ (NSRunLoopMode)defaultRunLoopMode {
    return [NSProcessInfo processInfo].activeProcessorCount > 1
        ? NSRunLoopCommonModes
        : NSDefaultRunLoopMode;
}

- (void)setMaxBufferSize:(NSUInteger)maxBufferSize {
    _maxBufferSize = maxBufferSize;
    self.player.maxBufferSize = maxBufferSize;
}

- (NSUInteger)maxBufferSize {
    return _maxBufferSize;
}

- (void)setPlaybackRate:(double)playbackRate {
    _playbackRate = playbackRate;
    self.player.playbackRate = playbackRate;
}

- (double)playbackRate {
    if (!_initFinished) return 1.0;
    return _playbackRate;
}

#pragma mark - UIView Overrides

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self checkPlay];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self checkPlay];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    [self checkPlay];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    [self checkPlay];
}

#pragma mark - UIImageView Overrides

- (void)startAnimating {
    if (self.player) {
        [self updateShouldAnimate];
        if (self.shouldAnimate) {
            [self.player startPlaying];
        }
    } else {
        [super startAnimating];
    }
}

- (void)stopAnimating {
    if (self.player) {
        [self.player pausePlaying];
    } else {
        [super stopAnimating];
    }
}

- (BOOL)isAnimating {
    if (self.player) {
        return self.player.isPlaying;
    }
    return [super isAnimating];
}

- (void)setHighlighted:(BOOL)highlighted {
    if (!self.player) {
        [super setHighlighted:highlighted];
    }
}

#pragma mark - Private

// Mirrors SDAnimatedImageView.checkPlay (line 495).
- (void)checkPlay {
    if (self.player && self.autoPlayAnimatedImage) {
        [self updateShouldAnimate];
        if (self.shouldAnimate) {
            [self startAnimating];
        } else {
            [self stopAnimating];
        }
    }
}

// Mirrors SDAnimatedImageView.updateShouldAnimate (line 510).
- (void)updateShouldAnimate {
    BOOL isVisible = self.window && self.superview && !self.isHidden && self.alpha > 0.0;
    self.shouldAnimate = self.player && isVisible;
}

#pragma mark - CALayerDelegate

// Mirrors SDAnimatedImageView.displayLayer: (line 562).
- (void)displayLayer:(CALayer *)layer {
    UIImage *currentFrame = self.currentFrame;
    if (currentFrame) {
        layer.contentsScale = currentFrame.scale;
        layer.contents = (__bridge id)currentFrame.CGImage;
    } else {
        // No animated frame — fall back to default UIImageView rendering.
        if ([UIImageView instancesRespondToSelector:@selector(displayLayer:)]) {
            [super displayLayer:layer];
        } else {
            UIImage *staticImage = super.image;
            if (staticImage) {
                layer.contentsScale = staticImage.scale;
                layer.contents = (__bridge id)staticImage.CGImage;
            }
        }
    }
}

// iOS 17+: UIImageView resets layer.contents when entering background.
// We re-set it so the animated frame is not replaced with self.image.CGImage.
// Mirrors SDAnimatedImageView.traitCollectionDidChange: (line 582).
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self.layer setNeedsDisplay];
}

// iOS: the layer is the imageView's own layer.
// Mirrors SDAnimatedImageView.imageViewLayer (iOS, line 620).
- (CALayer *)layer {
    return [super layer];
}

@end
