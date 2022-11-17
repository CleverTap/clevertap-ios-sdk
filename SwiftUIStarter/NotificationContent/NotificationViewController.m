#import "NotificationViewController.h"

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

// optional: implement to get user event type data
- (void)userDidPerformAction:(NSString *)action withProperties:(NSDictionary *)properties {
    NSLog(@"user did perform action: %@ with props: %@", action , properties);
}

// optional: implement to get notification response
- (void)userDidReceiveNotificationResponse:(UNNotificationResponse *)response {
    NSLog(@"user did receive notification response: %@:", response);
}

@end
