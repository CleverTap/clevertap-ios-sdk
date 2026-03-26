#import "CTPiPWindowController.h"
#import "CTPiPPayloadModel.h"
#import <QuartzCore/QuartzCore.h>
#import "CTPiPContainerView.h"
#import "CTPiPMediaView.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTNotificationAction.h"
#import "CTUIUtils.h"
#import "CTUtils.h"
#import "CTConstants.h"

/// Transparent root view that passes through touches not hitting any subview.
@interface CTPiPRootView : UIView
@end

@implementation CTPiPRootView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}
@end

// MARK: -

@interface CTPiPWindowController () <CTPiPContainerViewDelegate>
@property (nonatomic, strong) CTPiPPayloadModel *pipPayload;
@property (nonatomic, strong) CTPiPContainerView *containerView;
@property (nonatomic, strong) NSTimer *ttlTimer;
@property (nonatomic, assign) BOOL isVideoPlaying;
/// Guards against running initial layout more than once.
@property (nonatomic, assign) BOOL hasPerformedInitialLayout;
/// Stores the animated flag from show: so viewSafeAreaInsetsDidChange can use it.
@property (nonatomic, assign) BOOL pendingAnimated;
@end

@implementation CTPiPWindowController

// MARK: - Initialisation

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    self = [super initWithNotification:notification];
    if (self) {
        _pipPayload = [CTPiPPayloadModel modelFromJSON:notification.jsonDescription];
        _isVideoPlaying = YES;
    }
    return self;
}

// MARK: - View lifecycle

- (void)loadView {
    CTPiPRootView *root = [[CTPiPRootView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    root.backgroundColor = UIColor.clearColor;
    self.view = root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.pipPayload || !self.pipPayload.config) {
        return;
    }
    [self buildContainerView];
}

- (void)buildContainerView {
    CTPiPConfigModel *config = self.pipPayload.config;
    CTPiPMediaModel *media = self.pipPayload.media;

    if (!media) {
        CleverTapLogStaticDebug(@"CTPiPWindowController: no valid media in PiP payload, aborting build.");
        return;
    }

    // Build media view
    CTPiPMediaView *mediaView = [[CTPiPMediaView alloc] initWithMedia:media];
    // Pass pre-loaded data from CTInAppNotification if available (images/GIFs)
    mediaView.preloadedImage = self.notification.inAppImage;
    mediaView.preloadedImageData = self.notification.imageData;

    // Build container
    CTPiPContainerView *container = [[CTPiPContainerView alloc]
                                     initWithConfig:config
                                          showClose:self.pipPayload.showClose
                                          mediaView:mediaView];
    container.delegate = self;
    container.autoHideControls = YES;
    [self.view addSubview:container];
    self.containerView = container;
}

// MARK: - show / hide

- (void)show:(BOOL)animated {
    [self initializePiPWindow:animated];
}

- (void)initializePiPWindow:(BOOL)animated {
    self.pendingAnimated = animated;

    if (@available(iOS 13, *)) {
        NSSet *scenes = [CTUIUtils getSharedApplication].connectedScenes;
        for (UIScene *scene in scenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive
                && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                CTInAppPassThroughWindow *win = [[CTInAppPassThroughWindow alloc]
                                                 initWithFrame:ws.coordinateSpace.bounds];
                win.windowScene = ws;
                self.window = win;
                break;
            }
        }
    }

    if (!self.window) {
        self.window = [[CTInAppPassThroughWindow alloc]
                       initWithFrame:UIScreen.mainScreen.bounds];
    }

    self.window.windowLevel = UIWindowLevelAlert - 1;
    self.window.backgroundColor = UIColor.clearColor;
    self.window.alpha = 0;
    self.window.rootViewController = self;
    // Showing the window triggers viewDidLoad → buildContainerView, then the system
    // calls viewSafeAreaInsetsDidChange once safe area insets are computed, where
    // we perform the initial placement and start the entry animation.
    [self.window setHidden:NO];
}

/// Called by the system after safe area insets are established — the correct place
/// to read valid top/bottom insets (Dynamic Island, status bar, home indicator).
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];

    if (!self.hasPerformedInitialLayout) {
        self.hasPerformedInitialLayout = YES;

        if (!self.containerView) {
            CleverTapLogStaticDebug(@"CTPiPWindowController: containerView is nil, cannot show PiP.");
            [self hide:NO];
            return;
        }

        // self.view.safeAreaInsets is now valid — it accounts for Dynamic Island,
        // notch, status bar height, and home indicator.
        [self.containerView placeInitialPositionInBounds:self.view.bounds
                                         safeAreaInsets:self.view.safeAreaInsets];
        [self.containerView.mediaView loadMedia];
        [self animateIn:self.pendingAnimated];
    } else if (self.containerView) {
        // Rotation or other layout change — keep stored safe area in sync so
        // subsequent drag snaps remain safe-area-aware.
        [self.containerView updateBounds:self.view.bounds
                         safeAreaInsets:self.view.safeAreaInsets];
    }
}

