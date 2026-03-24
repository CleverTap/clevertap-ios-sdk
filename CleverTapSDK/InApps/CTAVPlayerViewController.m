
#import "CTAVPlayerViewController.h"
#import "CTInAppNotification.h"
#import "CTUIUtils.h"

@interface CTAVPlayerViewController ()<UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate>

@property (nonatomic, strong) CTInAppNotification *notification;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIVisualEffectView *ctaContainerView;
@property (nonatomic, strong) UIButton *ctaButton;
@property (nonatomic, weak) UITapGestureRecognizer *overlayTap;
@property (nonatomic, assign) BOOL ctaButtonVisible;
@property (nonatomic, strong) NSLayoutConstraint *ctaButtonLeadingConstraint;
@property (nonatomic, assign) BOOL isFullscreen;

@end

@implementation CTAVPlayerViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification muted:(BOOL)muted autoplay:(BOOL)autoplay {
    self = [super init];
    if (self) {
        _notification = notification;
        _muted = muted;
        _autoplay = autoplay;
        _loopVideo = YES; // Default to looping
        AVPlayerItem *avPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.notification.mediaUrl]];
        self.player = [AVPlayer playerWithPlayerItem:avPlayerItem];
        self.player.muted = muted;

        // Setup looping notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
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
    
    for (UIView *sub in self.view.subviews) {
            if (sub != self.contentOverlayView) {
                for (UIView *control in sub.subviews) {
                    NSLog(@"[CTA] control: %@ frame: %@", control.class, NSStringFromCGRect(control.frame));
                }
            }
        }
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
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    self.ctaContainerView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.ctaContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.ctaContainerView.layer.cornerRadius = 14;
    self.ctaContainerView.layer.masksToBounds = YES;
    self.ctaContainerView.alpha = 0;
    [self.contentOverlayView addSubview:self.ctaContainerView];

    // Button lives inside the blur's contentView
    self.ctaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.ctaButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *icon = [CTUIUtils getImageForName:@"inapp_cta"];
    if (!icon) {
        UIImageSymbolConfiguration *symConfig = [UIImageSymbolConfiguration
            configurationWithPointSize:17 weight:UIImageSymbolWeightBold];
        icon = [[UIImage systemImageNamed:@"arrow.up.right"]
            imageByApplyingSymbolConfiguration:symConfig];
    }
    [self.ctaButton setImage:icon forState:UIControlStateNormal];
    self.ctaButton.tintColor = [UIColor whiteColor];
    [self.ctaButton addTarget:self action:@selector(handleCTATapped) forControlEvents:UIControlEventTouchUpInside];
    [self.ctaContainerView.contentView addSubview:self.ctaButton];

    [self addOverlayTapToView:self.view];

    self.ctaButtonLeadingConstraint = [self.ctaContainerView.leadingAnchor
        constraintEqualToAnchor:self.contentOverlayView.safeAreaLayoutGuide.leadingAnchor
        constant:[self ctaLeadingConstant]];

    [NSLayoutConstraint activateConstraints:@[
        self.ctaButtonLeadingConstraint,
        [self.ctaContainerView.topAnchor constraintEqualToAnchor:self.contentOverlayView.safeAreaLayoutGuide.topAnchor constant:8],
        [self.ctaContainerView.widthAnchor constraintEqualToConstant:40],
        [self.ctaContainerView.heightAnchor constraintEqualToConstant:40],
        [self.ctaButton.centerXAnchor constraintEqualToAnchor:self.ctaContainerView.centerXAnchor],
        [self.ctaButton.centerYAnchor constraintEqualToAnchor:self.ctaContainerView.centerYAnchor],
        [self.ctaButton.widthAnchor constraintEqualToConstant:40],
        [self.ctaButton.heightAnchor constraintEqualToConstant:40],
    ]];
}

/// Returns the leading offset based on fullscreen state and screen width.
/// In fullscreen, the top-left area has ~2 system buttons (~44pt each),
/// so we need more clearance. Safe area handles notch/island offsets automatically.
- (CGFloat)ctaLeadingConstant {
    return self.isFullscreen ? 117.0 : 113.0;
}

- (CGFloat)rightmostLeftButtonMaxX {
    CGFloat maxX = 0;
    for (UIView *sub in self.view.subviews) {
        if (sub == self.contentOverlayView) continue;
        maxX = [self findRightmostLeftButtonMaxX:sub currentMax:maxX];
    }
    return maxX;
}

