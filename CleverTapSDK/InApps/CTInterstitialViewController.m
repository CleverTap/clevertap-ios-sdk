
#import "CTInterstitialViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTUIUtils.h"
#import "CTDismissButton.h"
#import "CTInAppUtils.h"
#import "CTAVPlayerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface CTInterstitialViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *bodyLabel;
@property (nonatomic, strong) IBOutlet SDAnimatedImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *avPlayerContainerView;
@property (nonatomic, strong) IBOutlet UIView *buttonsContainer;
@property (nonatomic, strong) IBOutlet UIView *secondButtonContainer;
@property (nonatomic, strong) IBOutlet UIButton *firstButton;
@property (nonatomic, strong) IBOutlet UIButton *secondButton;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;
@property (nonatomic, strong) CTAVPlayerViewController *playerController;

@end

@implementation CTInterstitialViewController

@synthesize delegate;


#pragma mark - UIViewController Lifecycle

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTInterstitialViewController class])] owner:self options:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutNotification];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (IBAction)closeButtonTapped:(id)sender {
    [super tappedDismiss];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    
    self.view.backgroundColor = [UIColor clearColor];
    self.containerView.backgroundColor = [CTUIUtils ct_colorWithHexString:self.notification.backgroundColor];
    
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[NSLayoutConstraint constraintWithItem:self.containerView
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView
                                      attribute:NSLayoutAttributeHeight
                                     multiplier:0.6 constant:0] setActive:YES];
        
    }
    
    if ([CTUIUtils isUserInterfaceIdiomPad]) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        if (self.notification.tablet) {
            if (![self deviceOrientationIsLandscape]) {
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeLeading
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeLeading
                                             multiplier:1 constant:40] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeTrailing
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeTrailing
                                             multiplier:1 constant:-40] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:0.85 constant:0] setActive:YES];
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
                                             multiplier:0.85 constant:0] setActive:YES];
            }
        } else {
            if (![self deviceOrientationIsLandscape]) {
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeLeading
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeLeading
                                             multiplier:1 constant:160] setActive:YES];
                [[NSLayoutConstraint constraintWithItem:self.containerView
                                              attribute:NSLayoutAttributeTrailing
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeTrailing
                                             multiplier:1 constant:-160] setActive:YES];
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
    
    self.closeButton.hidden = !self.notification.showCloseButton;
    
    if (self.notification.inAppImage) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = self.notification.inAppImage;
    } else if (self.notification.imageData) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        if ([self.notification.contentType isEqualToString:@"image/gif"] ) {
            SDAnimatedImage *gif = [SDAnimatedImage imageWithData:self.notification.imageData];
            self.imageView.image = gif;
        } else {
            self.imageView.image = [UIImage imageWithData:self.notification.imageData];
        }
    }
    
    // handle video or audio
    if (self.notification.mediaUrl) {
        self.playerController = [[CTAVPlayerViewController alloc] initWithNotification:self.notification];
        self.imageView.hidden = YES;
        self.avPlayerContainerView.hidden = NO;
        [self configureAvPlayerController];
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
        self.bodyLabel.text = self.notification.message;
    }
    
    self.firstButton.hidden = YES;
    self.secondButton.hidden = YES;
    
    if (self.notification.buttons && self.notification.buttons.count > 0) {
        self.firstButton = [self setupViewForButton:self.firstButton withData:self.notification.buttons[0]  withIndex:0];
        if (self.notification.buttons.count == 2) {
            self.secondButton = [self setupViewForButton:self.secondButton withData:self.notification.buttons[1] withIndex:1];
        } else {
            [self.secondButton setHidden: YES];
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

- (void)configureAvPlayerController {
    [self addChildViewController:self.playerController];
    
    [self.avPlayerContainerView addSubview:self.playerController.view];
    
    [[NSLayoutConstraint constraintWithItem:self.playerController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                     toItem:self.avPlayerContainerView attribute:NSLayoutAttributeWidth
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.playerController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:self.avPlayerContainerView attribute:NSLayoutAttributeHeight
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.playerController.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:self.avPlayerContainerView attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.playerController.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.avPlayerContainerView attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:0] setActive:YES];
    [[NSLayoutConstraint constraintWithItem:self.playerController.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                     toItem:self.avPlayerContainerView attribute:NSLayoutAttributeCenterY
                                 multiplier:1 constant:0] setActive:YES];
    
    [self.playerController didMoveToParentViewController:self];
    
}


#pragma mark - Public

- (void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

- (void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
