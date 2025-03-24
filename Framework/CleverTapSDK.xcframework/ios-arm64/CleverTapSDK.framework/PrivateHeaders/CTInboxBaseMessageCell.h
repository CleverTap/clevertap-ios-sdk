#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import "CleverTap+Inbox.h"
#import "CTInboxMessageActionView.h"
#import "CTConstants.h"
#import "CTInboxUtils.h"
#import "CTUIUtils.h"
#import "CTVideoThumbnailGenerator.h"

@class SDAnimatedImageView;

typedef NS_OPTIONS(NSUInteger , CTMediaPlayerCellType) {
    CTMediaPlayerCellTypeNone,
    CTMediaPlayerCellTypeTopLandscape,
    CTMediaPlayerCellTypeTopPortrait,
    CTMediaPlayerCellTypeMiddleLandscape,
    CTMediaPlayerCellTypeMiddlePortrait,
    CTMediaPlayerCellTypeBottomLandscape,
    CTMediaPlayerCellTypeBottomPortrait
};

@interface CTInboxBaseMessageCell : UITableViewCell <CTInboxActionViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet SDAnimatedImageView *cellImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UIView *readView;
@property (strong, nonatomic) IBOutlet CTInboxMessageActionView *actionView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerContainerView;
@property (strong, nonatomic) IBOutlet UIView *avPlayerControlsView;
@property (strong, nonatomic) IBOutlet UIView *mediaContainerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewLRatioConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewPRatioConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *actionViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *readViewWidthConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *dividerCenterXConstraint;

// video controls
@property (nonatomic, strong) UIButton *volumeButton;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong, readwrite) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, weak)   NSTimer *controllersTimer;
@property (nonatomic, assign) NSInteger controllersTimeoutPeriod;
@property (nonatomic, assign) BOOL isAVMuted;
@property (nonatomic, assign) BOOL isControlsHidden;
@property (atomic, assign) BOOL hasVideoPoster;
@property (nonatomic, strong) CTVideoThumbnailGenerator *thumbnailGenerator;
@property (nonatomic, strong) CleverTapInboxMessage *message;
@property (atomic, assign) CTMediaPlayerCellType mediaPlayerCellType;
@property (atomic, assign) CTInboxMessageType messageType;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;


@property (nonatomic, assign) SDWebImageOptions sdWebImageOptions;
@property (nonatomic, strong) SDWebImageContext *sdWebImageContext;

- (void)volumeButtonTapped:(UIButton *)sender;

- (void)configureForMessage:(CleverTapInboxMessage *)message;
- (void)configureActionView:(BOOL)hide;
- (BOOL)mediaIsEmpty;
- (BOOL)orientationIsPortrait;
- (BOOL)deviceOrientationIsLandscape;
- (UIImage *)getPortraitPlaceHolderImage;
- (UIImage *)getLandscapePlaceHolderImage;

- (BOOL)hasAudio;
- (BOOL)hasVideo;
- (void)setupMediaPlayer;
- (void)pause;
- (void)play;
- (void)mute:(BOOL)mute;
- (CGRect)videoRect;

- (void)setupInboxMessageActions:(CleverTapInboxMessageContent *)content;
- (void)handleOnMessageTapGesture:(UITapGestureRecognizer *)sender;

@end
