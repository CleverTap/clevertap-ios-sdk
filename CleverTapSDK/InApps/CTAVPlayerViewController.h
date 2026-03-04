#import <AVKit/AVKit.h>

@class CTInAppNotification;

typedef void (^CTAVPlayerCTATapHandler)(void);

@interface CTAVPlayerViewController : AVPlayerViewController

@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) BOOL autoplay;
@property (nonatomic, assign) BOOL loopVideo;
@property (nonatomic, copy) CTAVPlayerCTATapHandler ctaTapHandler;

- (instancetype)initWithNotification:(CTInAppNotification*)notification;
- (instancetype)initWithNotification:(CTInAppNotification*)notification muted:(BOOL)muted autoplay:(BOOL)autoplay;

@end
