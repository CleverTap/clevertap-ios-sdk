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
@property (strong, nonatomic) IBOutlet UIView *readView;
@property (strong, nonatomic) IBOutlet CTInboxMessageActionView *actionView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerContainerView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerControlsView;
@property (strong, nonatomic) IBOutlet UIView *mediaContainerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewLRatioContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewPRatioContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *actionViewHeightContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *readViewWidthContraint;

// video controls
@property (nonatomic, strong) IBOutlet UIButton *volume;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong, readwrite) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, strong) AVPlayerItem *avPlayerItem;
@property (nonatomic, weak)   NSTimer *controllersTimer;
@property (nonatomic, assign) NSInteger controllersTimeoutPeriod;
@property (nonatomic, assign) BOOL isVideoMuted;
@property (nonatomic, assign) BOOL isControlsHidden;

@property (nonatomic, strong) CleverTapInboxMessage *message;

- (IBAction)volumeButtonTapped:(UIButton *)sender;
- (void)layoutNotification:(CleverTapInboxMessage *)message;
- (void)setupSimpleMessage:(CleverTapInboxMessage *)message;
- (void)setupVideoPlayer:(CleverTapInboxMessage *)message;
- (void)togglePlay;
- (void)pause;
- (void)play;
@end

NS_ASSUME_NONNULL_END
