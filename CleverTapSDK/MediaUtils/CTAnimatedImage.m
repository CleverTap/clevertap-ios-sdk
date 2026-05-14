/*
 * CTAnimatedImage
 * Ported from SDWebImage's SDAnimatedImage.
 *
 * Key SDWebImage source references:
 *   - initWithData:scale:options: → SDAnimatedImage.m:140–189
 *   - initWithAnimatedCoder:scale: → SDAnimatedImage.m:191–211
 *   - animatedImageFrameAtIndex: → SDAnimatedImage.m:299–308
 *   - animatedImageDurationAtIndex: → SDAnimatedImage.m:310–319
 */

#import "CTAnimatedImage.h"
#import "CTGIFDecoder.h"

@interface CTAnimatedImage ()

@property (nonatomic, strong) CTGIFDecoder *gifDecoder;

@end

@implementation CTAnimatedImage

// Mirrors SDAnimatedImage.imageWithData: (SDAnimatedImage.m:107–109).
+ (nullable instancetype)imageWithData:(NSData *)data {
    return [[CTAnimatedImage alloc] initWithData:data];
}

// Mirrors SDAnimatedImage.imageWithData:scale: (SDAnimatedImage.m:111–113).
+ (nullable instancetype)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[CTAnimatedImage alloc] initWithData:data scale:scale];
}

// Mirrors SDAnimatedImage.initWithData: → initWithData:scale:1 (SDAnimatedImage.m:132–134).
- (nullable instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

// Mirrors SDAnimatedImage.initWithData:scale:options: (line 140) + initWithAnimatedCoder:scale: (line 191).
// Scale is passed to CTGIFDecoder so each frame UIImage reports the correct logical size
// (mirrors SDImageIOAnimatedCoder.createFrameAtIndex:...: line 576).
- (nullable instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data || data.length == 0) return nil;

    CTGIFDecoder *decoder = [[CTGIFDecoder alloc] initWithData:data scale:scale];
    if (!decoder) return nil;

    // Get the first frame to initialize UIImage (mirrors SDAnimatedImage.m:195–203)
    UIImage *firstFrame = [decoder frameAtIndex:0];
    if (!firstFrame) return nil;

    // Mirrors SDAnimatedImage.initWithAnimatedCoder:scale: (SDAnimatedImage.m:200–202):
    // orientation: propagate from first decoded frame to respect EXIF rotation metadata.
    self = [super initWithCGImage:firstFrame.CGImage scale:MAX(scale, 1) orientation:firstFrame.imageOrientation];
    if (self) {
        // Only keep the coder if there are multiple frames (matches SDAnimatedImage.m:206–208)
        if (decoder.frameCount > 1) {
            _gifDecoder = decoder;
        }
    }
    return self;
}

#pragma mark - CTAnimatedImageProviding

- (NSUInteger)animatedImageFrameCount {
    return _gifDecoder.frameCount;
}

- (NSUInteger)animatedImageLoopCount {
    return _gifDecoder.loopCount;
}

// Mirrors SDAnimatedImage.animatedImageFrameAtIndex: (line 299).
- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (index >= self.animatedImageFrameCount) return nil;
    return [_gifDecoder frameAtIndex:index];
}

// Mirrors SDAnimatedImage.animatedImageDurationAtIndex: (line 310).
- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (index >= self.animatedImageFrameCount) return 0;
    return [_gifDecoder durationAtIndex:index];
}

@end
