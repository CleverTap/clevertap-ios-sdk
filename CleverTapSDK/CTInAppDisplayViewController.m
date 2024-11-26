#import "CTInAppDisplayViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTUIUtils.h"

@implementation CTInAppPassThroughWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return view == self ? nil : view;
}

@end

@implementation CTInAppPassThroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(viewWillPassThroughTouch)]) {
            [self.delegate viewWillPassThroughTouch];
        }
        return nil;
    }
    return view;
}
@end

@interface CTInAppDisplayViewController ()

@property (nonatomic, assign) BOOL waitingForSceneWindow;
@property (nonatomic, assign) BOOL animated;

@end

@implementation CTInAppDisplayViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    self = [super init];
    if (self) {
        _notification = notification;
        if (@available(iOS 13, tvOS 13.0, *)) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(sceneDidActivate:) name:UISceneDidActivateNotification
                                                       object:nil];
        }
    }
    return self;
}

// Notification will not be posted if the scene became active before registering the observer.
// However, this means that there is already an active scene when the controller is initialized.
// In this case, we do not need the notification, since showFromWindow will directly find the window from the already active scene and not wait for it.
- (void)sceneDidActivate:(NSNotification *)notification
API_AVAILABLE(ios(13.0), tvos(13.0)) {
    if (!self.window && self.waitingForSceneWindow) {
        CleverTapLogStaticDebug(@"%@:%@: Scene did activate. Showing from window.", [CTInAppDisplayViewController class], self);
        self.waitingForSceneWindow = NO;
        [self showFromWindow:self.animated];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self loadView];
        [self viewDidLoad];
    } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#if !(TARGET_OS_TV)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIWindow *window = [CTUIUtils getKeyWindow];
    UIInterfaceOrientationMask windowSupportedOrientations = [[CTUIUtils getSharedApplication] supportedInterfaceOrientationsForWindow:window];
    
    if (_notification.hasPortrait && _notification.hasLandscape) {
        return windowSupportedOrientations;
    }
    if (_notification.hasPortrait) {
        if ([self isOrientationSupported:UIInterfaceOrientationPortrait mask:windowSupportedOrientations]
            && [self isOrientationSupported:UIInterfaceOrientationPortraitUpsideDown mask:windowSupportedOrientations]) {
            return (UIInterfaceOrientationPortrait | UIInterfaceOrientationPortraitUpsideDown);
        }
        if ([self isOrientationSupported:UIInterfaceOrientationPortrait mask:windowSupportedOrientations]) {
            return UIInterfaceOrientationMaskPortrait;
        }
        if ([self isOrientationSupported:UIInterfaceOrientationPortraitUpsideDown mask:windowSupportedOrientations]) {
            return UIInterfaceOrientationMaskPortraitUpsideDown;
        }
        return windowSupportedOrientations;
    }
    if (_notification.hasLandscape) {
        if ([self isOrientationSupported:UIInterfaceOrientationLandscapeLeft mask:windowSupportedOrientations]
            && [self isOrientationSupported:UIInterfaceOrientationLandscapeRight mask:windowSupportedOrientations]) {
            return (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight);
        }
        if ([self isOrientationSupported:UIInterfaceOrientationLandscapeLeft mask:windowSupportedOrientations]) {
            return UIInterfaceOrientationMaskLandscapeLeft;
        }
        if ([self isOrientationSupported:UIInterfaceOrientationLandscapeRight mask:windowSupportedOrientations]) {
            return UIInterfaceOrientationMaskLandscapeRight;
        }
        return windowSupportedOrientations;
    }
    return windowSupportedOrientations;
}

- (BOOL)isOrientationSupported:(UIInterfaceOrientation)orientation mask:(UIInterfaceOrientationMask)mask {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return (mask & UIInterfaceOrientationMaskPortrait) != 0;
        case UIInterfaceOrientationPortraitUpsideDown:
            return (mask & UIInterfaceOrientationMaskPortraitUpsideDown) != 0;
        case UIInterfaceOrientationLandscapeLeft:
            return (mask & UIInterfaceOrientationMaskLandscapeLeft) != 0;
        case UIInterfaceOrientationLandscapeRight:
            return (mask & UIInterfaceOrientationMaskLandscapeRight) != 0;
        default:
            return NO;
    }
}
#endif

