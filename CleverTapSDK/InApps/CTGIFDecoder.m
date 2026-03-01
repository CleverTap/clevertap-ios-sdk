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
 */

#import "CTGIFDecoder.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

// Strips the internal CGImageSourceRef retained by CGImageRef on iOS 15+.
// This avoids thread-safety issues when rendering on a display link thread.
// Mirrors SDCGImageCreateMutableCopy from SDImageIOAnimatedCoder.m:40–54.
static CGImageRef CTCGImageCreateStrippedCopy(CGImageRef image) CF_RETURNS_RETAINED {
    if (!image) return NULL;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(image);
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    CGColorSpaceRef space = CGImageGetColorSpace(image);
    CGDataProviderRef provider = CGImageGetDataProvider(image);
    const CGFloat *decode = CGImageGetDecode(image);
    bool shouldInterpolate = CGImageGetShouldInterpolate(image);
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(image);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(image);
    return CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow,
                         space, bitmapInfo, provider, decode, shouldInterpolate, intent);
}

@interface CTGIFDecoder () {
    CGImageSourceRef _imageSource;
    NSData *_imageData;
    // Scale factor applied to each decoded UIImage frame.
    // Mirrors SDImageIOAnimatedCoder which passes scale to UIImage initWithCGImage:scale:orientation:.
    CGFloat _scale;
    // Lightweight per-frame duration storage — mirrors SDImageIOCoderFrame (index+duration only).
    // SDImageIOAnimatedCoder.scanAndCheckFramesValidWithImageSource: (line 1076) uses a private
    // SDImageIOCoderFrame with only `index` and `duration`; no UIImage placeholder is allocated
    // during the scan phase (images are decoded lazily in frameAtIndex:).
    NSArray<NSNumber *> *_frameDurations; // per-frame duration in seconds
}
@end

@implementation CTGIFDecoder

- (void)dealloc {
    // Mirrors SDImageIOAnimatedCoder.dealloc — remove observer before releasing source.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
}

// Mirrors SDAnimatedImage.initWithData: → initWithData:scale:1.
// Scale defaults to 1.0 for raw data (same as SD; file-based loading would derive scale from filename).
- (nullable instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

// Mirrors SDImageIOAnimatedCoder.initWithAnimatedImageData:options: (line 994).
// The scale is stored and applied per-frame in frameAtIndex: so UIImage reports the correct
// logical size (matching SDImageIOAnimatedCoder.createFrameAtIndex:…:scale: line 576).
- (nullable instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data || data.length == 0) return nil;
    self = [super init];
    if (self) {
        _scale = MAX(scale, 1);
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        if (!source) return nil;

        BOOL valid = [self scanFramesFromSource:source];
        if (!valid) {
            CFRelease(source);
            return nil;
        }
        _imageSource = source;
        _imageData = data;

        // Register for memory warnings to purge ImageIO's internal per-frame decode cache.
        // Mirrors SDImageIOAnimatedCoder.initWithAnimatedImageData:options: (line 1062).
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

// Mirrors SDImageIOAnimatedCoder.didReceiveMemoryWarning: (SDImageIOAnimatedCoder.m:314–320).
// Calls CGImageSourceRemoveCacheAtIndex for every frame so ImageIO releases its internal
// per-frame CGImage decode cache, reducing memory pressure during low-memory conditions.
- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    if (_imageSource) {
        for (size_t i = 0; i < _frameCount; i++) {
            CGImageSourceRemoveCacheAtIndex(_imageSource, i);
        }
    }
}

// Mirrors SDImageIOAnimatedCoder.scanAndCheckFramesValidWithImageSource: (line 1068).
// Uses lightweight NSNumber-boxed durations instead of full CTImageFrame objects,
// matching SD's SDImageIOCoderFrame which only stores index + duration (no UIImage).
- (BOOL)scanFramesFromSource:(CGImageSourceRef)source {
    NSUInteger count = CGImageSourceGetCount(source);
    if (count == 0) return NO;

    _loopCount = [CTGIFDecoder loopCountFromSource:source];
    _frameCount = count;

    NSMutableArray<NSNumber *> *durations = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        NSTimeInterval duration = [CTGIFDecoder frameDurationAtIndex:i source:source];
        [durations addObject:@(duration)];
    }
    if (durations.count != count) return NO;
    _frameDurations = [durations copy];
    return YES;
}

// Mirrors SDImageGIFCoder.defaultLoopCount = 1 and SDImageIOAnimatedCoder.imageLoopCountWithSource: (line 403).
+ (NSUInteger)loopCountFromSource:(CGImageSourceRef)source {
    NSUInteger loopCount = 1; // GIF default (SDImageGIFCoder.defaultLoopCount)
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, NULL);
    NSDictionary *gifProps = properties[(__bridge NSString *)kCGImagePropertyGIFDictionary];
    if (gifProps) {
        NSNumber *count = gifProps[(__bridge NSString *)kCGImagePropertyGIFLoopCount];
        if (count != nil) {
            loopCount = count.unsignedIntegerValue;
        }
    }
    return loopCount;
}

// Mirrors SDImageIOAnimatedCoder.frameDurationAtIndex:source: (line 416).
+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    NSTimeInterval duration = 0.1;
    CFDictionaryRef cfProps = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
    if (!cfProps) return duration;
    NSDictionary *props = (__bridge NSDictionary *)cfProps;
    NSDictionary *gifProps = props[(__bridge NSString *)kCGImagePropertyGIFDictionary];

    NSNumber *unclamped = gifProps[(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (unclamped != nil) {
        duration = unclamped.doubleValue;
    } else {
        NSNumber *clamped = gifProps[(__bridge NSString *)kCGImagePropertyGIFDelayTime];
        if (clamped != nil) {
            duration = clamped.doubleValue;
        }
    }
    // Many ads specify 0 duration. Firefox heuristic: use 100ms for any frame <= 10ms.
    // Mirrors SDImageIOAnimatedCoder.m:440–441.
    if (duration < 0.011) {
        duration = 0.1;
    }
    CFRelease(cfProps);
    return duration;
}

- (NSTimeInterval)durationAtIndex:(NSUInteger)index {
    if (index >= _frameDurations.count) return 0;
    return [_frameDurations[index] doubleValue];
}

// Mirrors SDImageIOAnimatedCoder.safeAnimatedImageFrameAtIndex: and createFrameAtIndex:... (line 1148, 448).
- (nullable UIImage *)frameAtIndex:(NSUInteger)index {
    if (index >= _frameCount || !_imageSource) return nil;

    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @YES,
    };
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(_imageSource, index, (__bridge CFDictionaryRef)options);
    if (!cgImage) return nil;

    // iOS 15+: CGImageRef retains the CGImageSourceRef internally, causing thread-safety issues.
    // Strip it by creating a plain copy. Mirrors SDImageIOAnimatedCoder.m:542–552.
    if (@available(iOS 15, *)) {
        CGImageRef stripped = CTCGImageCreateStrippedCopy(cgImage);
        if (stripped) {
            CGImageRelease(cgImage);
            cgImage = stripped;
        }
    }

    // Apply scale — mirrors SDImageIOAnimatedCoder.createFrameAtIndex:...: (line 576):
    //   UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];
    // GIFs do not carry EXIF orientation metadata, so UIImageOrientationUp is correct here.
    UIImage *frame = [[UIImage alloc] initWithCGImage:cgImage scale:_scale orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    return frame;
}

@end
