#import <UIKit/UIKit.h>
#import "CTPiPPayloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CTPiPControlsViewDelegate <NSObject>
- (void)pipControlsDidTapClose;
- (void)pipControlsDidTapExpandCollapse:(BOOL)isExpanded;
- (void)pipControlsDidTapMute;
- (void)pipControlsDidTapPlayPause;
- (void)pipControlsDidTapDeeplink;
@end

/// Overlay view containing control buttons.
/// Layout adapts based on media type (image/GIF vs video) and collapsed/expanded state.
@interface CTPiPControlsView : UIView

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CTPiPConfigModel *)config isVideoType:(BOOL)isVideoType;

@property (nonatomic, weak, nullable) id<CTPiPControlsViewDelegate> delegate;

/// Show or hide the close button independently of control config.
- (void)setCloseButtonVisible:(BOOL)visible;

/// Update mute button icon to reflect current mute state.
- (void)updateMuteButtonMuted:(BOOL)isMuted;

/// Update play/pause button icon to reflect current playback state.
- (void)updatePlayPauseButtonPlaying:(BOOL)isPlaying;

/// Update button layout and icons for expanded/collapsed state transition.
- (void)updateLayout:(BOOL)isExpanded;

@end

NS_ASSUME_NONNULL_END
