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

#import "CTAnimatedImagePlayer.h"
#import "CTDisplayLink.h"
#import "CTImageFramePool.h"

@interface CTAnimatedImagePlayer () {
    NSRunLoopMode _runLoopMode;
    NSUInteger _maxBufferSize;
    double _playbackRate;
}

@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;
@property (nonatomic, assign, readwrite) NSUInteger currentLoopCount;

@property (nonatomic, strong) id<CTAnimatedImageProviding> animatedProvider;
@property (nonatomic, strong) CTImageFramePool *framePool;
@property (nonatomic, strong) CTDisplayLink *displayLink;

@property (nonatomic, assign) NSUInteger currentFrameBytes;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) BOOL bufferMiss;
@property (nonatomic, assign) BOOL needsDisplayWhenImageBecomesAvailable;

@end

@implementation CTAnimatedImagePlayer

- (nullable instancetype)initWithProvider:(id<CTAnimatedImageProviding>)provider {
    self = [super init];
    if (self) {
        NSUInteger frameCount = provider.animatedImageFrameCount;
        if (frameCount <= 1) return nil;
        self.totalFrameCount = frameCount;
        self.totalLoopCount = provider.animatedImageLoopCount;
        self.animatedProvider = provider;
        self.playbackRate = 1.0;
        self.framePool = [[CTImageFramePool alloc] initWithProvider:provider];
    }
    return self;
}

+ (nullable instancetype)playerWithProvider:(id<CTAnimatedImageProviding>)provider {
    return [[CTAnimatedImagePlayer alloc] initWithProvider:provider];
}

#pragma mark - Display Link

// Lazy-creates the display link and adds it to the run loop.
// Mirrors SDAnimatedImagePlayer.displayLink getter (line 67).
- (CTDisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CTDisplayLink displayLinkWithTarget:self selector:@selector(displayDidRefresh:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
        [_displayLink stop];
    }
    return _displayLink;
}

- (void)setRunLoopMode:(NSRunLoopMode)runLoopMode {
    if ([_runLoopMode isEqual:runLoopMode]) return;
    if (_displayLink) {
        if (_runLoopMode) {
            [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_runLoopMode];
        }
        if (runLoopMode.length > 0) {
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:runLoopMode];
        }
    }
    _runLoopMode = [runLoopMode copy];
}

- (NSRunLoopMode)runLoopMode {
    if (!_runLoopMode) {
        _runLoopMode = [[self class] defaultRunLoopMode];
    }
    return _runLoopMode;
}

+ (NSRunLoopMode)defaultRunLoopMode {
    // Mirrors SDAnimatedImagePlayer.defaultRunLoopMode (line 350).
    return [NSProcessInfo processInfo].activeProcessorCount > 1
        ? NSRunLoopCommonModes
        : NSDefaultRunLoopMode;
}

#pragma mark - State Control

// Caches the first frame into the pool and triggers immediate display.
// Mirrors SDAnimatedImagePlayer.setupCurrentFrame (line 100).
- (void)setupCurrentFrame {
    if (self.currentFrameIndex != 0) return;
    if (!self.currentFrame && [self.animatedProvider isKindOfClass:[UIImage class]]) {
        UIImage *image = (UIImage *)self.animatedProvider;
        UIImage *posterFrame = [[UIImage alloc] initWithCGImage:image.CGImage
                                                          scale:image.scale
                                                    orientation:image.imageOrientation];
        if (posterFrame) {
            [self calculateMaxBufferCountWithFrame:posterFrame];
            self.needsDisplayWhenImageBecomesAvailable = YES;
            [self.framePool setFrame:posterFrame atIndex:self.currentFrameIndex];
        }
    }
}

// Mirrors SDAnimatedImagePlayer.resetCurrentFrameStatus (line 128).
- (void)resetCurrentFrameStatus {
    _currentFrame = nil;
    _currentFrameIndex = 0;
    _currentLoopCount = 0;
    _currentTime = 0;
    _bufferMiss = NO;
    _needsDisplayWhenImageBecomesAvailable = NO;
}

- (void)clearFrameBuffer {
    [self.framePool removeAllFrames];
}

#pragma mark - Animation Control

- (void)startPlaying {
    [self.displayLink start];
    [self setupCurrentFrame];
}

- (void)stopPlaying {
    [_displayLink stop];
    [self resetCurrentFrameStatus];
}

- (void)pausePlaying {
    [_displayLink stop];
}

- (BOOL)isPlaying {
    return _displayLink.isRunning;
}

#pragma mark - Core Render

