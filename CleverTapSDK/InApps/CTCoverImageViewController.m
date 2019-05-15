#import "CTCoverImageViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTDismissButton.h"
#import "CTInAppResources.h"

@interface CTCoverImageViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;

@end

@implementation CTCoverImageViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTCoverImageViewController class])] owner:self options:nil];
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
    
    if (@available(iOS 11.0, *)) {
        CGFloat statusBarFrame = [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
        [[NSLayoutConstraint constraintWithItem: self.closeButton
                                      attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1.0 constant:statusBarFrame] setActive:YES];
        
    } else {
        // Fallback on earlier versions
    }
    
    // set image
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.userInteractionEnabled = YES;
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

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
