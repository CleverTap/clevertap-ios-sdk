#import "CTCoverViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTDismissButton.h"
#import "CTInAppUtils.h"
#import "CTUIUtils.h"

@interface CTCoverViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *bodyLabel;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *buttonsContainer;
@property (nonatomic, strong) IBOutlet UIView *secondButtonContainer;
@property (nonatomic, strong) IBOutlet UIButton *firstButton;
@property (nonatomic, strong) IBOutlet UIButton *secondButton;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;

#if TARGET_OS_TV
/// Routes LEFT navigation from secondButton back to firstButton.
/// Covers the area [buttonsContainer.leading … secondButton.leading], so any
/// focus search that lands in the gap (or the scaled-frame overlap zone) is
/// redirected to firstButton instead of stalling.
@property (nonatomic, strong) UIFocusGuide *buttonLeftFocusGuide;
/// Routes RIGHT navigation from firstButton forward to secondButton.
/// Covers the 40 pt dead-zone [firstButton.trailing … buttonsContainer.trailing]
/// that exists because secondButton is inset 40 pt inside secondButtonContainer.
@property (nonatomic, strong) UIFocusGuide *buttonRightFocusGuide;
#endif

@end

@implementation CTCoverViewController

@synthesize delegate;


#pragma mark - UIViewController Lifecycle

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTCoverViewController class])] owner:self options:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutNotification];
#if TARGET_OS_TV
    // Install focus guides now that button visibility has been resolved by layoutNotification.
    // Must happen before setNeedsFocusUpdate so the focus engine sees the guides on the
    // very first pass.
    [self setupFocusGuides];
    // Force the focus engine to re-read preferredFocusEnvironments so initial focus
    // lands on the correct button deterministically.
    [self setNeedsFocusUpdate];
    [self updateFocusIfNeeded];
#endif
}

#if !(TARGET_OS_TV)
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGFloat topLength;
        if (@available(iOS 11.0, *)) {
            topLength = self.view.safeAreaInsets.top;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            topLength = self.topLayoutGuide.length;
#pragma clang diagnostic pop
        }
        [[NSLayoutConstraint constraintWithItem: self.closeButton
                                      attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual
                                         toItem:self.containerView
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1.0 constant:topLength] setActive:YES];
    }
}
#endif

#if TARGET_OS_TV

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    // Cover is full-screen on tvOS — force the frame every layout pass so Auto Layout can't override.
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;   // 1920
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;  // 1080
    self.containerView.frame = CGRectMake(0, 0, screenW, screenH);
    // Close button: top-right corner, 15pt inset from each edge
    self.closeButton.frame = CGRectMake(screenW - 15.0f - 44.0f, 15.0f, 44.0f, 44.0f);
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
    // Scale 1.05 is the largest safe value that keeps secondButton.frame.minX above
    // firstButton.frame.maxX (gap = 40 pt; max safe expansion per side ≈ 20 pt → scale ≈ 1.046).
    // 1.1 caused a ~3 pt frame overlap that confused the spatial focus search engine,
    // making it impossible to navigate LEFT from secondButton back to firstButton.
    [coordinator addCoordinatedAnimations:^{
        if (context.nextFocusedView) {
            context.nextFocusedView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        }
        if (context.previouslyFocusedView) {
            context.previouslyFocusedView.transform = CGAffineTransformIdentity;
        }
    } completion:nil];
}

