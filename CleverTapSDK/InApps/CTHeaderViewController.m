#import "CTHeaderViewController.h"
#import "CTBaseHeaderFooterViewControllerPrivate.h"
#import "CTUIUtils.h"

@interface CTHeaderViewController () {
}

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CTHeaderViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTHeaderViewController class])] owner:self options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topLength;
    if (@available(iOS 11.0, *)) {
        topLength = self.view.safeAreaInsets.top;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        topLength = self.topLayoutGuide.length;
#pragma clang diagnostic pop
    }
    [[NSLayoutConstraint constraintWithItem: self.containerView
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual
                                     toItem:self.view attribute:NSLayoutAttributeTop
                                 multiplier:1.0 constant:topLength] setActive:YES];
}


@end
