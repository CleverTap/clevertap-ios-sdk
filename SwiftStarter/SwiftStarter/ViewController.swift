import UIKit
import CleverTapSDK
import UserNotifications

class ViewController: UIViewController, CleverTapInboxViewControllerDelegate, CleverTapPushPermissionDelegate {
    
    @IBOutlet var tblEvent: UITableView!
    var eventList: [String] = [String]()
    
    lazy var cleverTapAdditionalInstance: CleverTap = {
        let ctConfig = CleverTapInstanceConfig.init(accountId: "R65-RR9-9R5Z", accountToken: "c22-562")
        return CleverTap.instance(with: ctConfig)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        CleverTap.sharedInstance()?.setPushPermissionDelegate(self)
        loadData()
        registerAppInbox()
        initializeAppInbox()
        tblEvent.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func messageDidSelect(_ message: CleverTapInboxMessage, at index: Int32, withButtonIndex buttonIndex: Int32) {
        //  This is called when an inbox message is clicked(tapped or call to action)
    }
}

extension ViewController {
    
    func loadData(){
        eventList.append("Record User Profile")
        eventList.append("Record User Profile with Properties")
        eventList.append("Record User Event called Product Viewed")
        eventList.append("Record User Event with Properties")
        eventList.append("Record User Charged Event")
        eventList.append("Record User event to an Additional instance")
        eventList.append("Show App Inbox")
        eventList.append("Analytics in a Webview")
        eventList.append("Increment User Profile Property")
        eventList.append("Decrement User Profile Property")
        eventList.append("Activate Custom domain proxy")
        eventList.append("Prompt for Push Notification")
        eventList.append("Local Half Interstitial Push Primer")
        eventList.append("Local Alert Push Primer")
        eventList.append("InApp Campaign Push Primer")
        self.tblEvent.reloadData()
    }
    
    func registerAppInbox() {
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock({
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        })
    }
    
