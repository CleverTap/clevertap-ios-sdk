#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>


@protocol CTAVPlayerControlsDelegate <NSObject>
- (void)toggleFullscreen;
@end

@interface CTAVPlayerControlsViewController : UIViewController

@property (nonatomic, weak) id <CTAVPlayerControlsDelegate> delegate;

- (instancetype)init __unavailable;
- (instancetype)initWithPlayer:(AVPlayer*)player andConfig:(NSDictionary*)config;

@end
