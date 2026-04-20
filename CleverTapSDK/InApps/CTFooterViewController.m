
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

- (void)layoutNotification {
    [super layoutNotification];
#if TARGET_OS_TV
    // Frame-based layout: full-width bar pinned to bottom of the 1920x1080 screen.
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    CGFloat barH = 200.0f;
    self.containerView.frame = CGRectMake(0, screenH - barH, screenW, barH);
#else
    if (@available(iOS 11, *)) {
        UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
        [self.containerView.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor].active = YES;
    }
#endif
}


@end
