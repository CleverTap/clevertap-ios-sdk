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
/// Last bounds size applied to the container — used to skip duplicate layout passes.
@property (nonatomic, assign) CGSize lastKnownViewSize;
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
    root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
                // initWithWindowScene: lets the scene fully manage the window's geometry,
                // so its bounds automatically update on rotation (unlike initWithFrame: +
                // setting windowScene post-init, which is not scene-managed for resizing).
                CTInAppPassThroughWindow *win = [[CTInAppPassThroughWindow alloc] initWithWindowScene:ws];
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

/// Override to prevent CTInAppDisplayViewController from calling loadView + viewDidLoad on
/// rotation (which would destroy the PiP container). Capture the incoming size so that
/// viewSafeAreaInsetsDidChange can use it for the post-rotation layout pass.
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // Do NOT call super — the parent class calls loadView + viewDidLoad there,
    // which would tear down and rebuild the entire container view.
    self.lastKnownViewSize = size;
}

/// Called by the system after safe area insets are established — the correct place
/// to read valid top/bottom insets (Dynamic Island, status bar, home indicator).
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];

    if (!self.hasPerformedInitialLayout) {
        // On iPad 13" the system can fire this before the view has been laid out,
        // resulting in zero bounds. Skip here and let viewDidLayoutSubviews handle it.
        if (CGSizeEqualToSize(self.view.bounds.size, CGSizeZero)) { return; }
        [self performInitialLayoutAnimated:self.pendingAnimated];
        return;
    }

    // After rotation, safe area insets are recomputed with the new orientation values.
    // Use the current view bounds (already updated for iPad) and the new insets.
    self.lastKnownViewSize = self.view.bounds.size;
    [self.containerView updateBounds:self.view.bounds safeAreaInsets:self.view.safeAreaInsets];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Fallback for iPad 13" where viewSafeAreaInsetsDidChange fires before the view
    // has proper bounds. Once layout completes with non-zero bounds, run initial setup.
    if (!self.hasPerformedInitialLayout && !CGSizeEqualToSize(self.view.bounds.size, CGSizeZero)) {
        [self performInitialLayoutAnimated:self.pendingAnimated];
    }
}

- (void)performInitialLayoutAnimated:(BOOL)animated {
    self.hasPerformedInitialLayout = YES;

    if (!self.containerView) {
        CleverTapLogStaticDebug(@"CTPiPWindowController: containerView is nil, cannot show PiP.");
        [self hide:NO];
        return;
    }

    self.lastKnownViewSize = self.view.bounds.size;
    [self.containerView placeInitialPositionInBounds:self.view.bounds
                                     safeAreaInsets:self.view.safeAreaInsets];

    // UIDeviceOrientationDidChangeNotification only fires on change. If the device
    // is already in a non-portrait orientation when PiP is first shown, we must
    // apply the current orientation now — the notification will not fire for us.
    // Skip when the window has already rotated to match the device (iPad path),
    // since placeInitialPositionInBounds: has already placed the PiP correctly.
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsValidInterfaceOrientation(orientation) &&
        orientation != UIDeviceOrientationPortrait) {
        BOOL isDeviceLandscape = UIDeviceOrientationIsLandscape(orientation);
        BOOL isWindowLandscape = (self.view.bounds.size.width > self.view.bounds.size.height);
        // iPad: window already in landscape → no transform needed.
        // iPhone/other: window is still portrait → apply transform rotation.
        if (!(isDeviceLandscape && isWindowLandscape)) {
            [self.containerView applyDeviceOrientation:orientation
                                          windowBounds:self.view.bounds
                                       safeAreaInsets:self.view.safeAreaInsets];
        }
    }

    [self.containerView.mediaView loadMedia];
    [self animateIn:animated];
}

// MARK: - Animation
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
    [self observeAppLifecycle];

    // Image/GIF: show controls immediately then auto-hide after 3 sec.
    // Video: controls stay hidden until user taps.
    if (self.pipPayload.media.contentType != CTPiPContentTypeVideo) {
        [self.containerView showControlsAndScheduleAutoHide];
    }
}

- (void)hide:(BOOL)animated {
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

// MARK: - App lifecycle (pause/resume video + rotation)

- (void)observeAppLifecycle {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)removeAppLifecycleObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)deviceOrientationDidChange {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (!UIDeviceOrientationIsValidInterfaceOrientation(orientation)) { return; }
    if (!self.hasPerformedInitialLayout || !self.containerView) { return; }

    // UIDeviceOrientationDidChangeNotification fires before UIKit has finished rotating
    // the window on iPad. Defer to the next run-loop turn so viewWillTransitionToSize:
    // can run first, updating lastKnownViewSize to the post-rotation dimensions.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.containerView) { return; }

        BOOL isDeviceLandscape = UIDeviceOrientationIsLandscape(orientation);
        BOOL isWindowLandscape = (strongSelf.lastKnownViewSize.width > strongSelf.lastKnownViewSize.height);
        BOOL hasTransform = !CGAffineTransformIsIdentity(strongSelf.containerView.transform);

        // On iPad the window auto-rotates with the device, so lastKnownViewSize already
        // reflects the new orientation after viewWillTransitionToSize: fires.
        // Matching orientations with no stale transform → window already rotated (iPad).
        // Use updateBounds: to reposition without applying a redundant transform.
        if (isDeviceLandscape == isWindowLandscape && !hasTransform) {
            CGRect windowBounds = CGRectMake(0, 0, strongSelf.lastKnownViewSize.width,
                                                    strongSelf.lastKnownViewSize.height);
            [strongSelf.containerView updateBounds:windowBounds
                                   safeAreaInsets:strongSelf.view.safeAreaInsets];
            return;
        }

        // On iPhone the window stays portrait, so we apply a transform-based rotation.
        CGRect windowBounds = CGRectMake(0, 0, strongSelf.lastKnownViewSize.width,
                                                strongSelf.lastKnownViewSize.height);
        [strongSelf.containerView applyDeviceOrientation:orientation
                                            windowBounds:windowBounds
                                         safeAreaInsets:strongSelf.view.safeAreaInsets];
    });
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
    [self removeAppLifecycleObservers];
}

@end
