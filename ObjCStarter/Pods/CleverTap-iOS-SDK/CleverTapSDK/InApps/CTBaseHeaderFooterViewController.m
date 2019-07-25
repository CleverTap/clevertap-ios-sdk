
#import "CTBaseHeaderFooterViewController.h"
#import "CTBaseHeaderFooterViewControllerPrivate.h"
#import "CTInAppDisplayViewControllerPrivate.h"

typedef enum {
    kWRSlideStatusNormal = 0,
    kWRSlideStatusLeftExpanded,
    kWRSlideStatusLeftExpanding,
    kWRSlideStatusRightExpanded,
    kWRSlideStatusRightExpanding,
} kWRSlideStatus;

typedef enum {
    WRSlideCellDirectionRight,
    WRSlideCellDirectionLeft,
} WRSlideCellDirection;

#define kMinimumVelocity  self.containerView.frame.size.width*1.5
#define kMinimumPan       60.0
#define kBOUNCE_DISTANCE  0.0


@interface CTBaseHeaderFooterViewController () <UIGestureRecognizerDelegate> {
    
    kWRSlideStatus _currentStatus;
}

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *bodyLabel;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *buttonsContainer;
@property (nonatomic, strong) IBOutlet UIView *secondButtonContainer;
@property (nonatomic, strong) IBOutlet UIButton *firstButton;
@property (nonatomic, strong) IBOutlet UIButton *secondButton;
@property (nonatomic, strong) IBOutlet UIView *imageContainer;

@property(nonatomic, retain) UIPanGestureRecognizer *panGesture;
@property(nonatomic, assign) CGFloat initialHorizontalCenter;
@property(nonatomic, assign) CGFloat initialTouchPositionX;

@property(nonatomic, assign) WRSlideCellDirection lastDirection;
@property(nonatomic, assign) CGFloat originalCenter;

@property(nonatomic, assign) BOOL revealing;

@end

@implementation CTBaseHeaderFooterViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil notification:(CTInAppNotification *)notification {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.shouldPassThroughTouches = YES;
        self.notification = notification;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    CTInAppPassThroughView *view = (CTInAppPassThroughView*)self.view;
    view.delegate = self;
    [self layoutNotification];
}

#pragma mark - Setup Notification

- (void)layoutNotification {
    
    self.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:self.notification.backgroundColor];
    
    if (self.notification.darkenScreen) {
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    }
    
    // set image
    if (self.notification.image) {
        self.imageView.clipsToBounds = YES;
        self.imageView.hidden = NO;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.image = [UIImage imageWithData:self.notification.image];
    } else {
        [[NSLayoutConstraint constraintWithItem:self.imageContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1 constant:20] setActive:YES];
        self.imageView.hidden = YES;
    }
    
    if (self.notification.title) {
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [CTInAppUtils ct_colorWithHexString:self.notification.titleColor];
        self.titleLabel.text = self.notification.title;
    }
    
    if (self.notification.message) {
        self.bodyLabel.textAlignment = NSTextAlignmentLeft;
        self.bodyLabel.backgroundColor = [UIColor clearColor];
        self.bodyLabel.textColor = [CTInAppUtils ct_colorWithHexString:self.notification.messageColor];
        self.bodyLabel.numberOfLines = 0;
        self.bodyLabel.text = self.notification.message;
    }
    
    if (!self.notification.showClose) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
        _panGesture.delegate = self;
        [self.containerView addGestureRecognizer:_panGesture];
    }
    
    self.firstButton.hidden = YES;
    self.secondButton.hidden = YES;
    
    if (self.notification.buttons && self.notification.buttons.count > 0) {
        self.firstButton = [self setupViewForButton:self.firstButton withData:self.notification.buttons[0]  withIndex:0];
        if (self.notification.buttons.count == 2) {
            _secondButton = [self setupViewForButton:_secondButton withData:self.notification.buttons[1] withIndex:1];
        } else {
            [[NSLayoutConstraint constraintWithItem:self.secondButtonContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                         multiplier:1 constant:0] setActive:YES];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)recognizer {
    //begin pan...
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.initialTouchPositionX = [recognizer locationInView:self.view].x;
        self.initialHorizontalCenter = self.containerView.center.x;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) { //status change
        
        CGFloat panAmount = _initialTouchPositionX - [recognizer locationInView:self.view].x;
        CGFloat newCenterPosition = _initialHorizontalCenter - panAmount;
        CGFloat centerX = self.containerView.center.x;
        
        if (centerX > _originalCenter && _currentStatus != kWRSlideStatusLeftExpanding) {
            _currentStatus = kWRSlideStatusLeftExpanding;
        }
        else if (centerX < _originalCenter && _currentStatus != kWRSlideStatusRightExpanding) {
            _currentStatus = kWRSlideStatusRightExpanding;
        }
        
        if (panAmount > 0) {
            _lastDirection = WRSlideCellDirectionLeft;
        }
        else {
            _lastDirection = WRSlideCellDirectionRight;
        }
        
        if (newCenterPosition > self.view.bounds.size.width + self.containerView.bounds.size.width) {
            newCenterPosition = self.view.bounds.size.width + self.containerView.bounds.size.width;
        }
        else if (newCenterPosition < -self.containerView.bounds.size.width) {
            newCenterPosition = -self.containerView.bounds.size.width;
        }
        CGPoint center = self.containerView.center;
        center.x = newCenterPosition;
        self.containerView.layer.position = center;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded ||
             recognizer.state == UIGestureRecognizerStateCancelled) {
        
        CGPoint translation = [recognizer translationInView:self.view];
        CGFloat velocityX = [recognizer velocityInView:self.view].x;
        
        BOOL isNeedPush = (fabs(velocityX) > kMinimumVelocity);
        
        isNeedPush |= ((_lastDirection == WRSlideCellDirectionLeft && translation.x < -kMinimumPan) ||
                       (_lastDirection == WRSlideCellDirectionRight && translation.x > kMinimumPan));
        
        if (velocityX > 0 && _lastDirection == WRSlideCellDirectionLeft) {
            isNeedPush = NO;
        }
        
        else if (velocityX < 0 && _lastDirection == WRSlideCellDirectionRight) {
            isNeedPush = NO;
        }
        
        if (isNeedPush && !self.revealing) {
            
            if (_lastDirection == WRSlideCellDirectionRight) {
                _currentStatus = kWRSlideStatusLeftExpanding;
            }
            else {
                _currentStatus = kWRSlideStatusRightExpanding;
            }
            [self _slideOutContentViewInDirection:_lastDirection];
            [self _setRevealing:YES];
        }
        else if (self.revealing && translation.x != 0) {
            WRSlideCellDirection direct = _currentStatus == kWRSlideStatusRightExpanding ? WRSlideCellDirectionLeft : WRSlideCellDirectionRight;
            
            [self _slideInContentViewFromDirection:direct];
            [self _setRevealing:NO];
        }
        else if (translation.x != 0) {
            // Figure out which side we've dragged on.
            WRSlideCellDirection finalDir = WRSlideCellDirectionRight;
            if (translation.x < 0)
                finalDir = WRSlideCellDirectionLeft;
            [self _slideInContentViewFromDirection:finalDir];
            [self _setRevealing:NO];
        }
    }
}

