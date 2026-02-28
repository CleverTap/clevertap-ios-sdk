/*
 * CTAnimatedImageView
 * Ported from SDWebImage's SDAnimatedImageView (iOS path only).
 * A drop-in UIImageView replacement that animates CTAnimatedImage instances.
 *
 * Usage: set the `image` property to a CTAnimatedImage — animation starts automatically
 * when the view becomes visible (mirrors SDAnimatedImageView behavior).
 */

#import <UIKit/UIKit.h>
#import "CTAnimatedImagePlayer.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UI_ACTOR
@interface CTAnimatedImageView : UIImageView

/// The internal animation player. Available after a CTAnimatedImage is set.
@property (nonatomic, strong, readonly, nullable) CTAnimatedImagePlayer *player;

/// Currently displayed frame. KVO compliant.
@property (nonatomic, strong, readonly, nullable) UIImage *currentFrame;
/// Currently displayed frame index. KVO compliant.
@property (nonatomic, assign, readonly) NSUInteger currentFrameIndex;
/// Current loop count. KVO compliant.
@property (nonatomic, assign, readonly) NSUInteger currentLoopCount;

/// Auto-play when view becomes visible. Default is YES.
@property (nonatomic, assign) BOOL autoPlayAnimatedImage;

/// Playback rate. Default is 1.0.
@property (nonatomic, assign) double playbackRate;

/// RunLoop mode. Default is NSRunLoopCommonModes (multi-core) or NSDefaultRunLoopMode (single-core).
@property (nonatomic, copy) NSRunLoopMode runLoopMode;

/// Max buffer size in bytes. 0 = auto. Default is 0.
@property (nonatomic, assign) NSUInteger maxBufferSize;

@end

NS_ASSUME_NONNULL_END
