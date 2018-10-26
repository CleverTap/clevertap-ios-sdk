#import <AVKit/AVKit.h>
#import "CTAVPlayerControlsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CTInAppNotification;

@protocol CTAVPlayerViewControllerDelegate <NSObject>
- (void)toggleFullscreen;
@end

@interface CTAVPlayerViewController : AVPlayerViewController

@property (nonatomic, weak) id <CTAVPlayerViewControllerDelegate> playerDelegate;

- (instancetype)initWithNotification:(CTInAppNotification*)notification;

@end

NS_ASSUME_NONNULL_END
