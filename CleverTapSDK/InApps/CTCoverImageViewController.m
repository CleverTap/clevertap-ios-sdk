#import "CTCoverImageViewController.h"
#import "CTImageInAppViewControllerPrivate.h"
#import "CTUIUtils.h"
#import "CTDismissButton.h"

@interface CTCoverImageViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;

@end

@implementation CTCoverImageViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTCoverImageViewController class])]
                                  owner:self
                                options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
}

#if !(TARGET_OS_TV)
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Push closeButton below the status bar on iPhone using safe area / topLayoutGuide.
    // Not needed on tvOS — closeButton position is set frame-based in the base class
    // viewWillLayoutSubviews (15pt from top-right corner of the full-screen card).
    CGFloat topLength;
    if (@available(iOS 11.0, *)) {
        topLength = self.view.safeAreaInsets.top;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        topLength = self.topLayoutGuide.length;
#pragma clang diagnostic pop
    }
    [[NSLayoutConstraint constraintWithItem: self.closeButton
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1.0 constant:topLength] setActive:YES];
}
#endif


@end
