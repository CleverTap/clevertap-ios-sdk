#import <UIKit/UIKit.h>
#import "CTPiPPayloadModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CTPiPControlsViewDelegate <NSObject>
- (void)pipControlsDidTapClose;
- (void)pipControlsDidTapExpandCollapse:(BOOL)isExpanded;
- (void)pipControlsDidTapMute;
- (void)pipControlsDidTapPlayPause;
@end

/// Overlay view containing Close, Expand/Collapse, Mute, and Play/Pause buttons.
/// Visibility of each button is controlled by the CTPiPControlsModel config.
@interface CTPiPControlsView : UIView

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CTPiPConfigModel *)config;

@property (nonatomic, weak, nullable) id<CTPiPControlsViewDelegate> delegate;

/// Show or hide the close button independently of control config.
- (void)setCloseButtonVisible:(BOOL)visible;

/// Update button states to reflect current media state.
- (void)updateMuteButtonMuted:(BOOL)isMuted;
- (void)updatePlayPauseButtonPlaying:(BOOL)isPlaying;
- (void)updateExpandCollapseButtonExpanded:(BOOL)isExpanded;

@end

NS_ASSUME_NONNULL_END
