#import "CTFooterViewController.h"
#import "CTBaseHeaderFooterViewControllerPrivate.h"

@interface CTFooterViewController () {
}

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CTFooterViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTFooterViewController class])] owner:self options:nil];
}

- (void)layoutNotification {
    [super layoutNotification];
    
    if (@available(iOS 11, *)) {
        UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
        [self.containerView.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor].active = YES;
    }
}

@end
