//
//  EventRow.swift
//  SwiftUIStarter
//
//  Created by Kushagra Mishra on 17/11/22.
//

import SwiftUI
import CleverTapSDK

struct EventRow: View {
    let event: CTEvent
    @State private var selectedIndex: Int?
    
    var body: some View {
        HStack {
            Button(action: {
                selectedIndex = event.id
                listView(listIndex: selectedIndex ?? 0)
            }, label: {
                Text("\(event.name)")
            })
//            Text("\(event.name)")
            Spacer()
            if (event.name == "Show App Inbox"){
                NavigationLink(destination: AppInboxView()) {
                }
            }
            else if (event.name == "Analytics in a WebView"){
                NavigationLink(destination: MyWebViewVC()) {
                }
            }
//            else if (event.name == "Activate Custom domain proxy"){
//                NavigationLink(destination: MyCustomDomainViewController()) {
//                }
//            }
            
            
        }
    }
}
func listView(listIndex: Int){
        switch listIndex {
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
//        case 10: activateCustomDomain()
        default:
            break;
    }
}
//
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
//
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
//
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
//
    func recordUserEventforAdditionalInstance() {
        lazy var cleverTapAdditionalInstance: CleverTap = {
            let ctConfig = CleverTapInstanceConfig.init(accountId: "R65-RR9-9R5Z", accountToken: "c22-562")
            return CleverTap.instance(with: ctConfig)
        }()
        cleverTapAdditionalInstance.recordEvent("TestCT1WProps", withProps: ["one": NSNumber.init(integerLiteral: 1)])
        cleverTapAdditionalInstance.profileSetMultiValues(["a"], forKey: "letters")
    }

//
//    func navigateToWebview() {
////        self.performSegue(withIdentifier: "segue_webview", sender: nil)
//    }
//
    func incrementUserProfileProperty() {
        CleverTap.sharedInstance()?.profileIncrementValue(by: NSNumber(value: 1), forKey: "score")
    }

    func decrementUserProfileProperty() {
        CleverTap.sharedInstance()?.profileDecrementValue(by: NSNumber(value: 1), forKey: "score")
    }
//
//    func activateCustomDomain() {
//        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
//        let customDomainVC = storyBoard.instantiateViewController(withIdentifier: "CustomDomainVC")
////        self.navigationController?.pushViewController(customDomainVC, animated: true)
////    }
//
//
//}

struct PersonRow_Previews: PreviewProvider {
    static var previews: some View {
        EventRow(event: .init(id: 1, name: "Artem"))
    }
}
