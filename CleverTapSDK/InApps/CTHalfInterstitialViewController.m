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
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    
    self.view.backgroundColor = [UIColor clearColor];
    self.containerView.backgroundColor = [CTUIUtils ct_colorWithHexString:self.notification.backgroundColor];
    
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
    } else {
        if (self.notification.inAppImageLandscape) {
            self.imageView.image = self.notification.inAppImageLandscape;
        } else if (self.notification.imageLandscapeData) {
            self.imageView.image = [UIImage imageWithData:self.notification.imageLandscapeData];
        }
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
            if ([self deviceOrientationIsLandscape]) {
                [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                 toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1 constant:0] setActive:YES];
                
            } else {
                [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                                 toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1 constant:0] setActive:YES];
            }
            
            [self.secondButton setHidden:YES];
        }
    }
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