- (CGFloat)findRightmostLeftButtonMaxX:(UIView *)view currentMax:(CGFloat)currentMax {
    CGFloat screenMidX = self.view.bounds.size.width / 2.0;
    // Only consider buttons on the left half
    if ([view isKindOfClass:[UIButton class]] &&
        CGRectGetMidX(view.frame) < screenMidX &&
        !CGRectIsEmpty(view.frame)) {
        currentMax = MAX(currentMax, CGRectGetMaxX(view.frame));
    }
    for (UIView *child in view.subviews) {
        CGFloat childMax = [self findRightmostLeftButtonMaxX:child currentMax:currentMax];
        currentMax = MAX(currentMax, childMax);
    }
    return currentMax;
}

- (void)updateCTAButtonPosition {
    self.ctaButtonLeadingConstraint.constant = [self ctaLeadingConstant];
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentOverlayView layoutIfNeeded];
    }];
}

- (void)addOverlayTapToView:(UIView *)view {
    // Remove previous if any
    if (self.overlayTap) {
        [self.overlayTap.view removeGestureRecognizer:self.overlayTap];
    }
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleOverlayTapped)];
    tap.cancelsTouchesInView = NO;
    tap.delaysTouchesBegan = NO;
    tap.delegate = self;
    [view addGestureRecognizer:tap];
    self.overlayTap = tap;
    NSLog(@"[CTA] gesture added to: %@ userInteractionEnabled: %d", view, view.userInteractionEnabled);
}

#pragma mark - AVPlayerViewControllerDelegate

- (void)playerViewController:(AVPlayerViewController *)playerViewController
willBeginFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self hideCTAButton];
    self.isFullscreen = YES;
    [self updateCTAButtonPosition];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self attachFullscreenGestureToPlayerViewController:playerViewController attempts:10];
        
    }];
}

- (void)attachFullscreenGestureToPlayerViewController:(AVPlayerViewController *)playerViewController
                                             attempts:(int)attempts {
    if (attempts <= 0) {
        NSLog(@"[CTA] gave up waiting for fullscreen window");
        return;
    }

    // Try the player's window first
    UIWindow *window = playerViewController.view.window;
    
    // If nil, search all active scene windows for the fullscreen one
    if (!window) {
        NSSet *connectedScenes = [CTUIUtils getSharedApplication].connectedScenes;
        for (UIWindowScene *scene in connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *w in scene.windows) {
                if (w.isKeyWindow && w != self.view.window) {
                    window = w;
                    break;
                }
            }
        }
    }

    if (window) {
        [self addOverlayTapToView:window];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self attachFullscreenGestureToPlayerViewController:playerViewController attempts:attempts - 1];
        });
    }
}


- (void)playerViewController:(AVPlayerViewController *)playerViewController
willEndFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self hideCTAButton];
    self.isFullscreen = NO;
    [self updateCTAButtonPosition];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // back to inline — restore gesture on self.view
        [self addOverlayTapToView:self.view];
        
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES; // always begin, don't let AVPlayerViewController block us
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    UIView *v = touch.view;
    while (v) {
        if (v == self.ctaButton) return NO;
        if ([v isKindOfClass:[UIButton class]]) return NO;
        if ([v isKindOfClass:[UISlider class]]) return NO;
        v = v.superview;
    }
    return YES;
}

- (void)handleOverlayTapped {
    if (self.ctaButtonVisible) {
        [self hideCTAButton];
    } else {
        [self showCTAButton];
    }
}

- (void)showCTAButton {
    self.ctaButtonVisible = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(hideCTAButton)
                                               object:nil];
    [UIView animateWithDuration:0.2 animations:^{
        self.ctaContainerView.alpha = 1.0;
    }];
    [self performSelector:@selector(hideCTAButton) withObject:nil afterDelay:3.0];
}

- (void)hideCTAButton {
    self.ctaButtonVisible = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(hideCTAButton)
                                               object:nil];
    [UIView animateWithDuration:0.2 animations:^{
        self.ctaContainerView.alpha = 0.0;
    }];
}

- (void)handleCTATapped {
    if (self.ctaTapHandler) {
        self.ctaTapHandler();
    }
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
