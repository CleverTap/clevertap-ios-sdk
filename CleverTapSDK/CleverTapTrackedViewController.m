
#import "CleverTapTrackedViewController.h"
#import "CleverTap.h"

@implementation CleverTapTrackedViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.screenName) {
        [[CleverTap sharedInstance] recordScreenView:self.screenName];
    }
}


@end