/// Installs UIFocusGuides that route navigation between spatially misaligned focusable items.
///
/// Two classes of guide are needed:
///
/// 1. **Close-button guides** — CloseButton sits at the top-right corner (x ≈ 1861),
///    while content buttons sit at the bottom-left/centre (x ≈ 80-720).  The tvOS focus
///    engine casts a narrow beam matching the focused item's width in the navigation
///    direction.  The UP beam from firstButton (width 640 at x ≈ 560) never reaches
///    closeButton's column; likewise the DOWN beam from closeButton (width 44 at x ≈ 1861)
///    never reaches the content buttons.  Two guides bridge this gap:
///      • upGuide   — full-width strip at the top of the screen; any UP beam enters it and
///                     gets routed to closeButton.
///      • downGuide — narrow strip aligned with closeButton's column; the DOWN beam from
///                     closeButton enters it and gets routed back to the primary content button.
///
/// 2. **Button-to-button guides** (two-button mode only) — secondButton sits 40 pt inside
///    secondButtonContainer.  That 40 pt gap is a dead zone the focus engine can stall in.
///    A left and right guide cover the gap and ensure LEFT/RIGHT navigation always resolves.
- (void)setupFocusGuides {

    // ── Close-button guides (always installed when closeButton is visible) ──────────
    if (!self.closeButton.isHidden) {
        // UP guide — full-width, 60 pt tall strip at the top of the screen.
        // Any upward beam from the content-button area (x = 0 … 1920) enters this guide
        // and gets redirected to closeButton regardless of horizontal alignment.
        UIFocusGuide *upGuide = [UIFocusGuide new];
        [self.view addLayoutGuide:upGuide];
        [NSLayoutConstraint activateConstraints:@[
            [upGuide.topAnchor      constraintEqualToAnchor:self.view.topAnchor],
            [upGuide.heightAnchor   constraintEqualToConstant:60.0],
            [upGuide.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor],
            [upGuide.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        ]];
        upGuide.preferredFocusEnvironments = @[self.closeButton];

        // DOWN guide — narrow vertical strip aligned with closeButton's column.
        // The DOWN beam from closeButton (44 pt wide at x ≈ 1861) enters this strip and
        // gets redirected to the primary content button.  The strip is kept narrow
        // (closeButton ± 20 pt padding) so it never overlaps the content-button area
        // (x ≤ ~1720) and doesn't interfere with LEFT/RIGHT navigation between buttons.
        UIFocusGuide *downGuide = [UIFocusGuide new];
        [self.view addLayoutGuide:downGuide];
        id<UIFocusEnvironment> downTarget = !self.firstButton.isHidden
            ? (id<UIFocusEnvironment>)self.firstButton
            : (id<UIFocusEnvironment>)self.secondButton;
        [NSLayoutConstraint activateConstraints:@[
            [downGuide.topAnchor      constraintEqualToAnchor:self.view.topAnchor constant:60.0],
            [downGuide.bottomAnchor   constraintEqualToAnchor:self.view.bottomAnchor],
            [downGuide.leadingAnchor  constraintEqualToAnchor:self.closeButton.leadingAnchor constant:-20.0],
            [downGuide.trailingAnchor constraintEqualToAnchor:self.closeButton.trailingAnchor constant:20.0],
        ]];
        downGuide.preferredFocusEnvironments = @[downTarget];
    }

    // ── Button-to-button guides (two-button mode only) ─────────────────────────────
    if (self.firstButton.isHidden || self.secondButton.isHidden) return;

    // LEFT guide — catches leftward navigation that overshoots firstButton due to the
    // 40 pt dead zone or a residual scale transform on secondButton.
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

    // RIGHT guide — bridges the 40 pt dead zone to the right of firstButton.
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

/// Centres firstButton in buttonsContainer at a readable fixed width (640 pt) when
/// only one action button is present.
///
/// The XIB layout chain normally makes firstButton.trailing == buttonsContainer.trailing
/// once secondButtonContainer collapses to 0 width, stretching the button across the
/// entire 1 760 pt content area.  We break three constraints that form that chain and
/// substitute a center + fixed-width pair.
- (void)layoutSingleButtonForTvOS {
    for (NSLayoutConstraint *c in self.buttonsContainer.constraints) {
        // 1. buttonsContainer.trailing == secondButtonContainer.trailing
        //    (cvr-btn2c-trail) — this is the constraint that "pulls" firstButton.trailing
        //    to the right edge once the container collapses.
        if (c.firstAttribute == NSLayoutAttributeTrailing &&
            c.secondItem == self.secondButtonContainer &&
            c.secondAttribute == NSLayoutAttributeTrailing) {
            c.active = NO;
        }
        // 2. firstButton.leading == buttonsContainer.leading  (cvr-btn1-lead)
        //    Must be removed so centerX doesn't conflict with a fixed left edge.
        else if (c.firstItem == self.firstButton &&
                 c.firstAttribute == NSLayoutAttributeLeading) {
            c.active = NO;
        }
        // 3. secondButton.width == firstButton.width  (cvr-btneq-w)
        //    With secondButtonContainer at 0 width, secondButton.width is driven to 0,
        //    which would force firstButton.width to 0 as well.
        else if (c.firstItem  == self.secondButton &&
                 c.firstAttribute  == NSLayoutAttributeWidth &&
                 c.secondItem == self.firstButton) {
            c.active = NO;
        }
    }
    // Centre the single button and fix its width to a TV-appropriate size.
    [NSLayoutConstraint activateConstraints:@[
        [self.firstButton.centerXAnchor constraintEqualToAnchor:self.buttonsContainer.centerXAnchor],
        [self.firstButton.widthAnchor   constraintEqualToConstant:640.0],
    ]];
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    // Select press is handled natively by buttons via UIControlEventPrimaryActionTriggered.
    // Only handle Menu button here for dismiss.
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

    // UIView container which holds all other subviews
    self.containerView.backgroundColor = [CTUIUtils ct_colorWithHexString:self.notification.backgroundColor];

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
    // Also deactivate closeButton's own self-referencing constraints (width/height set by
    // the XIB). These live on closeButton itself, not on self.view, so the loop above
    // misses them. Leaving them active while translatesAutoresizingMaskIntoConstraints=YES
    // creates a conflict between the XIB constraint and the auto-generated mask constraint.
    [toDeactivate addObjectsFromArray:self.closeButton.constraints];
    [NSLayoutConstraint deactivateConstraints:toDeactivate];
    self.containerView.translatesAutoresizingMaskIntoConstraints = YES;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = YES;
    self.containerView.clipsToBounds = YES;
#endif

    self.closeButton.hidden = !self.notification.showCloseButton;
    
    // set image
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
            self.secondButton = [self setupViewForButton:self.secondButton withData:self.notification.buttons[1] withIndex:1];
        } else {
            [self.secondButton setHidden:YES];
#if TARGET_OS_TV
            // Collapse the container first (required to satisfy the sibling-chain constraints
            // before we break some of them in layoutSingleButtonForTvOS).
            [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                         multiplier:1 constant:0] setActive:YES];
            // Center firstButton at 640 pt instead of letting it fill the full 1760 pt
            // content area that would otherwise result from the collapsed container chain.
            [self layoutSingleButtonForTvOS];
#else
            if ([self deviceOrientationIsLandscape]) {
                [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer
                                              attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                 toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1 constant:0] setActive:YES];
            } else {
                [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer
                                              attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                 toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1 constant:0] setActive:YES];
            }
