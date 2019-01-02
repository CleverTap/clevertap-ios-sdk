#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CleverTap+Inbox.h"
#import "CTInboxMessageActionView.h"
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FLAnimatedImageView;

@interface CTInboxSimpleMessageCell : UITableViewCell <CTInboxActionViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet FLAnimatedImageView *cellImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIView *readView;
@property (strong, nonatomic) IBOutlet AVPlayerLayer *playerLayer;
@property (strong, nonatomic) IBOutlet CTInboxMessageActionView *actionView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerContainerView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerControlsView;
@property (strong, nonatomic) IBOutlet UIView *mediaContainerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewLRatioContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewPRatioContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *actionViewHeightContraint;

@property (nonatomic, strong) IBOutlet UIButton *volume;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (strong, nonatomic) AVPlayer *avPlayer;
@property (strong, nonatomic) AVPlayerLayer *avPlayerLayer;
@property (strong, nonatomic) AVPlayerItem *avPlayerItem;
@property (nonatomic, weak) NSTimer *controllersTimer;
@property (nonatomic, assign) NSInteger controllersTimeoutPeriod;
@property (assign, nonatomic) BOOL isVideoMuted;
@property (nonatomic, assign) BOOL isControlsHidden;

@property (strong, nonatomic) CleverTapInboxMessage *message;

- (IBAction)volumeButtonTapped:(UIButton *)sender;
- (void)layoutNotification:(CleverTapInboxMessage *)message;
- (void)setupSimpleMessage:(CleverTapInboxMessage *)message;
- (void)setupVideoPlayer:(CleverTapInboxMessage *)message;
@end

NS_ASSUME_NONNULL_END
