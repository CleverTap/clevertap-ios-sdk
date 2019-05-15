#import "CTCoverViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTDismissButton.h"
#import "CTInAppUtils.h"
#import "CTInAppResources.h"

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

@end

@implementation CTCoverViewController

@synthesize delegate;

#pragma mark - UIViewController Lifecycle

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTCoverViewController class])] owner:self options:nil];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self layoutNotification];
}

#pragma mark - Setup Notification

- (void)layoutNotification {
    
    self.view.backgroundColor = [UIColor clearColor];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (@available(iOS 11.0, *)) {
            CGFloat statusBarFrame = [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
            [[NSLayoutConstraint constraintWithItem: self.closeButton
                                          attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                             toItem:self.containerView
                                          attribute:NSLayoutAttributeTop
                                         multiplier:1.0 constant:statusBarFrame] setActive:YES];
        }
    }
    
   // UIView container which holds all other subviews
    self.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:self.notification.backgroundColor];
    
    self.closeButton.hidden = !self.notification.showCloseButton;

    // set image
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  
    if (self.notification.image && ![self deviceOrientationIsLandscape]) {
        self.imageView.image = [UIImage imageWithData:self.notification.image];
    }
    
    if (self.notification.imageLandscape && [self deviceOrientationIsLandscape]) {
        self.imageView.image = [UIImage imageWithData:self.notification.imageLandscape];
    }
    
    if (self.notification.title) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [CTInAppUtils ct_colorWithHexString:self.notification.titleColor];
        self.titleLabel.text = self.notification.title;
    }
    
    if (self.notification.message) {
        self.bodyLabel.textAlignment = NSTextAlignmentCenter;
        self.bodyLabel.backgroundColor = [UIColor clearColor];
        self.bodyLabel.textColor = [CTInAppUtils ct_colorWithHexString:self.notification.messageColor];
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
        }
    }
}

#pragma mark - Actions

- (IBAction)closeButtonTapped:(id)sender {
    [super tappedDismiss];
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}
@end
