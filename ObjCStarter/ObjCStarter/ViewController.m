
#import "ViewController.h"
#import "CustomDomainViewController.h"
#import <CleverTapSDK/CleverTap.h>
#import <CleverTapSDK/CleverTapInstanceConfig.h>
#import <CleverTapSDK/CleverTap+Inbox.h>
#import <CleverTapSDK/CleverTap+PushPermission.h>
#import <CleverTapSDK/CTLocalInApp.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, CleverTapInboxViewControllerDelegate, CleverTapPushPermissionDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tblEvent;
@property (nonatomic, strong) NSMutableArray *eventList;

@property (nonatomic, strong) CleverTap *cleverTapAdditionalInstance;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadData];
    [self initializeAppInbox];
    self.tblEvent.tableFooterView = [UIView new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadData {
    [[CleverTap sharedInstance] setPushPermissionDelegate:self];
    self.eventList = [[NSMutableArray alloc] initWithObjects:@"Record User Profile",
                      @"Record User Profile with Properties",
                      @"Record User Event called Product Viewed",
                      @"Record User Event with Properties",
                      @"Record User Charged Event",
                      @"Record User event to an Additional instance",
                      @"Open App Inbox",
                      @"Analytics in a Webview",
                      @"Increment User Profile Property",
                      @"Decrement User Profile Property",
                      @"Activate Custom domain proxy",
                      @"Prompt for Push Notification",
                      @"Local Half Interstitial Push Primer",
                      @"Local Alert Push Primer",
                      @"InApp Campaign Push Primer", nil];
    [self. tblEvent reloadData];
}
    
- (void)initializeAppInbox {
    [[CleverTap sharedInstance] initializeInboxWithCallback:^(BOOL success) {
        int messageCount = (int)[[CleverTap sharedInstance] getInboxMessageCount];
        int unreadCount = (int)[[CleverTap sharedInstance] getInboxMessageUnreadCount];
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
            [self recordUserEventforAdditionalInstance];
            break;
        case 6:
            [self showAppInbox];
            break;
        case 7:
            [self navigateToWebview];
            break;
        case 8:
            [self incrementUserProfileProperty];
            break;
        case 9:
            [self decrementUserProfileProperty];
            break;
        case 10:
            [self activateCustomDomain];
            break;
        case 11:
            [self promptForPushNotification];
            break;
        case 12:
            [self createLocalHalfInterstitialPushPrimer];
            break;
        case 13:
            [self createLocalAlertPushPrimer];
            break;
        case 14:
            [self createInAppCampaignPushPrimer];
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
    
    [[CleverTap sharedInstance] profilePush:profile];
}
- (void)recordUserProfileWithProperties {
    // To set a multi-value property
    [[CleverTap sharedInstance] profileSetMultiValues:@[@"bag", @"shoes"] forKey:@"myStuff"];
    
    // To add an additional value(s) to a multi-value property
    [[CleverTap sharedInstance] profileAddMultiValue:@"coat" forKey:@"myStuff"];
    // or
    [[CleverTap sharedInstance] profileAddMultiValues:@[@"socks", @"scarf"] forKey:@"myStuff"];
    
    //To remove a value(s) from a multi-value property
    [[CleverTap sharedInstance] profileRemoveMultiValue:@"bag" forKey:@"myStuff"];
    [[CleverTap sharedInstance] profileRemoveMultiValues:@[@"shoes", @"coat"] forKey:@"myStuff"];
    
    //To remove the value of a property (scalar or multi-value)
    [[CleverTap sharedInstance] profileRemoveValueForKey:@"myStuff"];
}
- (void)recordUserEventWithoutProperties {
    // event without properties
    [[CleverTap sharedInstance] recordEvent:@"Product viewed"];
}
- (void)recordUserEventWithProperties {
    // event with properties
    NSDictionary *props = @{
                            @"Product name": @"Casio Chronograph Watch",
                            @"Category": @"Mens Accessories",
                            @"Price": @59.99,
                            @"Date": [NSDate date]
                            };
    
    [[CleverTap sharedInstance] recordEvent:@"Product viewed" withProps:props];
}
- (void)recordUserChargedEvent {
    // charged event
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
    [[CleverTap sharedInstance] recordChargedEventWithDetails:chargeDetails
                                                     andItems:items];
}
- (void)recordUserEventforAdditionalInstance {
    if (_cleverTapAdditionalInstance == nil) {
        CleverTapInstanceConfig *ctConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:@"R65-RR9-9R5Z" accountToken:@"c22-562"];
        _cleverTapAdditionalInstance = [CleverTap instanceWithConfig:ctConfig];
    }
    [_cleverTapAdditionalInstance recordEvent:@"TestCT1WProps" withProps:@{@"one": @1}];
    [_cleverTapAdditionalInstance profileSetMultiValues:@[@"bag", @"shoes"] forKey:@"myStuff"];
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
- (void)messageDidSelect:(CleverTapInboxMessage *)message atIndex:(int)index withButtonIndex:(int)buttonIndex {
    //  This is called when an inbox message is clicked(tapped or call to action)
}
- (void)navigateToWebview {
    [self performSegueWithIdentifier:@"segue_webview" sender:nil];
}

- (void)incrementUserProfileProperty {
    [[CleverTap sharedInstance] profileIncrementValueBy: @3 forKey: @"score"];
}

- (void)decrementUserProfileProperty {
    [[CleverTap sharedInstance] profileDecrementValueBy: @7 forKey: @"score"];
}

- (void)activateCustomDomain {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CustomDomainViewController *customDomainVC = [storyBoard instantiateViewControllerWithIdentifier:@"CustomDomainVC"];
    [self.navigationController pushViewController:customDomainVC animated:YES];
}

- (void)promptForPushNotification {
    [[CleverTap sharedInstance] promptForPushPermission:YES];
}

- (void)createLocalHalfInterstitialPushPrimer {
    [[CleverTap sharedInstance] getNotificationPermissionStatusWithCompletionHandler:^(UNAuthorizationStatus status) {
        if (status == UNAuthorizationStatusNotDetermined || status == UNAuthorizationStatusDenied) {
            CTLocalInApp *localInAppBuilder = [[CTLocalInApp alloc] initWithInAppType:HALF_INTERSTITIAL
                                                                            titleText:@"Get Notified"
                                                                          messageText:@"Please enable notifications on your device to use Push Notifications."
                                                              followDeviceOrientation:YES
                                                                      positiveBtnText:@"Allow"
                                                                      negativeBtnText:@"Cancel"];
            [localInAppBuilder setFallbackToSettings:YES];
            [localInAppBuilder setImageUrl:@"https://icons.iconarchive.com/icons/treetog/junior/64/camera-icon.png"];
            [[CleverTap sharedInstance] promptPushPrimer:localInAppBuilder.getLocalInAppSettings];
        } else {
            NSLog(@"Push Persmission is already enabled.");
        }
    }];
}

- (void)createLocalAlertPushPrimer {
    CTLocalInApp *localInAppBuilder = [[CTLocalInApp alloc] initWithInAppType:ALERT
                                                                    titleText:@"Get Notified"
                                                                  messageText:@"Enable Notification permission"
                                                      followDeviceOrientation:YES
                                                              positiveBtnText:@"Allow"
                                                              negativeBtnText:@"Cancel"];
    [localInAppBuilder setFallbackToSettings:YES];
    [[CleverTap sharedInstance] promptPushPrimer:localInAppBuilder.getLocalInAppSettings];
}

- (void)createInAppCampaignPushPrimer {
    [[CleverTap sharedInstance] recordEvent:@"InAppCampaignPushPrimer"];
}

#pragma mark - CleverTapPushPermissionDelegate

- (void)onPushPermissionResponse:(BOOL)accepted {
    NSLog(@"Push Permission response called ---> accepted = %d", accepted);
}

@end