- (void)show:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

- (void)hide:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

- (void)initializeWindowOfClass:(Class)windowClass animated:(BOOL)animated {
    if (@available(iOS 13, tvOS 13.0, *)) {
        NSSet *connectedScenes = [CTUIUtils getSharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                self.window = [[windowClass alloc] initWithFrame:
                               windowScene.coordinateSpace.bounds];
                self.window.windowScene = windowScene;
            }
        }
    } else {
        self.window = [[windowClass alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    
    if (!self.window) {
        CleverTapLogStaticDebug(@"%@:%@: UIWindow not initialized.", [CTInAppDisplayViewController class], self);
        if (@available(iOS 13, tvOS 13.0, *)) {
            // No active scene found to initialize the window from. Cannot present the view.
            // Once a scene becomes active, the UISceneDidActivateNotification is posted.
            // sceneDidActivate: will call again showFromWindow from the notification,
            // so window is initialized from the scene that became active
            CleverTapLogStaticDebug(@"%@:%@: Waiting for active scene.", [CTInAppDisplayViewController class], self);
            self.animated = animated;
            self.waitingForSceneWindow = YES;
        }
    } else {
        CleverTapLogStaticInternal(@"%@:%@: Window initialized.", [CTInAppDisplayViewController class], self);
    }
}

- (void)showFromWindow:(BOOL)animated {
    if (!self.notification) return;
    
    [self initializeWindowOfClass:UIWindow.class animated:animated];
    if (!self.window) {
        return;
    }
    self.window.alpha = 0;
    self.window.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    self.window.windowLevel = UIWindowLevelNormal;
    self.window.rootViewController = self;
    [self.window setHidden:NO];
    
    void (^completionBlock)(void) = ^ {
        if (self.delegate) {
            [self.delegate notificationDidShow:self.notification];
        }
    };
    
    if (animated) {
        CGRect windowFrame = self.window.frame;
        CGRect transformWindowFrame = CGRectMake(0, -(windowFrame.size.height + windowFrame.origin.y),  [UIScreen mainScreen].bounds.size.width, windowFrame.size.height);
        self.window.frame = transformWindowFrame;
        
        [UIView animateWithDuration:0.33 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:10 options:UIViewAnimationOptionTransitionFlipFromTop animations:^{
            self.window.alpha = 1.0;
            self.window.frame = windowFrame;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } else {
        self.window.alpha = 1.0;
        completionBlock();
    }
}

- (void)hideFromWindow:(BOOL)animated {
    [self hideFromWindow:animated withCompletion:nil];
}

- (void)hideFromWindow:(BOOL)animated withCompletion:(void (^)(void))completion {
    __weak typeof(self) weakSelf = self;
    void (^completionBlock)(void) = ^ {
        if (!weakSelf) {
            return;
        }
        if (weakSelf.window) {
            [weakSelf.window removeFromSuperview];
            weakSelf.window = nil;
        }
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(notificationDidDismiss:fromViewController:)]) {
            [weakSelf.delegate notificationDidDismiss:weakSelf.notification fromViewController:weakSelf];
        }
        if (completion) {
            completion();
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.window.alpha = 0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else {
        completionBlock();
    }
}

#pragma mark - CTInAppPassThroughViewDelegate

- (void)viewWillPassThroughTouch {
    [self hide:NO];
}


#pragma mark - Setup Buttons

- (UIButton*)setupViewForButton:(UIButton *)buttonView withData:(CTNotificationButton *)button withIndex:(NSInteger)index {
    [buttonView setTag: index];
    buttonView.titleLabel.adjustsFontSizeToFitWidth = YES;
    buttonView.hidden = NO;
    if (_notification.inAppType != CTInAppTypeHeader && _notification.inAppType != CTInAppTypeFooter) {
        buttonView.layer.borderWidth = 1.0f;
        buttonView.layer.cornerRadius = [button.borderRadius floatValue];
        buttonView.layer.borderColor = [[CTUIUtils ct_colorWithHexString:button.borderColor] CGColor];
    }
    
    [buttonView setBackgroundColor:[CTUIUtils ct_colorWithHexString:button.backgroundColor]];
    [buttonView setTitleColor:[CTUIUtils ct_colorWithHexString:button.textColor] forState:UIControlStateNormal];
    [buttonView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView setTitle:button.text forState:UIControlStateNormal];
    return buttonView;
}

- (BOOL)deviceOrientationIsLandscape {
#if (TARGET_OS_TV)
    return nil;
#else
    return [CTUIUtils isDeviceOrientationLandscape];
#endif
}


#pragma mark - Actions

- (void)tappedDismiss {
    [self hide:YES];
}

- (void)buttonTapped:(UIButton*)button {
    [self handleButtonClickFromIndex:(int)button.tag];
    [self hide:YES];
}

- (void)handleButtonClickFromIndex:(int)index {
    CTNotificationButton *button = self.notification.buttons[index];
    NSString *buttonText = button.text;
    NSString *campaignId = self.notification.campaignId;
    if (campaignId == nil) {
        campaignId = @"";
    }
    
    if (self.notification.isLocalInApp) {
        if  (index == 0) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(handleInAppPushPrimer:fromViewController:withFallbackToSettings:)]) {
                [self.delegate handleInAppPushPrimer:self.notification
                                  fromViewController:self
                              withFallbackToSettings:self.notification.fallBackToNotificationSettings];
            }
        } else if (index == 1) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(inAppPushPrimerDidDismissed)]) {
                [self.delegate inAppPushPrimerDidDismissed];
            }
        }
        return;
    }
    
    // For showing Push Permission through InApp Campaign, positive button type is "rfp".
    if (button.type == CTInAppActionTypeRequestForPermission) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(handleInAppPushPrimer:fromViewController:withFallbackToSettings:)]) {
            [self.delegate handleInAppPushPrimer:self.notification
                              fromViewController:self
                          withFallbackToSettings:button.fallbackToSettings];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleNotificationAction:forNotification:withExtras:)]) {
        [self.delegate handleNotificationAction:button.action forNotification:self.notification withExtras:@{CLTAP_NOTIFICATION_ID_TAG:campaignId, CLTAP_PROP_WZRK_CTA: buttonText}];
    }
}