#pragma mark - revealing setter

- (void)setRevealing:(BOOL)revealing {
    if (_revealing == revealing) {
        return;
    }
    [self _setRevealing:revealing];
    
    if (self.revealing) {
        [self _slideOutContentViewInDirection:_lastDirection];
    } else {
        [self _slideInContentViewFromDirection:_lastDirection];
    }
}

- (void)_setRevealing:(BOOL)revealing {
    _revealing = revealing;
}

#pragma mark - ContentView Sliding

- (void)_slideInContentViewFromDirection:(WRSlideCellDirection)direction {
    CGFloat bounceDistance;
    
    if (self.containerView.center.x == _originalCenter)
        return;
    
    switch (direction) {
        case WRSlideCellDirectionRight:
            bounceDistance = kBOUNCE_DISTANCE;
            break;
        case WRSlideCellDirectionLeft:
            bounceDistance = (CGFloat) -kBOUNCE_DISTANCE;
            break;
        default:
            break;
    }
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self->_containerView.center = CGPointMake(self->_originalCenter, self->_containerView.center.y);
                     }
                     completion:^(BOOL f) {
                         [UIView animateWithDuration:0.1 delay:0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self->_containerView.frame = CGRectOffset(self->_containerView.frame, bounceDistance, 0);
                                          }
                                          completion:^(BOOL f2) {
                                              [UIView animateWithDuration:0.1 delay:0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self->_containerView.frame = CGRectOffset(self->_containerView.frame, -bounceDistance, 0);
                                                               }
                                                               completion:^(BOOL f1) {
                                                                   self->_currentStatus = kWRSlideStatusNormal;
                                                               }];
                                          }];
                     }];
}

- (void)_slideOutContentViewInDirection:(WRSlideCellDirection)direction; {
    CGFloat newCenterX;
    CGFloat bounceDistance;
    switch (direction) {
        case WRSlideCellDirectionLeft: {
            newCenterX = -self.containerView.bounds.size.width;
            bounceDistance = (CGFloat) -kBOUNCE_DISTANCE;
            _currentStatus = kWRSlideStatusLeftExpanded;
        }
            break;
        case WRSlideCellDirectionRight: {
            newCenterX = self.view.bounds.size.width + self.containerView.bounds.size.width;
            bounceDistance = kBOUNCE_DISTANCE;
            _currentStatus = kWRSlideStatusRightExpanded;
        }
            break;
        default:
            break;
    }
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self->_containerView.center = CGPointMake(newCenterX, self->_containerView.center.y);
                     }
                     completion:^(BOOL f) {
                         [UIView animateWithDuration:0.1 delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self->_containerView.frame = CGRectOffset(self->_containerView.frame, -bounceDistance, 0);
                                          }
                                          completion:^(BOOL f1) {
                                              [UIView animateWithDuration:0.1 delay:0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self->_containerView.frame = CGRectOffset(self->_containerView.frame, bounceDistance, 0);
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   [self hide:NO];
                                                               }];
                                          }];
                     }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _panGesture) {
        UIScrollView *superview = (UIScrollView *) self.view;
        CGPoint translation = [(UIPanGestureRecognizer *) gestureRecognizer translationInView:superview];
        // Make it scrolling horizontally
        return fabs(translation.x) / fabs(translation.y) > 1;
    }
    return YES;
}

- (void)showFromWindow:(BOOL)animated {
    if (!self.notification) return;
    self.window = [[CTInAppPassThroughWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.window.alpha = 0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.windowLevel = UIWindowLevelNormal;
    self.window.rootViewController = self;
    [self.window setHidden:NO];
    
    void (^completionBlock)(void) = ^ {
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidShow:fromViewController:)]) {
            [self.delegate notificationDidShow:self.notification fromViewController:self];
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 1.0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } else {
        self.window.alpha = 1.0;
        completionBlock();
    }
}

#pragma mark - Public

-(void)show:(BOOL)animated {
    [self showFromWindow:animated];
}

-(void)hide:(BOOL)animated {
    [self hideFromWindow:animated];
}

@end
