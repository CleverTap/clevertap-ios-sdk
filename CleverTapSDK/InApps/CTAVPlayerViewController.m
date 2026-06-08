
#import "CTAVPlayerViewController.h"
#import "CTInAppNotification.h"
#import "CTUIUtils.h"
#import "CTConstants.h"

@interface CTAVPlayerViewController ()<AVPlayerViewControllerDelegate>

@property (nonatomic, strong) CTInAppNotification *notification;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIVisualEffectView *ctaContainerView;
@property (nonatomic, strong) UIButton *ctaButton;
@property (nonatomic, strong) NSLayoutConstraint *ctaButtonBottomConstraint;

@end

@implementation CTAVPlayerViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification muted:(BOOL)muted autoplay:(BOOL)autoplay {
    self = [super init];
    if (self) {
        _notification = notification;
        _muted = muted;
        _autoplay = autoplay;
        _loopVideo = YES; // Default to looping
        NSString *videoUrlString = ([CTUIUtils isDeviceOrientationLandscape] && self.notification.mediaUrlLandscape)
            ? self.notification.mediaUrlLandscape
            : self.notification.mediaUrl;
        AVPlayerItem *avPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:videoUrlString]];
        self.playerItem = avPlayerItem;
        self.player = [AVPlayer playerWithPlayerItem:avPlayerItem];
        self.player.muted = muted;

        // Observe status to detect load failure before playback begins
        [avPlayerItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];

        // Setup looping notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:avPlayerItem];

        // Log mid-stream failures (network drops etc.) but do not dismiss
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemFailedMidStream:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:avPlayerItem];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;

    // Configure audio session to mix with other audio when muted
    if (self.muted) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                         withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                               error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }

    self.showsPlaybackControls = YES;
    self.allowsPictureInPicturePlayback = NO;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    if (self.notification.mediaIsAudio) {
        UIImage *image = [CTUIUtils getImageForName:@"ct_default_audio.png"];
        self.imageView = [[UIImageView alloc] initWithFrame: self.view.bounds];
        self.imageView.backgroundColor = [UIColor blackColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = image;
        [self.contentOverlayView addSubview:self.imageView];
    }

    // Resume playback when app returns to foreground
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    // Autoplay if configured
    if (self.autoplay) {
        [self.player play];
    }

    // Add CTA button overlay if handler and buttons are available
    if (self.ctaTapHandler && self.notification.buttons.count > 0) {
        [self setupCTAButton];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self adjustAudioDefaultImage];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        [self adjustAudioDefaultImage];
    } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)adjustAudioDefaultImage {
    if (self.notification.mediaIsAudio) {
        if (!CGRectIsEmpty(self.contentOverlayView.frame)) {
            self.imageView.frame = self.contentOverlayView.bounds;
        } else {
            self.imageView.frame = self.view.bounds;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object != self.playerItem || ![keyPath isEqualToString:@"status"]) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    AVPlayerItemStatus status = (AVPlayerItemStatus)[change[NSKeyValueChangeNewKey] integerValue];
    if (status == AVPlayerItemStatusFailed) {
        NSError *error = self.playerItem.error;
        CleverTapLogStaticDebug(@"%@: InApp AVPlayerItem failed to load — %@ %ld: %@",
                                self, error.domain, (long)error.code, error.localizedDescription);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.videoDidFailHandler) {
                self.videoDidFailHandler();
            }
        });
    }
}

- (void)appWillEnterForeground {
    if (self.autoplay) {
        [self.player play];
    }
}

- (void)playerItemFailedMidStream:(NSNotification *)notification {
    NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    CleverTapLogStaticDebug(@"%@: InApp AVPlayerItem mid-stream failure — %@ %ld",
                            self, error.domain, (long)error.code);
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if (self.loopVideo) {
        AVPlayerItem *playerItem = [notification object];
        [playerItem seekToTime:kCMTimeZero completionHandler:nil];
        if (self.autoplay) {
            [self.player play];
        }
    }
}

- (void)setupCTAButton {
    // Frosted-glass container matching system button style
    UIBlurEffect *blur;
    if (@available(iOS 14, *)) {
        blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    } else {
        blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    self.ctaContainerView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.ctaContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.ctaContainerView.layer.cornerRadius = 14;
    self.ctaContainerView.layer.masksToBounds = YES;
    self.ctaContainerView.alpha = 1;
    [self.contentOverlayView addSubview:self.ctaContainerView];

    // Button lives inside the blur's contentView
    self.ctaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.ctaButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *icon = [CTUIUtils getImageForName:@"inapp_cta"];
    if (!icon) {
        if (@available(iOS 13, *)) {
            UIImageSymbolConfiguration *symConfig = [UIImageSymbolConfiguration
                configurationWithPointSize:17 weight:UIImageSymbolWeightBold];
            icon = [[UIImage systemImageNamed:@"arrow.up.right"]
                imageByApplyingSymbolConfiguration:symConfig];
        }
        // else: no bundle image and no SF Symbols on < iOS 13 — button still tappable
    }
    [self.ctaButton setImage:icon forState:UIControlStateNormal];
    self.ctaButton.tintColor = [UIColor whiteColor];
    [self.ctaButton addTarget:self action:@selector(handleCTATapped) forControlEvents:UIControlEventTouchUpInside];
    [self.ctaContainerView.contentView addSubview:self.ctaButton];

    self.ctaButtonBottomConstraint = [self.ctaContainerView.bottomAnchor
        constraintEqualToAnchor:self.contentOverlayView.safeAreaLayoutGuide.bottomAnchor
        constant:-80];

    [NSLayoutConstraint activateConstraints:@[
        self.ctaButtonBottomConstraint,
        [self.ctaContainerView.leadingAnchor constraintEqualToAnchor:self.contentOverlayView.safeAreaLayoutGuide.leadingAnchor constant:8],
        [self.ctaContainerView.widthAnchor constraintEqualToConstant:40],
        [self.ctaContainerView.heightAnchor constraintEqualToConstant:40],
        [self.ctaButton.centerXAnchor constraintEqualToAnchor:self.ctaContainerView.centerXAnchor],
        [self.ctaButton.centerYAnchor constraintEqualToAnchor:self.ctaContainerView.centerYAnchor],
        [self.ctaButton.widthAnchor constraintEqualToConstant:40],
        [self.ctaButton.heightAnchor constraintEqualToConstant:40],
    ]];
}

#pragma mark - AVPlayerViewControllerDelegate

- (void)playerViewController:(AVPlayerViewController *)playerViewController
willBeginFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController
restoreUserInterfaceForFullScreenExitWithCompletionHandler:(void (^)(BOOL))completionHandler {
    completionHandler(YES);
    if (self.autoplay) {
        [self.player play];
    }
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController
willEndFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.autoplay) {
            [self.player play];
        }
    }];
}

- (void)handleCTATapped {
    if (self.ctaTapHandler) {
        self.ctaTapHandler();
    }
}

- (void)dealloc {
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:@"status"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
