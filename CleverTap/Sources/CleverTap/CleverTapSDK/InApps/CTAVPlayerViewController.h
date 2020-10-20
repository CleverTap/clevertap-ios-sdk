#import <AVKit/AVKit.h>

@class CTInAppNotification;

@interface CTAVPlayerViewController : AVPlayerViewController

- (instancetype)initWithNotification:(CTInAppNotification*)notification;

@end
