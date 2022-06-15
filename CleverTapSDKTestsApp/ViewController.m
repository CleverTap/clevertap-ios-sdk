#import "ViewController.h"
#import <CleverTapSDK/CleverTap.h>
#import <CleverTapSDK/CleverTapInstanceConfig.h>
#import <CleverTapSDK/CleverTap+Inbox.h>
#import "TestConstants.h"
#import <CleverTapSDK/CleverTapInAppNotificationDelegate.h>

@interface ViewController () <CleverTapInboxViewControllerDelegate, CleverTapInAppNotificationDelegate>
//@property (nonatomic, retain) StubHelper *stubHelper;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [[CleverTap sharedInstance]setInAppNotificationDelegate:self];
}

- (IBAction)inappAlertPressed {
    [[CleverTap sharedInstance]recordEvent: kEventAlertRequested];
}

- (IBAction)inappInterstitalPressed {
    [[CleverTap sharedInstance]recordEvent: kEventInterstitalRequested];
}

- (IBAction)inboxPressed {
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

- (BOOL)shouldShowInAppNotificationWithExtras:(NSDictionary *)extras; {

    return YES;
}


@end
