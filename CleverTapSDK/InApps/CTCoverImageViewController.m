#import "CTCoverImageViewController.h"
#import "CTImageInAppViewControllerPrivate.h"
#import "CTInAppResources.h"
#import "CTDismissButton.h"

@interface CTCoverImageViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet CTDismissButton *closeButton;

@end

@implementation CTCoverImageViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils XibNameForControllerName:NSStringFromClass([CTCoverImageViewController class])]
                                  owner:self
                                options:nil];
}


#pragma mark - Setup Notification

- (void)layoutNotification {
    [super layoutNotification];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topLength = self.topLayoutGuide.length;
    [[NSLayoutConstraint constraintWithItem: self.closeButton
                                  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                     toItem:self.containerView
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1.0 constant:topLength] setActive:YES];
}


@end