#endif
        }
    }
#if TARGET_OS_TV
    // On tvOS, UIButton fires UIControlEventPrimaryActionTriggered on Select press.
    // setupViewForButton: registers touchUpInside which doesn't fire on tvOS.
    if (!self.firstButton.hidden) {
        [self.firstButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
    }
    if (!self.secondButton.hidden) {
        [self.secondButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
    }
    // Close button: XIB connects closeButtonTapped: via touchUpInside; add primaryActionTriggered for remote Select
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
#endif

    // Explicit VoiceOver traversal order: title → body → primary button → secondary button → close.
    // Without this, UIAccessibility derives order from frame geometry, which diverges from
    // reading order when elements are anchored near the bottom of the screen (the default
    // Cover layout).  Filtering hidden elements prevents VoiceOver from announcing invisible
    // controls and trapping focus inside a non-interactive element.
    NSMutableArray *a11yElements = [NSMutableArray array];
    if (self.titleLabel.text.length > 0)  [a11yElements addObject:self.titleLabel];
    if (self.bodyLabel.text.length > 0)   [a11yElements addObject:self.bodyLabel];
    if (!self.firstButton.isHidden)       [a11yElements addObject:self.firstButton];
    if (!self.secondButton.isHidden)      [a11yElements addObject:self.secondButton];
    if (!self.closeButton.isHidden)       [a11yElements addObject:self.closeButton];
    self.view.accessibilityElements = a11yElements;
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
