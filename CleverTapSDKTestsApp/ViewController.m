#import "ViewController.h"
#import <CleverTapSDK/CleverTap.h>
#import <CleverTapSDK/CleverTapInstanceConfig.h>
#import <CleverTapSDK/CleverTap+Inbox.h>

@interface ViewController () <CleverTapInboxViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    [self initializeAppInbox];
}

- (void)initializeAppInbox {
    [[CleverTap sharedInstance] initializeInboxWithCallback:^(BOOL success) {
        int messageCount = (int)[[CleverTap sharedInstance] getInboxMessageCount];
        int unreadCount = (int)[[CleverTap sharedInstance] getInboxMessageUnreadCount];
        NSLog(@"Inbox Message: %d/%d", messageCount, unreadCount);
        [self showAppInbox];
    }];
}

- (void)showAppInbox {
    CleverTapInboxStyleConfig *style = [[CleverTapInboxStyleConfig alloc] init];
    style.messageTags = @[@"tag1", @"tag2"];
    style.tabSelectedBgColor = [UIColor blueColor];
    style.tabSelectedTextColor = [UIColor whiteColor];
    CleverTapInboxViewController *inboxController = [[CleverTap sharedInstance] newInboxViewControllerWithConfig:style andDelegate:self];
    if (inboxController) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inboxController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}




@end