- (void)animateIn:(BOOL)animated {
    CTPiPAnimationModel *anim = self.pipPayload.config.animation;
    CTPiPAnimationType type = anim ? anim.type : CTPiPAnimationTypeInstant;

    if (!animated || type == CTPiPAnimationTypeInstant) {
        self.window.alpha = 1.0;
        [self didFinishAnimatingIn];
        return;
    }

    if (type == CTPiPAnimationTypeDissolve) {
        [self applyTimingFunction:anim];
        [UIView animateWithDuration:anim.duration
                         animations:^{ self.window.alpha = 1.0; }
                         completion:^(BOOL f) { [self didFinishAnimatingIn]; }];

    } else if (type == CTPiPAnimationTypeMoveIn) {
        CGRect finalFrame = self.containerView.frame;
        CGRect startFrame = [self startFrameForMoveIn:finalFrame direction:anim.moveInDirection];
        self.containerView.frame = startFrame;
        self.window.alpha = 1.0;

        [self applyTimingFunction:anim];
        [UIView animateWithDuration:anim.duration
                              delay:0
                            options:[self animationOptionsForEasing:anim.easing]
                         animations:^{ self.containerView.frame = finalFrame; }
                         completion:^(BOOL f) { [self didFinishAnimatingIn]; }];
    }
}

/// Returns UIViewAnimationOptions curve flag for non-bezier easings.
- (UIViewAnimationOptions)animationOptionsForEasing:(CTPiPAnimationEasing)easing {
    switch (easing) {
        case CTPiPAnimationEasingLinear:     return UIViewAnimationOptionCurveLinear;
        case CTPiPAnimationEasingEaseIn:     return UIViewAnimationOptionCurveEaseIn;
        case CTPiPAnimationEasingEaseOut:    return UIViewAnimationOptionCurveEaseOut;
        case CTPiPAnimationEasingEaseInOut:
        case CTPiPAnimationEasingCubicBezier:
        default:                             return UIViewAnimationOptionCurveEaseInOut;
    }
}

/// For cubic-bezier easing, sets CATransaction timing function before the UIView animation block.
- (void)applyTimingFunction:(CTPiPAnimationModel *)anim {
    if (anim.easing != CTPiPAnimationEasingCubicBezier) { return; }
    CAMediaTimingFunction *tf = [CAMediaTimingFunction functionWithControlPoints:anim.bezierX1
                                                                                :anim.bezierY1
                                                                                :anim.bezierX2
                                                                                :anim.bezierY2];
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:tf];
    // CATransaction commit is called after the animation block is set up in animateIn:
    // Use dispatch_async to commit after UIView picks it up.
    dispatch_async(dispatch_get_main_queue(), ^{ [CATransaction commit]; });
}

/// Calculates the off-screen start frame for a move-in animation.
- (CGRect)startFrameForMoveIn:(CGRect)finalFrame direction:(CTPiPMoveInDirection)direction {
    CGFloat x = finalFrame.origin.x;
    CGFloat y = finalFrame.origin.y;
    switch (direction) {
        case CTPiPMoveInDirectionTop:    y = -finalFrame.size.height; break;
        case CTPiPMoveInDirectionBottom: y = self.view.bounds.size.height; break;
        case CTPiPMoveInDirectionLeft:   x = -finalFrame.size.width; break;
        case CTPiPMoveInDirectionRight:  x = self.view.bounds.size.width; break;
    }
    return CGRectMake(x, y, finalFrame.size.width, finalFrame.size.height);
}

- (void)didFinishAnimatingIn {
    if (self.delegate) {
        [self.delegate notificationDidShow:self.notification];
    }
    [self startTTLTimerIfNeeded];
    [self observeAppLifecycle];

    // Image/GIF: show controls immediately then auto-hide after 3 sec.
    // Video: controls stay hidden until user taps.
    if (self.pipPayload.media.contentType != CTPiPContentTypeVideo) {
        [self.containerView showControlsAndScheduleAutoHide];
    }
}

