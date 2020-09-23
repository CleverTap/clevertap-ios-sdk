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
    if (@available(iOS 11.0, *)) {
        CGFloat statusBarFrame = [[CTInAppResources getSharedApplication] statusBarFrame].size.height;
        [[NSLayoutConstraint constraintWithItem: self.closeButton
                                      attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1.0 constant:statusBarFrame] setActive:YES];
        
    } else {
        // Fallback on earlier versions
    }
}
@end
