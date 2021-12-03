
#import "CTHalfInterstitialImageViewController.h"
#import "CTImageInAppViewControllerPrivate.h"

@interface CTHalfInterstitialImageViewController ()

@end

@implementation CTHalfInterstitialImageViewController

- (void)loadView {
    [super loadView];
    [[CTInAppUtils bundle] loadNibNamed:[CTInAppUtils getXibNameForControllerName:NSStringFromClass([CTHalfInterstitialImageViewController class])]
                                  owner:self
                                options:nil];
}


@end
