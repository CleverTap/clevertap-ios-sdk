
#import "CTHalfInterstitialImageViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTDismissButton.h"
#import "CTInAppResources.h"

@interface CTHalfInterstitialImageViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;


@end

@implementation CTHalfInterstitialImageViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTHalfInterstitialImageViewController class])] owner:self options:nil];
}

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
    self.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:self.notification.backgroundColor];
    self.closeButton.hidden = !self.notification.showCloseButton;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        if (self.notification.tablet) {
            if (![self deviceOrientationIsLandscape]) {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeLeading
                                        withConstant:40
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTrailing
                                        withConstant:-40
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeHeight
                                        withConstant:0
                                      withMultiplier:0.5];
            } else {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTop
                                        withConstant:40
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeBottom
                                        withConstant:-40
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeWidth
                                        withConstant:0
                                      withMultiplier:0.5];
            }
        } else {
            if (![self deviceOrientationIsLandscape]) {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeLeading
                                        withConstant:160
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTrailing
                                        withConstant:-160
                                      withMultiplier:1];
                
            } else {
                [self addLayoutConstraintToAttribute:NSLayoutAttributeTop
                                        withConstant:160
                                      withMultiplier:1];
                [self addLayoutConstraintToAttribute:NSLayoutAttributeBottom
                                        withConstant:-160
                                      withMultiplier:1];
            }
        }
    }
    [self setUpImage];
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
    
    if (self.notification.image && ![self deviceOrientationIsLandscape]) {
        self.imageView.image = [UIImage imageWithData:self.notification.image];
    }
    
    if (self.notification.imageLandscape && [self deviceOrientationIsLandscape]) {
        self.imageView.image = [UIImage imageWithData:self.notification.imageLandscape];
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