    func initializeAppInbox() {
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        }))
    }
}
extension ViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eventList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = self.eventList[indexPath.row]
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\(indexPath.row)!")
        
        switch(indexPath.row)
        {
        case 0:
            recordUserProfile()
            break;
        case 1:
            recordUserProfileWithProperties()
            break;
        case 2:
            recordUserEventWithoutProperties()
            break;
        case 3:
            recordUserEventWithProperties()
            break;
        case 4:
            recordUserChargedEvent()
            break;
        case 5:
            recordUserEventforAdditionalInstance()
            break;
        case 6:
            showAppInbox()
            break;
        case 7:
            navigateToWebview()
            break;
        case 8:
            incrementUserProfileProperty()
            break;
        case 9:
            decrementUserProfileProperty()
            break;
        case 10:
            activateCustomDomain()
            break;
        case 11:
            promptForPushNotification()
            break;
        case 12:
            createLocalHalfInterstitialPushPrimer()
            break;
        case 13:
            createLocalAlertPushPrimer()
            break;
        case 14:
            createInAppCampaignPushPrimer()
            break;
        default:
            break;
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func recordUserProfile() {
        
        // each of the below mentioned fields are optional
        // if set, these populate demographic information in the Dashboard
        let dob = NSDateComponents()
        dob.day = 24
        dob.month = 5
        dob.year = 1992
        let d = NSCalendar.current.date(from: dob as DateComponents)
        let profile: Dictionary<String, AnyObject> = [
            "Name": "Jack Montana" as AnyObject,                 // String
            "Identity": 61026032 as AnyObject,                   // String or number
            "Email": "jack@gmail.com" as AnyObject,              // Email address of the user
            "Phone": "+14155551234" as AnyObject,                // Phone (with the country code, starting with +)
            "Gender": "M" as AnyObject,                          // Can be either M or F
            "Employed": "Y" as AnyObject,                        // Can be either Y or N
            "Education": "Graduate" as AnyObject,                // Can be either School, College or Graduate
            "Married": "Y" as AnyObject,                         // Can be either Y or N
            "DOB": d! as AnyObject,                              // Date of Birth. An NSDate object
            "Age": 26 as AnyObject,                              // Not required if DOB is set
            "Tz":"Asia/Kolkata" as AnyObject,                    //an abbreviation such as "PST", a full name such as "America/Los_Angeles",
            //or a custom ID such as "GMT-8:00"
            "Photo": "www.foobar.com/image.jpeg" as AnyObject,   // URL to the Image
            
            // optional fields. controls whether the user will be sent email, push etc.
            "MSG-email": false as AnyObject,                     // Disable email notifications
            "MSG-push": true as AnyObject,                       // Enable push notifications
            "MSG-sms": false as AnyObject,                        // Disable SMS notifications
            
            //custom fields
            "score": 15 as AnyObject,
            "cost": 10.5 as AnyObject
        ]
        
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    func recordUserProfileWithProperties() {
        // To set a multi-value property
        CleverTap.sharedInstance()?.profileSetMultiValues(["bag", "shoes"], forKey: "myStuff")
        
        // To add an additional value(s) to a multi-value property
        CleverTap.sharedInstance()?.profileAddMultiValue("coat", forKey: "myStuff")
        // or
        CleverTap.sharedInstance()?.profileAddMultiValues(["socks", "scarf"], forKey: "myStuff")
        
        //To remove a value(s) from a multi-value property
        CleverTap.sharedInstance()?.profileRemoveMultiValue("bag", forKey: "myStuff")
        CleverTap.sharedInstance()?.profileRemoveMultiValues(["shoes", "coat"], forKey: "myStuff")
        
        //To remove the value of a property (scalar or multi-value)
        CleverTap.sharedInstance()?.profileRemoveValue(forKey: "myStuff")
    }
    
    func recordUserEventWithoutProperties() {
        // event without properties
        CleverTap.sharedInstance()?.recordEvent("Product viewed")
    }
    
    func recordUserEventWithProperties() {
        // event with properties
        let props = [
            "Product name": "Casio Chronograph Watch",
            "Category": "Mens Accessories",
            "Price": 59.99,
            "Date": NSDate()
            ] as [String : Any]
        CleverTap.sharedInstance()?.recordEvent("Product viewed", withProps: props)
    }
    
    func recordUserChargedEvent() {
        //charged event
        let chargeDetails = [
            "Amount": 300,
            "Payment mode": "Credit Card",
            "Charged ID": 24052013
            ] as [String : Any]
        
        let item1 = [
            "Category": "books",
            "Book name": "The Millionaire next door",
            "Quantity": 1
            ] as [String : Any]
        
        let item2 = [
            "Category": "books",
            "Book name": "Achieving inner zen",
            "Quantity": 1
            ] as [String : Any]
        
        let item3 = [
            "Category": "books",
            "Book name": "Chuck it, let's do it",
            "Quantity": 5
            ] as [String : Any]
        
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: chargeDetails, andItems: [item1, item2, item3])
    }
    
    func recordUserEventforAdditionalInstance() {
        cleverTapAdditionalInstance.recordEvent("TestCT1WProps", withProps: ["one": NSNumber.init(integerLiteral: 1)])
        cleverTapAdditionalInstance.profileSetMultiValues(["a"], forKey: "letters")
    }
    
    func showAppInbox() {
        
        // config the style of App Inbox Controller
        let style = CleverTapInboxStyleConfig.init()
        style.title = "App Inbox"
        style.navigationTintColor = .black
        
        if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self) {
            let navigationController = UINavigationController.init(rootViewController: inboxController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func navigateToWebview() {
        self.performSegue(withIdentifier: "segue_webview", sender: nil)
    }
    
    func incrementUserProfileProperty() {
        CleverTap.sharedInstance()?.profileIncrementValue(by: NSNumber(value: 1), forKey: "score")
    }
    
    func decrementUserProfileProperty() {
        CleverTap.sharedInstance()?.profileDecrementValue(by: NSNumber(value: 1), forKey: "score")
    }
    
    func activateCustomDomain() {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let customDomainVC = storyBoard.instantiateViewController(withIdentifier: "CustomDomainVC")
        self.navigationController?.pushViewController(customDomainVC, animated: true)
    }
    
    func promptForPushNotification() {
        CleverTap.sharedInstance()?.prompt(forPushPermission: true)
    }
    
    func createLocalHalfInterstitialPushPrimer() {
        CleverTap.sharedInstance()?.getNotificationPermissionStatus(completionHandler: { status in
            if status == .notDetermined || status == .denied {
                let localInAppBuilder = CTLocalInApp(inAppType: CTLocalInAppType.HALF_INTERSTITIAL, titleText: "Get Notified", messageText: "Please enable notifications on your device to use Push Notifications.", followDeviceOrientation: true, positiveBtnText: "Allow", negativeBtnText: "Cancel")
                localInAppBuilder.setFallbackToSettings(true)
                localInAppBuilder.setImageUrl("https://icons.iconarchive.com/icons/treetog/junior/64/camera-icon.png")
                CleverTap.sharedInstance()?.promptPushPrimer(localInAppBuilder.getSettings())
            } else {
                print("Push Persmission is already enabled.")
            }
        })
    }
    
    func createLocalAlertPushPrimer() {
        let localInAppBuilder = CTLocalInApp(inAppType: .ALERT, titleText: "Get Notified", messageText: "Enable Notification permission", followDeviceOrientation: true, positiveBtnText: "Allow", negativeBtnText: "Cancel")
        localInAppBuilder.setFallbackToSettings(true)
        CleverTap.sharedInstance()?.promptPushPrimer(localInAppBuilder.getSettings())
    }
    
    func createInAppCampaignPushPrimer() {
        CleverTap.sharedInstance()?.recordEvent("InAppCampaignPushPrimer")
    }
    
    // MARK: CleverTapPushPermissionDelegate
    func onPushPermissionResponse(_ accepted: Bool) {
        print("Push Permission response called ---> accepted = \(accepted)")
    }
}