- (void)hide:(BOOL)animated {
    [self stopTTLTimer];
    [self removeAppLifecycleObservers];
    [self.containerView.mediaView releaseMedia];

    __weak typeof(self) weakSelf = self;
    void (^completion)(void) = ^{
        if (weakSelf.window) {
            [weakSelf.window setHidden:YES];
            weakSelf.window = nil;
        }
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(notificationDidDismiss:fromViewController:)]) {
            [weakSelf.delegate notificationDidDismiss:weakSelf.notification fromViewController:weakSelf];
        }
    };

    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.window.alpha = 0;
        } completion:^(BOOL finished) {
            completion();
        }];
    } else {
        completion();
    }
}

// MARK: - TTL

- (void)startTTLTimerIfNeeded {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval remaining = self.notification.timeToLive - now;
    if (remaining > 0) {
        self.ttlTimer = [NSTimer scheduledTimerWithTimeInterval:remaining
                                                        target:self
                                                      selector:@selector(ttlExpired)
                                                      userInfo:nil
                                                       repeats:NO];
    }
}

- (void)stopTTLTimer {
    [self.ttlTimer invalidate];
    self.ttlTimer = nil;
}

- (void)ttlExpired {
    [CTUtils runSyncMainQueue:^{
        [self hide:YES];
    }];
}

// MARK: - App lifecycle (pause/resume video)

- (void)observeAppLifecycle {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)removeAppLifecycleObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)appDidEnterBackground {
    [self.containerView.mediaView pause];
}

- (void)appWillEnterForeground {
    if (self.isVideoPlaying) {
        [self.containerView.mediaView play];
    }
}

// MARK: - CTPiPContainerViewDelegate

- (void)pipContainerDidTapClose {
    [self hide:YES];
}

- (void)pipContainerDidTapCTA {
    CTPiPOnClickModel *onClick = self.pipPayload.config.onClick;
    if (!onClick) {
        [self hide:YES];
        return;
    }
    [self executeCTAWithOnClick:onClick];
}

- (void)pipContainerDidTapMute {
    [self.containerView.mediaView toggleMute];
    BOOL isMuted = self.containerView.mediaView.isMuted;
    [self.containerView.controlsView updateMuteButtonMuted:isMuted];
}

- (void)pipContainerDidTapPlayPause {
    if (self.isVideoPlaying) {
        [self.containerView.mediaView pause];
        self.isVideoPlaying = NO;
    } else {
        [self.containerView.mediaView play];
        self.isVideoPlaying = YES;
    }
    [self.containerView.controlsView updatePlayPauseButtonPlaying:self.isVideoPlaying];
}

- (void)pipContainerDidToggleExpand:(BOOL)isExpanded {
    // Drag is disabled in expanded state (container handles internally)
}

// MARK: - CTA Execution

- (void)executeCTAWithOnClick:(CTPiPOnClickModel *)onClick {
    // Record clicked event via delegate
    CTNotificationAction *action = [self actionForOnClick:onClick];
    if (action && self.delegate &&
        [self.delegate respondsToSelector:@selector(handleNotificationAction:forNotification:withExtras:)]) {
        NSMutableDictionary *extras = [NSMutableDictionary new];
        NSString *campaignId = self.notification.campaignId ?: @"";
        extras[CLTAP_NOTIFICATION_ID_TAG] = campaignId;
        if (action.actionURL) {
            extras[CLTAP_PROP_WZRK_DL] = action.actionURL.absoluteString;
        }
        [self.delegate handleNotificationAction:action forNotification:self.notification withExtras:extras];
    }

    if (onClick.close || onClick.type == CTPiPOnClickActionTypeClose) {
        [self hide:YES];
    }
}

- (nullable CTNotificationAction *)actionForOnClick:(CTPiPOnClickModel *)onClick {
    switch (onClick.type) {
        case CTPiPOnClickActionTypeClose:
            return [[CTNotificationAction alloc] initWithCloseAction];
        case CTPiPOnClickActionTypeURL: {
            NSString *urlString = onClick.iosURL;
            if (urlString.length > 0) {
                NSURL *url = [NSURL URLWithString:urlString];
                if (url) return [[CTNotificationAction alloc] initWithOpenURL:url];
            }
            return [[CTNotificationAction alloc] initWithCloseAction];
        }
        case CTPiPOnClickActionTypeKV: {
            NSDictionary *json = @{@"type": @"kv", @"kv": onClick.kv ?: @{}};
            return [[CTNotificationAction alloc] initWithJSON:json];
        }
        case CTPiPOnClickActionTypeCustomCode:
        case CTPiPOnClickActionTypeUnknown:
            return nil;
    }
}

// MARK: - Dealloc

- (void)dealloc {
    [self stopTTLTimer];
    [self removeAppLifecycleObservers];
}

@end
