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
    
    CGFloat statusBarFrame = [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
    [[NSLayoutConstraint constraintWithItem: self.containerView
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeTop
                                 multiplier:1.0 constant:statusBarFrame] setActive:YES];
}

@end
