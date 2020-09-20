#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CTInAppNotification;

@interface CTAVPlayerViewController : AVPlayerViewController

- (instancetype)initWithNotification:(CTInAppNotification*)notification;

@end

NS_ASSUME_NONNULL_END
