
#import "CTImageInAppViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTImageInAppViewControllerPrivate.h"
#import "CTDismissButton.h"
#import "CTUIUtils.h"

static const CGFloat kTabletSpacingConstant = 40.f;
static const CGFloat kSpacingConstant = 160.f;

@interface CTImageInAppViewController ()

@property (nonatomic, assign) CGFloat aspectMultiplier;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;

@end

@implementation CTImageInAppViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    [self layoutNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#if TARGET_OS_TV

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    // Force the card geometry every layout pass — prevents Auto Layout from overriding
    // the frame-based positioning set up in layoutNotification.
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;   // 1920
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;  // 1080
    CGRect frame;
    CGPoint closePt; // origin of the 44×44 close button

    if (self.notification.inAppType == CTInAppTypeCoverImage) {
        // Full-screen card
        frame   = CGRectMake(0, 0, screenW, screenH);
        closePt = CGPointMake(screenW - 15.0f - 44.0f, 15.0f);
    } else if (self.notification.inAppType == CTInAppTypeHalfInterstitialImage) {
        // Smaller centered card — 50% width × 50% height
        CGFloat cW = screenW * 0.50f;        // 960
        CGFloat cH = screenH * 0.50f;        // 540
        CGFloat cX = (screenW - cW) * 0.5f; // 480
        CGFloat cY = (screenH - cH) * 0.5f; // 270
        frame   = CGRectMake(cX, cY, cW, cH);
        closePt = CGPointMake(cX + cW - 15.0f, cY - 15.0f);
    } else {
        // CTInAppTypeInterstitialImage — same geometry as Interstitial
        CGFloat margin = 160.0f;
        CGFloat cW = screenW * 0.70f;           // 1344
        CGFloat cH = screenH - 2.0f * margin;   // 760
        CGFloat cX = (screenW - cW) * 0.5f;     // 288
        CGFloat cY = margin;                     // 160
        frame   = CGRectMake(cX, cY, cW, cH);
        closePt = CGPointMake(cX + cW - 15.0f, cY - 15.0f);
    }

    self.containerView.frame = frame;
    self.closeButton.frame = CGRectMake(closePt.x, closePt.y, 44.0f, 44.0f);
}

- (BOOL)canBecomeFocused {
    return YES;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
      withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        context.nextFocusedView.transform = CGAffineTransformMakeScale(1.05, 1.05);
    } completion:nil];
    [coordinator addCoordinatedAnimations:^{
        context.previouslyFocusedView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    for (UIPress *press in presses) {
        if (press.type == UIPressTypeMenu) {
            [self tappedDismiss];   // dismiss without firing CTA
            return;
        }
        if (press.type == UIPressTypeSelect) {
            [self handleImageTapGesture]; // fire CTA action
            [self hide:YES];              // then dismiss
            return;
        }
    }
    [super pressesEnded:presses withEvent:event];
}

#endif // TARGET_OS_TV


#pragma mark - Setup Notification

- (void)layoutNotification {

    // UIView container which holds all other subviews
    self.containerView.backgroundColor = [CTUIUtils ct_colorWithHexString:self.notification.backgroundColor];
    self.closeButton.hidden = !self.notification.showCloseButton;

#if TARGET_OS_TV
    // Deactivate all XIB constraints on root view that involve containerView or closeButton,
    // then switch both to frame-based layout. viewWillLayoutSubviews re-applies the frame on
    // every layout pass so Auto Layout can never claw back control.
    NSMutableArray *toDeactivate = [NSMutableArray array];
    for (NSLayoutConstraint *c in self.view.constraints) {
        if (c.firstItem == self.containerView || c.secondItem == self.containerView ||
            c.firstItem == self.closeButton   || c.secondItem == self.closeButton) {
            [toDeactivate addObject:c];
        }
    }
    [NSLayoutConstraint deactivateConstraints:toDeactivate];
    self.containerView.translatesAutoresizingMaskIntoConstraints = YES;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = YES;
    self.containerView.clipsToBounds = YES;
#endif

    // isUserInterfaceIdiomPad returns NO on tvOS — these branches are safely skipped.
    switch (self.notification.inAppType) {
        case CTInAppTypeInterstitialImage:
            self.aspectMultiplier = 0.85;
            [self handleLayoutForIdiomPad];
            break;
        case CTInAppTypeHalfInterstitialImage:
            self.aspectMultiplier = 0.5;
            [self handleLayoutForIdiomPad];
            break;
        default:
            break;
    }

    [self setUpImage];

#if TARGET_OS_TV
    // Close button: XIB connects closeButtonTapped: via touchUpInside;
    // add primaryActionTriggered so the Siri Remote Select button also works.
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
#endif
}

- (void)handleLayoutForIdiomPad {
    if ([CTUIUtils isUserInterfaceIdiomPad]) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        if (self.notification.tablet) {
            if (![self deviceOrientationIsLandscape]) {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeLeading
                                        withConstant:kTabletSpacingConstant
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTrailing
                                        withConstant:-kTabletSpacingConstant
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeHeight
                                        withConstant:0
                                      withMultiplier:_aspectMultiplier];
            } else {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTop
                                        withConstant:kTabletSpacingConstant
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeBottom
                                        withConstant:-kTabletSpacingConstant
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeWidth
                                        withConstant:0
                                      withMultiplier:_aspectMultiplier];
            }
        } else {
            if (![self deviceOrientationIsLandscape]) {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeLeading
                                        withConstant:kSpacingConstant
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTrailing
                                        withConstant:-kSpacingConstant
                                      withMultiplier:1];
            } else {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTop
                                        withConstant:kSpacingConstant
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeBottom
                                        withConstant:-kSpacingConstant
                                      withMultiplier:1];
            }
        }
    }
}

- (void)addLayoutConstraintToAttribute:(NSLayoutAttribute)layoutAttribute withConstant:(CGFloat)constant withMultiplier:(CGFloat)multiplier {
    [[NSLayoutConstraint constraintWithItem:self.containerView
                                  attribute:layoutAttribute
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:layoutAttribute
                                 multiplier:multiplier constant:constant] setActive:YES];
}

- (void)setUpImage {
    // set image
    self.imageView.clipsToBounds = YES;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
#if !(TARGET_OS_TV)
    // UITapGestureRecognizer doesn't fire on tvOS remote — CTA is handled via
    // pressesEnded: (UIPressTypeSelect) in the tvOS block above.
    UITapGestureRecognizer *imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapGesture:)];
    [self.imageView addGestureRecognizer:imageTapGesture];
#endif

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
}


#pragma mark - Actions

- (IBAction)closeButtonTapped:(id)sender {
    [super tappedDismiss];
}

- (void)handleImageTapGesture:(UITapGestureRecognizer *)sender {
    [self handleImageTapGesture];
    [self hide:true];
}


#pragma mark - Public

- (void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

- (void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
