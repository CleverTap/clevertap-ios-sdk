#import "CustomDomainViewController.h"
#import <CleverTapSDK/CleverTap.h>
#import <CleverTapSDK/CleverTapInstanceConfig.h>
#import <CleverTapSDK/CleverTap+Inbox.h>

@interface CustomDomainViewController() <UITableViewDelegate, UITableViewDataSource, CleverTapInboxViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tblView;
@property (nonatomic, strong) NSMutableArray *eventList;
@property (nonatomic, strong) CleverTap *cleverTapAdditionalInstance;
@end

@implementation CustomDomainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    CleverTapInstanceConfig *ctConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:@"R65-RR9-9R5Z" accountToken:@"c22-562" proxyDomain:@"analytics.sdktesting.xyz"];
//    or to use spiky proxy domain call
//    [[CleverTapInstanceConfig alloc] initWithAccountId:@"R65-RR9-9R5Z" accountToken:@"c22-562" proxyDomain:@"analytics.sdktesting.xyz" spikyProxyDomain:@"analyticst.sdktesting.xyz"];
    [ctConfig setLogLevel: CleverTapLogDebug];
    _cleverTapAdditionalInstance = [CleverTap instanceWithConfig:ctConfig];
    
    [self loadData];
    [self initializeAppInbox];
    self.tblView.tableFooterView = [UIView new];
}

- (void)loadData {
    [_cleverTapAdditionalInstance recordScreenView:@"CustomDomainViewController"];
    self.eventList = [[NSMutableArray alloc] initWithObjects:@"Record User Profile",
                      @"Record User Profile with Properties",
                      @"Record User Event called Product Viewed",
                      @"Record User Event with Properties",
                      @"Record User Charged Event",
                      @"Open App Inbox",
                      @"Increment User Profile Property",
                      @"Decrement User Profile Property", nil];
    [self.tblView reloadData];
}
    
- (void)initializeAppInbox {
    [_cleverTapAdditionalInstance initializeInboxWithCallback:^(BOOL success) {
        int messageCount = (int)[self.cleverTapAdditionalInstance getInboxMessageCount];
        int unreadCount = (int)[self.cleverTapAdditionalInstance getInboxMessageUnreadCount];
        NSLog(@"Inbox Message: %d/%d", messageCount, unreadCount);
    }];
}

