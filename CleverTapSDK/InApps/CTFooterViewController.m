#import "CTFooterViewController.h"
#import "CTBaseHeaderFooterViewControllerPrivate.h"

@interface CTFooterViewController () {
}

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CTFooterViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    self = [super
            initWithNibName:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTFooterViewController class])]
            bundle:[CTInAppUtils bundle]
            notification:notification];
    return self;
}

- (void)layoutNotification {
    [super layoutNotification];
    
    if (@available(iOS 11, *)) {
        UILayoutGuide *layoutGuide = self.view.safeAreaLayoutGuide;
        [self.containerView.bottomAnchor constraintEqualToAnchor:layoutGuide.bottomAnchor].active = YES;
    }
}

@end
