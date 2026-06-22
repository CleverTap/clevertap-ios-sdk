
#import "CTFooterViewController.h"
#import "CTBaseHeaderFooterViewControllerPrivate.h"

@interface CTFooterViewController () {
    
}

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CTFooterViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTFooterViewController class])] owner:self options:nil];
}

#if TARGET_OS_TV
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    CGFloat barH = 200.0f;
    self.containerView.frame = CGRectMake(0, screenH - barH, screenW, barH);
}
#endif

- (void)layoutNotification {
    [super layoutNotification];
#if TARGET_OS_TV
    // Deactivate XIB constraints on the root view and containerView itself,
    // then switch containerView to frame-based layout. viewWillLayoutSubviews
    // re-applies the frame each pass so Auto Layout cannot override it.
    NSMutableArray *toDeactivate = [NSMutableArray array];
    for (NSLayoutConstraint *c in self.view.constraints) {
        if (c.firstItem == self.containerView || c.secondItem == self.containerView) {
            [toDeactivate addObject:c];
        }
    }
    // Deactivate only the self-sizing constraints on containerView (e.g. height=200)
    // so the frame-based height won't conflict. Internal subview arrangement
    // constraints must stay active.
    for (NSLayoutConstraint *c in self.containerView.constraints) {
        if (c.secondItem == nil) {
            [toDeactivate addObject:c];
        }
    }
    [NSLayoutConstraint deactivateConstraints:toDeactivate];
    self.containerView.translatesAutoresizingMaskIntoConstraints = YES;
#else
    if (@available(iOS 11, *)) {
        UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
        [self.containerView.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor].active = YES;
    }
#endif
}


@end
