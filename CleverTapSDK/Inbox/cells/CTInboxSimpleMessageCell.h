#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CleverTap+Inbox.h"
#import "CTInboxActionView.h"
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FLAnimatedImageView;

@interface CTInboxSimpleMessageCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet FLAnimatedImageView *cellImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewRatioContraint;
@property (strong, nonatomic) IBOutlet AVPlayerLayer *playerLayer;
@property (strong, nonatomic) IBOutlet CTInboxActionView *actionView;
@property (nonatomic, strong) IBOutlet UIView *avPlayerContainerView;
@property (strong, nonatomic) IBOutlet UIView *mediaContainerView;

@property (nonatomic, strong) IBOutlet UIButton *volume;

@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (strong, nonatomic) AVPlayer *avPlayer;
@property (strong, nonatomic) AVPlayerLayer *avPlayerLayer;
@property (strong, nonatomic) AVPlayerItem *avPlayerItem;
@property (assign, nonatomic) BOOL isVideoMuted;
@property (nonatomic, assign) BOOL isControlsHidden;

- (IBAction)volumeButtonTapped:(UIButton *)sender;
- (void)setupSimpleMessage:(CTInboxNotificationContentItem *)message;
- (void)setupVideoPlayer:(CleverTapInboxMessage *)message;
@end

NS_ASSUME_NONNULL_END
