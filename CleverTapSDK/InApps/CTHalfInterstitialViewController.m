#import "CTHalfInterstitialViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTDismissButton.h"
#import "CTInAppUtils.h"
#import "CTUIUtils.h"

@interface CTHalfInterstitialViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *buttonsContainer;
@property (nonatomic, strong) IBOutlet UIView *secondButtonContainer;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *bodyLabel;
@property (nonatomic, strong) IBOutlet UIButton *firstButton;
@property (nonatomic, strong) IBOutlet UIButton *secondButton;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;

#if TARGET_OS_TV
@property (nonatomic, strong) UIFocusGuide *buttonLeftFocusGuide;
@property (nonatomic, strong) UIFocusGuide *buttonRightFocusGuide;
#endif

@end

@implementation CTHalfInterstitialViewController


#pragma mark - UIViewController Lifecycle

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTHalfInterstitialViewController class])] owner:self options:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutNotification];
#if TARGET_OS_TV
    [self setupFocusGuides];
    [self setNeedsFocusUpdate];
    [self updateFocusIfNeeded];
#endif
}

#if TARGET_OS_TV

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;   // 1920
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;  // 1080
    CGFloat margin  = 160.0f;
    CGFloat cW = screenW * 0.70f;           // 1344
    CGFloat cH = screenH - 2.0f * margin;   // 760
    CGFloat cX = (screenW - cW) * 0.5f;     // 288
    CGFloat cY = margin;                     // 160
    self.containerView.frame = CGRectMake(cX, cY, cW, cH);
    self.closeButton.frame = CGRectMake(cX + cW - 15.0f, cY - 15.0f, 44.0f, 44.0f);
}

- (BOOL)canBecomeFocused {
    return YES;
}

- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments {
    if (!self.firstButton.isHidden) return @[self.firstButton];
    if (!self.secondButton.isHidden) return @[self.secondButton];
    if (!self.closeButton.isHidden) return @[self.closeButton];
    return [super preferredFocusEnvironments];
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    
    [coordinator addCoordinatedAnimations:^{
        
        if (context.nextFocusedView == self.closeButton) {
            self.closeButton.transform = CGAffineTransformMakeScale(1.15, 1.15);
        }
        if (context.previouslyFocusedView == self.closeButton) {
            self.closeButton.transform = CGAffineTransformIdentity;
        }
        if (context.previouslyFocusedView == self.firstButton) {
            self.firstButton.transform = CGAffineTransformIdentity;
        }
        if (context.previouslyFocusedView == self.secondButton) {
            self.secondButton.transform = CGAffineTransformIdentity;
        }
        
    } completion:nil];
}

