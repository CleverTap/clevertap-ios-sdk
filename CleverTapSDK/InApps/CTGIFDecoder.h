/*
 * CTGIFDecoder
 * Ported from SDWebImage's SDImageIOAnimatedCoder + SDImageGIFCoder.
 * Decodes GIF frames lazily using the ImageIO framework.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Provides per-frame access to an animated image. Conforms to CTAnimatedImageProviding.
@interface CTGIFDecoder : NSObject

@property (nonatomic, readonly) NSUInteger frameCount;
@property (nonatomic, readonly) NSUInteger loopCount;

/// Returns nil if data cannot be decoded as a valid animated GIF (mirrors SDAnimatedImage behavior).
- (nullable instancetype)initWithData:(NSData *)data;

- (nullable UIImage *)frameAtIndex:(NSUInteger)index;
- (NSTimeInterval)durationAtIndex:(NSUInteger)index;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
