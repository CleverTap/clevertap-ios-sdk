
#import "CTImageInAppViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTImageInAppViewControllerPrivate.h"
#import "CTDismissButton.h"
#import "CTUIUtils.h"
#import "CTAVPlayerViewController.h"
#import "UIImageView+CTWebCache.h"
#import "CTAnimatedImageView.h"
#import "CTAnimatedImage.h"

static const CGFloat kTabletSpacingConstant = 40.f;
static const CGFloat kSpacingConstant = 160.f;

@interface CTImageInAppViewController ()

@property (nonatomic, assign) CGFloat aspectMultiplier;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet CTAnimatedImageView *imageView;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;
@property (nonatomic, strong) CTAVPlayerViewController *playerController;
@property (nonatomic, strong) UIImage *initialImage;

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


#pragma mark - Setup Notification

- (void)layoutNotification {
    
    // UIView container which holds all other subviews
    self.containerView.backgroundColor = [CTUIUtils ct_colorWithHexString:self.notification.backgroundColor];
    self.closeButton.hidden = !self.notification.showCloseButton;
    
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

- (void)embedPlayerInContainer {
    // Insert video player below close button and pin it to all edges via Auto Layout.
    // translatesAutoresizingMaskIntoConstraints is NO on the player's view, so constraints
    // are required - a frame + autoresizingMask approach would be ignored.
    // Cross-view constraints are owned by containerView, so they're automatically released
    // when the XIB reloads and creates a fresh containerView on rotation.
    UIView *playerView = self.playerController.view;
    [self.containerView insertSubview:playerView belowSubview:self.closeButton];
    [NSLayoutConstraint activateConstraints:@[
        [playerView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [playerView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
        [playerView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
    ]];
}

- (void)setUpImage {
    // Phase A: video player already created - re-embed into refreshed containerView, keep URL.
    if (self.playerController) {
        self.imageView.hidden = YES;
        [self embedPlayerInContainer];
        return;
    }

    // Phase B: image already chosen at first render - re-show it without switching.
    if (self.initialImage) {
        self.imageView.clipsToBounds = YES;
        self.imageView.userInteractionEnabled = YES;
        // Use ScaleAspectFit so a landscape image shown in a portrait container (or vice versa)
        // is not cropped/zoomed. ScaleAspectFill would be correct only when image and container
        // share the same orientation, which is not guaranteed after rotation.
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = self.initialImage;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapGesture:)];
        [self.imageView addGestureRecognizer:tap];
        return;
    }

    // Phase C: first render - decide what to show based on current orientation.
    BOOL isLandscape = [self deviceOrientationIsLandscape];
    BOOL hasPortraitVideo = self.notification.mediaIsVideo && self.notification.mediaUrl.length > 0;
    BOOL hasLandscapeVideo = self.notification.mediaUrlLandscape.length > 0;
    BOOL shouldShowVideo = isLandscape ? hasLandscapeVideo : hasPortraitVideo;

    if (shouldShowVideo) {
        self.playerController = [[CTAVPlayerViewController alloc] initWithNotification:self.notification
                                                                                  muted:YES
                                                                               autoplay:YES];
        __weak typeof(self) weakSelf = self;
        self.playerController.videoDidFailHandler = ^{
            CleverTapLogStaticDebug(@"InApp: dismissing due to video load failure.");
            [weakSelf hide:YES];
        };
        if (self.notification.buttons.count > 0) {
            self.playerController.ctaTapHandler = ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf handleButtonClickFromIndex:0];
                [strongSelf hide:YES];
            };
        }
        self.imageView.hidden = YES;
        [self addChildViewController:self.playerController];
        [self embedPlayerInContainer];
        [self.playerController didMoveToParentViewController:self];
        return;
    }

    // Image/GIF: pick by orientation, fall back to portrait if no landscape image exists.
    self.imageView.clipsToBounds = YES;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    UITapGestureRecognizer *imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapGesture:)];
    [self.imageView addGestureRecognizer:imageTapGesture];

    if (!isLandscape) {
        if (self.notification.inAppImage) {
            self.imageView.image = self.notification.inAppImage;
        } else if (self.notification.imageData) {
            if ([self.notification.contentType isEqualToString:@"image/gif"]) {
                self.imageView.image = [CTAnimatedImage imageWithData:self.notification.imageData];
            } else {
                self.imageView.image = [UIImage imageWithData:self.notification.imageData];
            }
        }
        self.imageView.accessibilityLabel = self.notification.contentDescription;
    } else {
        if (self.notification.inAppImageLandscape) {
            self.imageView.image = self.notification.inAppImageLandscape;
            self.imageView.accessibilityLabel = self.notification.landscapeContentDescription;
        } else if (self.notification.imageLandscapeData) {
            if ([self.notification.landscapeContentType isEqualToString:@"image/gif"]) {
                self.imageView.image = [CTAnimatedImage imageWithData:self.notification.imageLandscapeData];
            } else {
                self.imageView.image = [UIImage imageWithData:self.notification.imageLandscapeData];
            }
            self.imageView.accessibilityLabel = self.notification.landscapeContentDescription;
        } else {
            // No landscape image (landscape media may be a video or absent) - fall back to portrait.
            if (self.notification.inAppImage) {
                self.imageView.image = self.notification.inAppImage;
            } else if (self.notification.imageData) {
                if ([self.notification.contentType isEqualToString:@"image/gif"]) {
                    self.imageView.image = [CTAnimatedImage imageWithData:self.notification.imageData];
                } else {
                    self.imageView.image = [UIImage imageWithData:self.notification.imageData];
                }
            }
            self.imageView.accessibilityLabel = self.notification.contentDescription;
        }
    }

    // Lock in the chosen image so rotation re-renders show the same one.
    self.initialImage = self.imageView.image;
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
