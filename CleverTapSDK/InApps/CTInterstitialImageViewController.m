
#import "CTInterstitialImageViewController.h"
#import "CTImageInAppViewControllerPrivate.h"
#import "CTUIUtils.h"

@interface CTInterstitialImageViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation CTInterstitialImageViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTInterstitialImageViewController class])] owner:self options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
    if ([CTUIUtils screenBounds].size.height == 480) {
        [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[NSLayoutConstraint constraintWithItem:self.containerView
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView
                                      attribute:NSLayoutAttributeHeight
                                     multiplier:0.6 constant:0] setActive:YES];
        
    }
}

@end