- (void)triggerInAppAction:(CTNotificationAction *)action callToAction:(NSString *)callToAction buttonId:(NSString *)buttonId {
    NSMutableDictionary *extras = [NSMutableDictionary new];
    
    if (action.type == CTInAppActionTypeOpenURL) {
        NSString *urlString = [action.actionURL absoluteString];
        NSMutableDictionary *mutableParams = [CTInAppUtils getParametersFromURL:urlString];
        
        if (mutableParams[@"params"]) {
            extras = [mutableParams[@"params"] mutableCopy];
            
            // Use the url from the deeplink to update the action if such is set
            if (mutableParams[@"deeplink"]) {
                action = [[CTNotificationAction alloc] initWithOpenURL:mutableParams[@"deeplink"]];
            }
        }
    }
    
    // callToAction, buttonId and notification id take precedence over
    // the URL parameters if those have been set in the URL
    if (callToAction) {
        extras[CLTAP_PROP_WZRK_CTA] = callToAction;
    }
    if (buttonId) {
        extras[@"button_id"] = buttonId;
    }
    NSString *campaignId = self.notification.campaignId;
    if (campaignId == nil) {
        campaignId = @"";
    }
    extras[CLTAP_NOTIFICATION_ID_TAG] = campaignId;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(handleNotificationAction:forNotification:withExtras:)]) {
        [self.delegate handleNotificationAction:action forNotification:self.notification withExtras:extras];
    }
    [self hide:YES];
}

- (void)handleImageTapGesture {
    CTNotificationButton *button = self.notification.buttons[0];
    NSString *buttonText = @"";
    NSString *campaignId = self.notification.campaignId;
    if (campaignId == nil) {
        campaignId = @"";
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleNotificationAction:forNotification:withExtras:)]) {
        [self.delegate handleNotificationAction:button.action forNotification:self.notification withExtras:@{CLTAP_NOTIFICATION_ID_TAG:campaignId, CLTAP_PROP_WZRK_CTA: buttonText}];
    }
}

- (void)dealloc {
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

@end
