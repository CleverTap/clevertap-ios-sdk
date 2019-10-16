#import "CTInAppDisplayViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTInAppResources.h"

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

@implementation CTInAppDisplayViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    self = [super init];
    if (self) {
        _notification = notification;
    }
    return self;
}

#if !(TARGET_OS_TV)
- (instancetype)initWithNotification:(CTInAppNotification *)notification jsInterface:(CleverTapJSInterface *)jsInterface {
    self = [self initWithNotification:notification];
    return self;
}
#endif

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
         [self loadView];
         [self viewDidLoad];
     } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#if !(TARGET_OS_TV)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (_notification.hasPortrait && _notification.hasLandscape) {
        return UIInterfaceOrientationMaskAll;
    } else if (_notification.hasPortrait) {
        return (UIInterfaceOrientationPortrait | UIInterfaceOrientationPortraitUpsideDown);
    } else if (_notification.hasLandscape) {
        return (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight);
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

#endif

-(void)show:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

-(void)hide:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

- (void)showFromWindow:(BOOL)animated {
    
    if (!self.notification) return;
    
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.window.alpha = 0;
    self.window.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    self.window.windowLevel = UIWindowLevelNormal;
    self.window.rootViewController = self;
    [self.window setHidden:NO];
    
    void (^completionBlock)(void) = ^ {
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidShow:fromViewController:)]) {
            [self.delegate notificationDidShow:self.notification fromViewController:self];
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

-(void)hideFromWindow:(BOOL)animated {
    void (^completionBlock)(void) = ^ {
        [self.window removeFromSuperview];
        self.window = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidDismiss:fromViewController:)]) {
            [self.delegate notificationDidDismiss:self.notification fromViewController:self];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else {
        completionBlock();
    }
}

#pragma mark CTInAppPassThroughViewDelegate
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
        buttonView.layer.borderColor = [[CTInAppUtils ct_colorWithHexString:button.borderColor] CGColor];
    }
    
    [buttonView setBackgroundColor:[CTInAppUtils ct_colorWithHexString:button.backgroundColor]];
    [buttonView setTitleColor:[CTInAppUtils ct_colorWithHexString:button.textColor] forState:UIControlStateNormal];
    [buttonView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView setTitle:button.text forState:UIControlStateNormal];
    return buttonView;
}

- (BOOL)deviceOrientationIsLandscape {
#if (TARGET_OS_TV)
    return nil;
#else
    UIApplication *sharedApplication = [CTInAppResources getSharedApplication];
    return UIInterfaceOrientationIsLandscape(sharedApplication.statusBarOrientation);
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
    NSURL *buttonCTA = button.actionURL;
    NSString *buttonText = button.text;
    NSString *campaignId = self.notification.campaignId;
    NSDictionary *buttonCustomExtras = button.customExtras;
    
    if (campaignId == nil) {
        campaignId = @"";
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleNotificationCTA:buttonCustomExtras:forNotification:fromViewController:withExtras:)]) {
        [self.delegate handleNotificationCTA:buttonCTA buttonCustomExtras:buttonCustomExtras forNotification:self.notification fromViewController:self withExtras:@{@"wzrk_id":campaignId, @"wzrk_c2a": buttonText}];
    }
}

- (void)handleImageTapGesture{
    CTNotificationButton *button = self.notification.buttons[0];
    NSURL *buttonCTA = button.actionURL;
    NSString *buttonText = @"image";
    NSString *campaignId = self.notification.campaignId;
    NSDictionary *buttonCustomExtras = button.customExtras;
    
    if (campaignId == nil) {
        campaignId = @"";
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleNotificationCTA:buttonCustomExtras:forNotification:fromViewController:withExtras:)]) {
        [self.delegate handleNotificationCTA:buttonCTA buttonCustomExtras:buttonCustomExtras forNotification:self.notification fromViewController:self withExtras:@{@"wzrk_id":campaignId, @"wzrk_c2a": buttonText}];
    }
}

@end
