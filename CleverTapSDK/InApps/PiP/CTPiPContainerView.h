#import <UIKit/UIKit.h>
#import "CTPiPPayloadModel.h"
#import "CTPiPMediaView.h"
#import "CTPiPControlsView.h"
#import "CTPiPCTAOverlayView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CTPiPContainerViewDelegate <NSObject>
- (void)pipContainerDidTapClose;
- (void)pipContainerDidTapCTA;
- (void)pipContainerDidTapMute;
- (void)pipContainerDidTapPlayPause;
- (void)pipContainerDidToggleExpand:(BOOL)isExpanded;
@end

/// Draggable PiP floating container. Manages layout, border/radius, drag + 9-point snap,
/// media rendering, control buttons, and CTA overlay.
@interface CTPiPContainerView : UIView

- (instancetype)init NS_UNAVAILABLE;

/// Designated initialiser.
/// @param config     Parsed PiP configuration.
/// @param showClose  Whether the close button should be visible.
/// @param mediaView  The pre-constructed media view.
- (instancetype)initWithConfig:(CTPiPConfigModel *)config
                     showClose:(BOOL)showClose
                     mediaView:(CTPiPMediaView *)mediaView;

@property (nonatomic, weak, nullable) id<CTPiPContainerViewDelegate> delegate;

/// Lay out the container at its initial position within the given bounds (safe area aware).
- (void)placeInitialPositionInBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets;

/// Update stored bounds and safe area insets (e.g. on rotation) without repositioning.
- (void)updateBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets;

/// Returns the mediaView owned by this container.
@property (nonatomic, strong, readonly) CTPiPMediaView *mediaView;
/// Returns the controls overlay view.
@property (nonatomic, strong, readonly) CTPiPControlsView *controlsView;

/// When YES, controls are toggled on each tap and auto-hidden after 3 sec.
@property (nonatomic, assign) BOOL autoHideControls;

/// Shows controls immediately and starts the 3-sec auto-hide timer.
/// Call this after the PiP finishes animating in for image/GIF types.
- (void)showControlsAndScheduleAutoHide;

@end

NS_ASSUME_NONNULL_END
