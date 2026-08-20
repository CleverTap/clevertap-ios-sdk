#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CTPiPCTAOverlayViewDelegate <NSObject>
- (void)pipCTAOverlayDidTap;
@end

/// Transparent full-body tap overlay for PiP CTA handling.
/// Sits below the controls layer so control buttons still receive taps.
@interface CTPiPCTAOverlayView : UIView
@property (nonatomic, weak, nullable) id<CTPiPCTAOverlayViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