// Mirrors SDAnimatedImagePlayer.displayDidRefresh: (line 175).
- (void)displayDidRefresh:(CTDisplayLink *)displayLink {
    if (!self.isPlaying) return;

    NSUInteger totalFrameCount = self.totalFrameCount;
    if (totalFrameCount <= 1) { [self stopPlaying]; return; }

    double playbackRate = self.playbackRate;
    if (playbackRate <= 0) { [self stopPlaying]; return; }

    NSTimeInterval duration = displayLink.duration;
    NSUInteger currentFrameIndex = self.currentFrameIndex;
    NSUInteger nextFrameIndex = (currentFrameIndex + 1) % totalFrameCount;

    if (self.needsDisplayWhenImageBecomesAvailable) {
        UIImage *currentFrame = [self.framePool frameAtIndex:currentFrameIndex];
        if (currentFrame) {
            self.currentFrame = currentFrame;
            [self handleFrameChange];
            self.bufferMiss = NO;
            self.needsDisplayWhenImageBecomesAvailable = NO;
        } else {
            self.bufferMiss = YES;
        }
    }

    if (!self.bufferMiss) {
        self.currentTime += duration;
        NSTimeInterval currentDuration = [self.animatedProvider animatedImageDurationAtIndex:currentFrameIndex] / playbackRate;
        if (self.currentTime < currentDuration) {
            [self prefetchFrameAtIndex:currentFrameIndex nextIndex:nextFrameIndex];
            return;
        }

        self.needsDisplayWhenImageBecomesAvailable = YES;
        self.currentFrameIndex = nextFrameIndex;
        self.currentTime -= currentDuration;
        NSTimeInterval nextDuration = [self.animatedProvider animatedImageDurationAtIndex:nextFrameIndex] / playbackRate;
        if (self.currentTime > nextDuration) {
            self.currentTime = nextDuration;
        }

        if (nextFrameIndex == 0) {
            self.currentLoopCount++;
            [self handleLoopChange];
            NSUInteger maxLoopCount = self.totalLoopCount;
            if (maxLoopCount != 0 && self.currentLoopCount >= maxLoopCount) {
                [self stopPlaying];
                return;
            }
        }
    }

    if (!self.isPlaying) return;
    [self prefetchFrameAtIndex:currentFrameIndex nextIndex:nextFrameIndex];
}

// Mirrors SDAnimatedImagePlayer.prefetchFrameAtIndex:nextIndex: (line 286).
- (void)prefetchFrameAtIndex:(NSUInteger)currentIndex nextIndex:(NSUInteger)nextIndex {
    NSUInteger fetchIndex = currentIndex;
    UIImage *fetchFrame = nil;
    if (!self.bufferMiss) {
        fetchIndex = nextIndex;
        fetchFrame = [self.framePool frameAtIndex:nextIndex];
    }
    BOOL bufferFull = (self.framePool.currentFrameCount == self.totalFrameCount);
    if (!fetchFrame && !bufferFull) {
        [self calculateMaxBufferCountWithFrame:self.currentFrame];
        [self.framePool prefetchFrameAtIndex:fetchIndex];
    }
}

- (void)handleFrameChange {
    if (self.animationFrameHandler) {
        self.animationFrameHandler(self.currentFrameIndex, self.currentFrame);
    }
}

- (void)handleLoopChange {
    if (self.animationLoopHandler) {
        self.animationLoopHandler(self.currentLoopCount);
    }
}

#pragma mark - Buffer Sizing

// Mirrors SDAnimatedImagePlayer.calculateMaxBufferCountWithFrame: (line 319).
- (void)calculateMaxBufferCountWithFrame:(UIImage *)frame {
    if (!frame) return;
    NSUInteger bytes = self.currentFrameBytes;
    if (bytes == 0) {
        bytes = CGImageGetBytesPerRow(frame.CGImage) * CGImageGetHeight(frame.CGImage);
        if (bytes == 0) bytes = 1024;
        else self.currentFrameBytes = bytes;
    }

    NSUInteger maxBytes = 0;
    if (self.maxBufferSize > 0) {
        maxBytes = self.maxBufferSize;
    } else {
        // Use 20% of total RAM or 60% of free RAM, whichever is smaller.
        NSUInteger total = (NSUInteger)[NSProcessInfo processInfo].physicalMemory;
        int64_t freeRAM = total / 4; // conservative fallback
        maxBytes = (NSUInteger)MIN(total * 0.2, freeRAM * 0.6);
    }

    NSUInteger maxCount = (NSUInteger)((double)maxBytes / (double)bytes);
    if (!maxCount) maxCount = 1;
    self.framePool.maxBufferCount = maxCount;
}

@end
