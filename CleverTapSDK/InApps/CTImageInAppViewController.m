
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

- (void)setUpImage {
    // set image
    self.imageView.clipsToBounds = YES;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    UITapGestureRecognizer *imageTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapGesture:)];
    [self.imageView addGestureRecognizer:imageTapGesture];
    
    if (![self deviceOrientationIsLandscape]) {
        if (self.notification.inAppImage) {
            self.imageView.image = self.notification.inAppImage;
        } else if (self.notification.imageData) {
            self.imageView.image  = [UIImage imageWithData:self.notification.imageData];
        }
    } else {
        if (self.notification.inAppImageLandscape) {
            self.imageView.image = self.notification.inAppImageLandscape;
        } else if (self.notification.imageLandscapeData) {
            self.imageView.image = [UIImage imageWithData:self.notification.imageLandscapeData];
        }
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
