/*
 * CTImageFramePool
 * Ported from SDWebImage's SDImageFramePool (simplified: per-player, no static sharing map).
 * A decoded-frame buffer that prefetches frames in a background operation queue.
 */

#import <UIKit/UIKit.h>
#import "CTAnimatedImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTImageFramePool : NSObject

/// Maximum number of decoded frames to keep in the buffer. Default is unlimited.
@property (nonatomic, assign) NSUInteger maxBufferCount;
/// Current number of buffered frames.
@property (nonatomic, readonly) NSUInteger currentFrameCount;

- (instancetype)initWithProvider:(id<CTAnimatedImageProviding>)provider;

/// Enqueues background decoding of the frame at the given index.
- (void)prefetchFrameAtIndex:(NSUInteger)index;

- (nullable UIImage *)frameAtIndex:(NSUInteger)index;
- (void)setFrame:(nullable UIImage *)frame atIndex:(NSUInteger)index;
- (void)removeAllFrames;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