#pragma mark - Table view Delegate and Data Source

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    static NSString *simpleTableIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [self.eventList objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _eventList.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self recordUserProfile];
            break;
        case 1:
            [self recordUserProfileWithProperties];
            break;
        case 2:
            [self recordUserEventWithoutProperties];
            break;
        case 3:
            [self recordUserEventWithProperties];
            break;
        case 4:
            [self recordUserChargedEvent];
            break;
        case 5:
            [self showAppInbox];
            break;
        case 6:
            [self incrementUserProfileProperty];
            break;
        case 7:
            [self decrementUserProfileProperty];
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void)recordUserProfile {
    
    // each of the below mentioned fields are optional
    // if set, these populate demographic information in the Dashboard
    NSDateComponents *dob = [[NSDateComponents alloc] init];
    dob.day = 24;
    dob.month = 5;
    dob.year = 1992;
    NSDate *d = [[NSCalendar currentCalendar] dateFromComponents:dob];
    NSDictionary *profile = @{
                              @"Name": @"Jack Montana",               // String
                              @"Identity": @61026032,                 // String or number
                              @"Email": @"jack@gmail.com",            // Email address of the user
                              @"Phone": @"+14155551234",              // Phone (with the country code, starting with +)
                              @"Gender": @"M",                        // Can be either M or F
                              @"Employed": @"Y",                      // Can be either Y or N
                              @"Education": @"Graduate",              // Can be either Graduate, College or School
                              @"Married": @"Y",                       // Can be either Y or N
                              @"DOB": d,                              // Date of Birth. An NSDate object
                              @"Age": @28,                            // Not required if DOB is set
                              @"Tz": @"Asia/Kolkata",                 //an abbreviation such as "PST", a full name such as "America/Los_Angeles",
                              //or a custom ID such as "GMT-8:00"
                              @"Photo": @"www.foobar.com/image.jpeg", // URL to the Image
                              
                              // optional fields. controls whether the user will be sent email, push etc.
                              @"MSG-email": @NO,                      // Disable email notifications
                              @"MSG-push": @YES,                      // Enable push notifications
                              @"MSG-sms": @NO,                         // Disable SMS notifications
                              
                              //custom fields
                              @"score": @15,
                              @"cost": @10.5

                              };
    
    [_cleverTapAdditionalInstance profilePush:profile];
}
- (void)recordUserProfileWithProperties {
    // To set a multi-value property
    [_cleverTapAdditionalInstance profileSetMultiValues:@[@"bag", @"shoes"] forKey:@"myStuff"];
    
    // To add an additional value(s) to a multi-value property
    [_cleverTapAdditionalInstance profileAddMultiValue:@"coat" forKey:@"myStuff"];
    // or
    [_cleverTapAdditionalInstance profileAddMultiValues:@[@"socks", @"scarf"] forKey:@"myStuff"];
    
    //To remove a value(s) from a multi-value property
    [_cleverTapAdditionalInstance profileRemoveMultiValue:@"bag" forKey:@"myStuff"];
    [_cleverTapAdditionalInstance profileRemoveMultiValues:@[@"shoes", @"coat"] forKey:@"myStuff"];
    
    //To remove the value of a property (scalar or multi-value)
    [_cleverTapAdditionalInstance profileRemoveValueForKey:@"myStuff"];
}
- (void)recordUserEventWithoutProperties {
    // event without properties
    [_cleverTapAdditionalInstance recordEvent:@"Product viewed"];
}
- (void)recordUserEventWithProperties {
    // event with properties
    NSDictionary *props = @{
                            @"Product name": @"Casio Chronograph Watch",
                            @"Category": @"Mens Accessories",
                            @"Price": @59.99,
                            @"Date": [NSDate date]
                            };
    
    [_cleverTapAdditionalInstance recordEvent:@"Product viewed" withProps:props];
}
- (void)recordUserChargedEvent {
    NSDictionary *chargeDetails = @{
                                    @"Amount" : @300,
                                    @"Payment mode": @"Credit Card",
                                    @"Charged ID": @24052013
                                    };
    
    NSDictionary *item1 = @{
                            @"Category": @"books",
                            @"Book name": @"The Millionaire next door",
                            @"Quantity": @1
                            };
    
    NSDictionary *item2 = @{
                            @"Category": @"books",
                            @"Book name": @"Achieving inner zen",
                            @"Quantity": @1
                            };
    
    NSDictionary *item3 = @{
                            @"Category": @"books",
                            @"Book name": @"Chuck it, let's do it",
                            @"Quantity": @5
                            };
    
    NSArray *items = @[item1, item2, item3];
    [_cleverTapAdditionalInstance recordChargedEventWithDetails:chargeDetails
                                                     andItems:items];
}

- (void)showAppInbox {
    
    CleverTapInboxStyleConfig *style = [[CleverTapInboxStyleConfig alloc] init];
    style.messageTags = @[@"tag1", @"tag2"];
    style.tabSelectedBgColor = [UIColor blueColor];
    style.tabSelectedTextColor = [UIColor whiteColor];
    CleverTapInboxViewController *inboxController = [_cleverTapAdditionalInstance newInboxViewControllerWithConfig:style andDelegate:self];
    if (inboxController) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:inboxController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}
- (void)messageDidSelect:(CleverTapInboxMessage *)message atIndex:(int)index withButtonIndex:(int)buttonIndex {
    //  This is called when an inbox message is clicked(tapped or call to action)
}

- (void)incrementUserProfileProperty {
    [_cleverTapAdditionalInstance profileIncrementValueBy: @3 forKey: @"score"];
}

- (void)decrementUserProfileProperty {
    [_cleverTapAdditionalInstance profileDecrementValueBy: @7 forKey: @"score"];
}

- (void)activateCustomDomain {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *customDomainVC = [storyBoard instantiateViewControllerWithIdentifier:@"CustomDomainVC"];
    [self.navigationController pushViewController:customDomainVC animated:YES];
}

@end
