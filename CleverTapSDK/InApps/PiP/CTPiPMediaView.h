#import <UIKit/UIKit.h>
#import "CTPiPPayloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CTPiPMediaViewDelegate <NSObject>
@optional
/// Called when media is ready to be displayed. PiP should animate in now.
- (void)pipMediaIsReadyToShow;
/// Called when video fails to load/stream and the fallback image is displayed instead.
- (void)pipMediaDidShowVideoFallback;
/// Called when all media (video + fallback) fails to load. PiP should not be shown.
- (void)pipMediaDidFailToLoad;
@end

/// Renders Image, GIF, or Video for the PiP overlay.
@interface CTPiPMediaView : UIView

@property (nonatomic, weak, nullable) id<CTPiPMediaViewDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMedia:(CTPiPMediaModel *)media;

/// Pre-loaded image/GIF data (optional). When set, used directly without re-downloading.
@property (nonatomic, strong, nullable) NSData *preloadedImageData;
/// Pre-loaded UIImage (optional). Takes precedence over preloadedImageData.
@property (nonatomic, strong, nullable) UIImage *preloadedImage;

/// Starts playback for video. No-op for image/GIF.
- (void)play;
/// Pauses playback for video. No-op for image/GIF.
- (void)pause;
/// Toggles mute state for video. No-op for image/GIF.
- (void)toggleMute;
/// Returns current mute state for video. Always NO for image/GIF.
@property (nonatomic, readonly) BOOL isMuted;

/// The content type of the media.
@property (nonatomic, readonly) CTPiPContentType contentType;

/// Load and display the media. Should be called after being added to the view hierarchy.
- (void)loadMedia;

/// Releases AVPlayer and clears media resources.
- (void)releaseMedia;

/// Switch between AspectFill (collapsed) and AspectFit (expanded) content modes.
- (void)setContentFitMode:(BOOL)fit;

@end

NS_ASSUME_NONNULL_END
