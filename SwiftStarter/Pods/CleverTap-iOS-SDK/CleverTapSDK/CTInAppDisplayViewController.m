#import "CTInAppDisplayViewController.h"
#import "CTInAppDisplayViewControllerPrivate.h"

@implementation CTInAppPassThroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return view == self ? nil : view;
}
@end

@implementation CTInAppPassThroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(viewWillPassThroughTouch)]) {
            [self.delegate viewWillPassThroughTouch];
        }
        return nil;
    }
    return view;
}
@end

@implementation CTInAppDisplayViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    self = [super init];
    if (self) {
        _notification = notification;
    }
    return self;
}

-(void)show:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

-(void)hide:(BOOL)animated {
    NSAssert(false, @"Override in sub-class");
}

- (void)showFromWindow:(BOOL)animated {
    
    if (!self.notification) return;
    
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.window.alpha = 0;
    self.window.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    self.window.windowLevel = UIWindowLevelNormal;
    self.window.rootViewController = self;
    [self.window setHidden:NO];
    
    void (^completionBlock)(void) = ^ {
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidShow:fromViewController:)]) {
            [self.delegate notificationDidShow:self.notification fromViewController:self];
        }
    };
    
    if (animated) {
        CGRect windowFrame = self.window.frame;
        CGRect transformWindowFrame = CGRectMake(0, -(windowFrame.size.height + windowFrame.origin.y),  [UIScreen mainScreen].bounds.size.width, windowFrame.size.height);
        self.window.frame = transformWindowFrame;
        
        [UIView animateWithDuration:0.33 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:10 options:UIViewAnimationOptionTransitionFlipFromTop animations:^{
            self.window.alpha = 1.0;
            self.window.frame = windowFrame;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } else {
        self.window.alpha = 1.0;
        completionBlock();
    }
}

-(void)hideFromWindow:(BOOL)animated {
    void (^completionBlock)(void) = ^ {
        [self.window setHidden:YES];
        [self.window removeFromSuperview];
        self.window = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationDidDismiss:fromViewController:)]) {
            [self.delegate notificationDidDismiss:self.notification fromViewController:self];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.window.alpha = 0;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    }
    else {
        completionBlock();
    }
}

#pragma mark CTInAppPassThroughViewDelegate
- (void)viewWillPassThroughTouch {
    [self hide:NO];
}

#pragma mark - Actions

- (void)tappedDismiss {
    [self hide:YES];
}

@end
