#import "CTInterstitialViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"
#import "CTInAppResources.h"
#import "CTDismissButton.h"
#import "CTInAppUtils.h"
#import "CTAVPlayerViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import "CTSlider.h"

@import AVFoundation;
#import <AVKit/AVKit.h>

struct FrameRotation {
    CGRect frame;
    CGFloat angle;
    BOOL isRotated;
};

@interface CTInterstitialViewController () <CTAVPlayerViewControllerDelegate>

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
@property (nonatomic, assign) CGRect cachedAVPlayerFrame;
@property (nonatomic, assign) UIInterfaceOrientation originalOrientation;
@property (nonatomic, strong) UIWindow *avPlayerWindow;
@property (nonatomic, weak) UIWindow *mainWindow;
@property (nonatomic, assign) BOOL avPlayerIsFullScreen;

@end

@implementation CTInterstitialViewController

@synthesize delegate;

#pragma mark - UIViewController Lifecycle

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTInterstitialViewController class])] owner:self options:nil];
}

-(void)viewDidLoad {
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
   
    self.originalOrientation = [CTInAppResources getSharedApplication].statusBarOrientation;
    self.view.backgroundColor = [UIColor clearColor];
    self.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:self.notification.backgroundColor];
    
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[NSLayoutConstraint constraintWithItem:self.containerView
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView
                                      attribute:NSLayoutAttributeHeight
                                     multiplier:0.6 constant:0] setActive:YES];
        
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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

    if (self.notification.image) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        if ([self.notification.contentType isEqualToString:@"image/gif"] ) {
            SDAnimatedImage *gif = [SDAnimatedImage imageWithData:self.notification.image];
            self.imageView.image = gif;
        } else {
            self.imageView.image = [UIImage imageWithData:self.notification.image];
        }
    }
    
    // handle video or audio
    if (self.notification.mediaUrl) {
        self.playerController = [[CTAVPlayerViewController alloc] initWithNotification:self.notification];
        self.playerController.playerDelegate = self;
        self.imageView.hidden = YES;
        self.avPlayerContainerView.hidden = NO;
        [self configureAvPlayerController];
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

#pragma mark - AV Delegates

- (struct FrameRotation)rotateFrameIfNeeded:(CGRect)frame {
    struct FrameRotation frameRotation;
    frameRotation.frame = frame;
    frameRotation.angle = 0;
    frameRotation.isRotated = NO;
    UIInterfaceOrientation currentOrientation = [CTInAppResources getSharedApplication].statusBarOrientation;
    if (currentOrientation != _originalOrientation) {
        frameRotation.isRotated = YES;
        if (currentOrientation == UIInterfaceOrientationPortrait && _originalOrientation == UIInterfaceOrientationLandscapeRight) {
            frameRotation.frame = CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
            frameRotation.angle = M_PI_2;
        }
        else if (currentOrientation == UIInterfaceOrientationPortrait && _originalOrientation == UIInterfaceOrientationLandscapeLeft) {
            frameRotation.frame = CGRectMake(frame.origin.y, [UIScreen mainScreen].bounds.size.height - frame.origin.x - frame.size.height, frame.size.height, frame.size.width);
            frameRotation.angle = -M_PI_2;
        }
        else if (currentOrientation == UIInterfaceOrientationLandscapeRight && _originalOrientation == UIInterfaceOrientationPortrait) {
            frameRotation.frame = CGRectMake(frame.origin.y, frame.origin.x, frame.size.height, frame.size.width);
            frameRotation.angle = -M_PI_2;
        }
        else if (currentOrientation == UIInterfaceOrientationLandscapeRight && _originalOrientation == UIInterfaceOrientationLandscapeLeft) {
            frameRotation.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - frame.origin.x - frame.size.width, frame.origin.y, frame.size.width, frame.size.height);
            frameRotation.angle = M_PI;
        }
        else if (currentOrientation == UIInterfaceOrientationLandscapeLeft && _originalOrientation == UIInterfaceOrientationPortrait) {
            frameRotation.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - frame.origin.y - frame.size.height, frame.origin.x, frame.size.height, frame.size.width);
            frameRotation.angle = M_PI_2;
        }
        else if (currentOrientation == UIInterfaceOrientationLandscapeLeft && _originalOrientation == UIInterfaceOrientationLandscapeRight) {
            frameRotation.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - frame.origin.y - frame.size.height, frame.origin.x, frame.size.height, frame.size.width);
            frameRotation.angle = -M_PI;
        }
    }
    return frameRotation;
}

- (void)toggleFullscreen {
    if (self.mainWindow == nil) {
        self.mainWindow = [CTInAppResources getSharedApplication].keyWindow;
    }
    
    if (self.avPlayerIsFullScreen) {
        struct FrameRotation frameRotation = [self rotateFrameIfNeeded:self.cachedAVPlayerFrame];
        self.playerController.view.frame = frameRotation.frame;
        [UIView animateKeyframesWithDuration:0.3
                                       delay:0 options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      self->_avPlayerWindow.transform = CGAffineTransformRotate(self->_avPlayerWindow.transform, frameRotation.angle);
                                      self->_avPlayerWindow.frame = frameRotation.frame;
                                  } completion:^(BOOL finished) {
                                      [self->_playerController removeFromParentViewController];
                                      [self->_playerController.view removeFromSuperview];
                                      [self configureAvPlayerController];
                                      [self->_avPlayerWindow removeFromSuperview];
                                      self->_avPlayerWindow.rootViewController = nil;
                                      self->_avPlayerWindow = nil;
                                  }];
    }
    else {
        self.cachedAVPlayerFrame = [[self.playerController.view superview] convertRect:self.playerController.view.frame toView:self.window];
        
        [self.playerController removeFromParentViewController];
        [self.playerController.view removeFromSuperview];
        [self.playerController willMoveToParentViewController:nil];
        
        struct FrameRotation frameRotation = [self rotateFrameIfNeeded:self.cachedAVPlayerFrame];
        
        self.avPlayerWindow = [[UIWindow alloc] initWithFrame:frameRotation.frame];
        self.avPlayerWindow.transform = CGAffineTransformRotate(self.avPlayerWindow.transform, frameRotation.angle);
        self.avPlayerWindow.backgroundColor = [UIColor blackColor];
        self.avPlayerWindow.windowLevel = UIWindowLevelNormal;
        [self.avPlayerWindow makeKeyAndVisible];
        self.avPlayerWindow.rootViewController = self.playerController;
        
        self.playerController.view.frame = self.mainWindow.bounds;
        
        [UIView animateKeyframesWithDuration:0.3
                                       delay:0 options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      self->_avPlayerWindow.transform = CGAffineTransformRotate(self->_avPlayerWindow.transform, -frameRotation.angle);
                                      self->_avPlayerWindow.frame = self->_mainWindow.bounds;
                                  } completion:^(BOOL finished) {
                                      // no-op
                                  }];
    }
    self.avPlayerIsFullScreen = !self.avPlayerIsFullScreen;
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