- (void)setupFocusGuides {
    if (!self.closeButton.isHidden) {
        
        id<UIFocusEnvironment> downTarget = !self.firstButton.isHidden
            ? (id<UIFocusEnvironment>)self.firstButton
            : (id<UIFocusEnvironment>)self.secondButton;

        UIFocusGuide *upGuide = [UIFocusGuide new];
        [self.view addLayoutGuide:upGuide];
        [NSLayoutConstraint activateConstraints:@[
            [upGuide.bottomAnchor   constraintEqualToAnchor:self.buttonsContainer.topAnchor],
            [upGuide.heightAnchor   constraintEqualToConstant:100.0],
            [upGuide.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
            [upGuide.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        ]];
        upGuide.preferredFocusEnvironments = @[self.closeButton];

        UIFocusGuide *downGuide = [UIFocusGuide new];
        [self.view addLayoutGuide:downGuide];
        [NSLayoutConstraint activateConstraints:@[
            [downGuide.topAnchor      constraintEqualToAnchor:self.view.topAnchor constant:200.0],
            [downGuide.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor],
            [downGuide.leadingAnchor  constraintEqualToAnchor:self.view.trailingAnchor constant:-400.0],
            [downGuide.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        ]];
        downGuide.preferredFocusEnvironments = @[downTarget];
        
        UIFocusGuide *leftCloseGuide = [UIFocusGuide new];
        [self.view addLayoutGuide:leftCloseGuide];
        [NSLayoutConstraint activateConstraints:@[
            [leftCloseGuide.topAnchor      constraintEqualToAnchor:self.view.topAnchor constant:60.0],
            [leftCloseGuide.bottomAnchor   constraintEqualToAnchor:self.view.topAnchor constant:200.0],
            [leftCloseGuide.leadingAnchor  constraintEqualToAnchor:self.view.trailingAnchor constant:-440.0],
            [leftCloseGuide.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-370.0],
        ]];
        leftCloseGuide.preferredFocusEnvironments = @[downTarget];
    }

    if (self.firstButton.isHidden || self.secondButton.isHidden) return;

    UIFocusGuide *leftGuide = [UIFocusGuide new];
    [self.buttonsContainer addLayoutGuide:leftGuide];
    [NSLayoutConstraint activateConstraints:@[
        [leftGuide.leadingAnchor  constraintEqualToAnchor:self.buttonsContainer.leadingAnchor],
        [leftGuide.trailingAnchor constraintEqualToAnchor:self.secondButton.leadingAnchor],
        [leftGuide.topAnchor      constraintEqualToAnchor:self.buttonsContainer.topAnchor],
        [leftGuide.bottomAnchor   constraintEqualToAnchor:self.buttonsContainer.bottomAnchor],
    ]];
    leftGuide.preferredFocusEnvironments = @[self.firstButton];
    self.buttonLeftFocusGuide = leftGuide;

    UIFocusGuide *rightGuide = [UIFocusGuide new];
    [self.buttonsContainer addLayoutGuide:rightGuide];
    [NSLayoutConstraint activateConstraints:@[
        [rightGuide.leadingAnchor  constraintEqualToAnchor:self.firstButton.trailingAnchor],
        [rightGuide.trailingAnchor constraintEqualToAnchor:self.buttonsContainer.trailingAnchor],
        [rightGuide.topAnchor      constraintEqualToAnchor:self.buttonsContainer.topAnchor],
        [rightGuide.bottomAnchor   constraintEqualToAnchor:self.buttonsContainer.bottomAnchor],
    ]];
    rightGuide.preferredFocusEnvironments = @[self.secondButton];
    self.buttonRightFocusGuide = rightGuide;
}

- (void)layoutSingleButtonForTvOS {
    for (NSLayoutConstraint *c in self.buttonsContainer.constraints) {
        if (c.firstAttribute == NSLayoutAttributeTrailing &&
            c.secondItem == self.secondButtonContainer &&
            c.secondAttribute == NSLayoutAttributeTrailing) {
            c.active = NO;
        }
        else if (c.firstItem == self.firstButton &&
                 c.firstAttribute == NSLayoutAttributeLeading) {
            c.active = NO;
        }
        else if (c.firstItem  == self.secondButton &&
                 c.firstAttribute  == NSLayoutAttributeWidth &&
                 c.secondItem == self.firstButton) {
            c.active = NO;
        }
    }
    [NSLayoutConstraint activateConstraints:@[
        [self.firstButton.centerXAnchor constraintEqualToAnchor:self.buttonsContainer.centerXAnchor],
        [self.firstButton.widthAnchor   constraintEqualToConstant:640.0],
    ]];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    for (UIPress *press in presses) {
        if (press.type == UIPressTypeMenu) {
            [self tappedDismiss];
            return;
        }
    }
    [super pressesEnded:presses withEvent:event];
}

#endif


#pragma mark - Setup Notification

- (void)layoutNotification {

    self.view.backgroundColor = [UIColor clearColor];
    self.containerView.backgroundColor = [CTUIUtils ct_colorWithHexString:self.notification.backgroundColor];

#if TARGET_OS_TV
    NSMutableArray *toDeactivate = [NSMutableArray array];
    for (NSLayoutConstraint *c in self.view.constraints) {
        if (c.firstItem == self.containerView || c.secondItem == self.containerView ||
            c.firstItem == self.closeButton   || c.secondItem == self.closeButton) {
            [toDeactivate addObject:c];
        }
    }
    [toDeactivate addObjectsFromArray:self.closeButton.constraints];
    [NSLayoutConstraint deactivateConstraints:toDeactivate];
    self.containerView.translatesAutoresizingMaskIntoConstraints = YES;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = YES;
    self.containerView.clipsToBounds = YES;
#endif

    if ([CTUIUtils isUserInterfaceIdiomPad]) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        if (self.notification.tablet) {
            if (![self deviceOrientationIsLandscape]) {
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeTrailing
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeTrailing
                                             multiplier:1 constant:-40] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeLeading
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeLeading
                                             multiplier:1 constant:40] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:0.5 constant:0] setActive:YES];
            } else {
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeTop
                                             multiplier:1 constant:40] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeBottom
                                             multiplier:1 constant:-40] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:0.5 constant:0] setActive:YES];
            }
        }else {
            if (![self deviceOrientationIsLandscape]) {
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeTrailing
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeTrailing
                                             multiplier:1 constant:-160] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeLeading
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeLeading
                                             multiplier:1 constant:160] setActive:YES];
                
            } else {
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeTop
                                             multiplier:1 constant:160] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeBottom
                                             multiplier:1 constant:-160] setActive:YES];
            }
        }
    }
    
    if (self.notification.darkenScreen) {
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    }
    
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    if (![self deviceOrientationIsLandscape]) {
        if (self.notification.inAppImage) {
            self.imageView.image = self.notification.inAppImage;
        } else if (self.notification.imageData) {
            self.imageView.image  = [UIImage imageWithData:self.notification.imageData];
        }
        self.imageView.accessibilityLabel = self.notification.contentDescription;
    } else {
        if (self.notification.inAppImageLandscape) {
            self.imageView.image = self.notification.inAppImageLandscape;
        } else if (self.notification.imageLandscapeData) {
            self.imageView.image = [UIImage imageWithData:self.notification.imageLandscapeData];
        }
        self.imageView.accessibilityLabel = self.notification.landscapeContentDescription;
    }
    
    self.closeButton.hidden = !self.notification.showCloseButton;
    
    if (self.notification.title) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [CTUIUtils ct_colorWithHexString:self.notification.titleColor];
        self.titleLabel.text = self.notification.title;
    }
    
    if (self.notification.message) {
        self.bodyLabel.textAlignment = NSTextAlignmentCenter;
        self.bodyLabel.backgroundColor = [UIColor clearColor];
        self.bodyLabel.textColor = [CTUIUtils ct_colorWithHexString:self.notification.messageColor];
        self.bodyLabel.numberOfLines = 0;
        self.bodyLabel.text = self.notification.message;
    }
    
    self.firstButton.hidden = YES;
    self.secondButton.hidden = YES;
    
    if (self.notification.buttons && self.notification.buttons.count > 0) {
        self.firstButton = [self setupViewForButton:self.firstButton withData:self.notification.buttons[0]  withIndex:0];
        if (self.notification.buttons.count == 2) {
            self.secondButton = [self setupViewForButton:_secondButton withData:self.notification.buttons[1] withIndex:1];
        } else {
#if TARGET_OS_TV
            [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                         multiplier:1 constant:0] setActive:YES];
            [self layoutSingleButtonForTvOS];
#else
            if ([self deviceOrientationIsLandscape]) {
                [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                 toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1 constant:0] setActive:YES];
            } else {
                [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                 toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1 constant:0] setActive:YES];
            }
#endif
            [self.secondButton setHidden:YES];
        }
    }
#if TARGET_OS_TV
    if (!self.firstButton.hidden) {
        [self.firstButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
    }
    if (!self.secondButton.hidden) {
        [self.secondButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
    }
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];

    NSMutableArray *a11yElements = [NSMutableArray array];
    if (self.titleLabel.text.length > 0)  [a11yElements addObject:self.titleLabel];
    if (self.bodyLabel.text.length > 0)   [a11yElements addObject:self.bodyLabel];
    if (!self.firstButton.isHidden)       [a11yElements addObject:self.firstButton];
    if (!self.secondButton.isHidden)      [a11yElements addObject:self.secondButton];
    if (!self.closeButton.isHidden)       [a11yElements addObject:self.closeButton];
    self.view.accessibilityElements = a11yElements;
#endif
}


#pragma mark - Actions

- (IBAction)closeButtonTapped:(id)sender {
    [super tappedDismiss];
}


#pragma mark - Public

- (void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

- (void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
