#import "CTHeaderViewController.h"
#import "CTBaseHeaderFooterViewControllerPrivate.h"
#import "CTInAppResources.h"

@interface CTHeaderViewController () {
}

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CTHeaderViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTHeaderViewController class])] owner:self options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topLength = self.topLayoutGuide.length;
    [[NSLayoutConstraint constraintWithItem: self.containerView
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeTop
                                 multiplier:1.0 constant:topLength] setActive:YES];
}


@end
