/*
 * CTAnimatedImagePlayer
 * Ported from SDWebImage's SDAnimatedImagePlayer.
 * Drives GIF animation timing using a CTDisplayLink (CADisplayLink-backed).
 */

#import <UIKit/UIKit.h>
#import "CTAnimatedImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTAnimatedImagePlayer : NSObject

/// Currently displayed frame. KVO compliant.
@property (nonatomic, readonly, nullable) UIImage *currentFrame;
/// Index of the currently displayed frame (zero-based). KVO compliant.
@property (nonatomic, readonly) NSUInteger currentFrameIndex;
/// Loop count since animation started. KVO compliant.
@property (nonatomic, readonly) NSUInteger currentLoopCount;

/// Total frame count. Defaults to the provider's frame count.
@property (nonatomic, assign) NSUInteger totalFrameCount;
/// Total loop count. 0 = infinite. Defaults to the provider's loop count.
@property (nonatomic, assign) NSUInteger totalLoopCount;

/// Playback rate. 1.0 = normal speed. 0.0 stops animation. Default is 1.0.
@property (nonatomic, assign) double playbackRate;

/// RunLoop mode for the display link. Defaults to NSRunLoopCommonModes on
/// multi-core devices, NSDefaultRunLoopMode on single-core.
@property (nonatomic, copy) NSRunLoopMode runLoopMode;

/// Max buffer size in bytes (mirrors SDAnimatedImagePlayer.maxBufferSize).
/// 0 = auto-calculate. NSUIntegerMax = cache all. Default is 0.
@property (nonatomic, assign) NSUInteger maxBufferSize;

/// Called whenever the current frame changes.
@property (nonatomic, copy, nullable) void (^animationFrameHandler)(NSUInteger index, UIImage *frame);
/// Called whenever a loop completes.
@property (nonatomic, copy, nullable) void (^animationLoopHandler)(NSUInteger loopCount);

@property (nonatomic, readonly) BOOL isPlaying;

/// Returns nil if provider has fewer than 2 frames.
- (nullable instancetype)initWithProvider:(id<CTAnimatedImageProviding>)provider;
+ (nullable instancetype)playerWithProvider:(id<CTAnimatedImageProviding>)provider;

- (void)startPlaying;
- (void)pausePlaying;
- (void)stopPlaying;
- (void)clearFrameBuffer;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
