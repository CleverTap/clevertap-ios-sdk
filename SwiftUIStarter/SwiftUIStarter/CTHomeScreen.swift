import SwiftUI
import CleverTapSDK

var cleverTapAdditionalInstance: CleverTap = {
        let ctConfig = CleverTapInstanceConfig.init(accountId: "ZWW-WWW-WWRZ", accountToken: "000-001")
        return CleverTap.instance(with: ctConfig)
    }()

struct HomeScreen: View {
    let eventList = [  "Record User Profile",
                       "Record User Profile with Properties",
                       "Record User Event called Product Viewed",
                       "Record User Event with Properties",
                       "Record User Charged Event",
                       "Record User Event to an Additional Instance",
                       "Show App Inbox",
                       "Analytics in a WebView",
                       "Increment User Profile Property",
                       "Decrement User Profile Property",
                       "Activate Custom domain proxy",
                       "Local Half Interstitial Push Primer"
                    ]
    
    @State private var viewDidLoad = false
    
    var body: some View {
        NavigationView {
            VStack {
                Image("logo")
                    .scaledToFit()
                    .frame(height: 72)
                List {
                    ForEach(0 ..< eventList.count, id: \.self) { index in
                        HStack {
                            Button("\(eventList[index])") {
                                buttonAction(index: index)
                            }
                            Spacer()
                            if (eventList[index] == "Show App Inbox") {
                                // Show App Inbox controller
                                NavigationLink(destination: CTAppInboxRepresentable()) { }
                            } else if (eventList[index] == "Analytics in a WebView") {
                                // Show Web View
                                NavigationLink(destination: CTWebViewRepresentable()) { }
                            }
                        }
                    }
                }
            }
            .onAppear() {
                print("~~~ onAppear")
                if viewDidLoad == false {
                    viewDidLoad = true
                    self.registerAppInbox()
                    self.initializeAppInbox()
                    print("~~~ viewDidLoad")
                }
            }
        }
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
    
func buttonAction(index: Int) {
    switch(index) {
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
            createLocalHalfInterstitialPushPrimer()
            break;
        default:
            break;
    }
}

func recordUserProfile() {
    // each of the below mentioned fields are optional
    // if set, these populate demographic information in the Dashboard
    let dob = NSDateComponents()
    dob.day = 24
    dob.month = 5
    dob.year = 1993
    let d = NSCalendar.current.date(from: dob as DateComponents)
    let profile: Dictionary<String, AnyObject> = [
        "Name": "Nishant" as AnyObject,                 // String
        "Identity": 6196032 as AnyObject,                   // String or number
        "Email": "testnishant@gmail.com" as AnyObject,              // Email address of the user
        "Phone": "+1415501234" as AnyObject,                // Phone (with the country code, starting with +)
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
    /// To set a multi-value property
    CleverTap.sharedInstance()?.profileSetMultiValues(["bag", "shoes"], forKey: "myStuff")
    
    /// To add an additional value(s) to a multi-value property
    // CleverTap.sharedInstance()?.profileAddMultiValue("coat", forKey: "myStuff")
    // CleverTap.sharedInstance()?.profileAddMultiValues(["socks", "scarf"], forKey: "myStuff")
    
    /// To remove a value(s) from a multi-value property
    // CleverTap.sharedInstance()?.profileRemoveMultiValue("bag", forKey: "myStuff")
    // CleverTap.sharedInstance()?.profileRemoveMultiValues(["shoes", "coat"], forKey: "myStuff")
    
    /// To remove the value of a property (scalar or multi-value)
    // CleverTap.sharedInstance()?.profileRemoveValue(forKey: "myStuff")
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

func incrementUserProfileProperty() {
    CleverTap.sharedInstance()?.profileIncrementValue(by: NSNumber(value: 1), forKey: "score")
}

func decrementUserProfileProperty() {
    CleverTap.sharedInstance()?.profileDecrementValue(by: NSNumber(value: 1), forKey: "score")
}

func activateCustomDomain() {
//        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
//        let customDomainVC = storyBoard.instantiateViewController(withIdentifier: "CustomDomainVC")
//        self.navigationController?.pushViewController(customDomainVC, animated: true)
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

#if DEBUG
struct CTHomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        CTHomeScreen()
    }
}
#endif
