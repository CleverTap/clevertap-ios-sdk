import UIKit
import CleverTapSDK

class WareHouseVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCTInbox()
    }
    
    func registerCTInbox() {
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock(({
            //            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            //            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
        }))
        
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            //            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            //            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
        }))
    }
    
    @IBAction func fireTestInApp(_ sender: Any) {
        CleverTap.sharedInstance()?.recordScreenView("recordScreen")
        CleverTap.sharedInstance()?.recordEvent("test ios")
        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
        CleverTap.sharedInstance()?.recordEvent("Cover")
        CleverTap.sharedInstance()?.recordEvent("Interstitial")
        CleverTap.sharedInstance()?.recordEvent("Header")
        CleverTap.sharedInstance()?.recordEvent("Interstitial Video")
        CleverTap.sharedInstance()?.recordEvent("Footer")
        CleverTap.sharedInstance()?.recordEvent("Cover Image")
        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
        CleverTap.sharedInstance()?.recordEvent("Footer")
        CleverTap.sharedInstance()?.recordEvent("Header")
        CleverTap.sharedInstance()?.recordEvent("Cover Image")
        CleverTap.sharedInstance()?.recordEvent("Tablet only Header")
        CleverTap.sharedInstance()?.recordEvent("Interstitial Gif")
        CleverTap.sharedInstance()?.recordEvent("Interstitial ios")
        CleverTap.sharedInstance()?.recordEvent("Charged")
        CleverTap.sharedInstance()?.recordEvent("Interstitial video")
        CleverTap.sharedInstance()?.recordEvent("Interstitial Image")
        CleverTap.sharedInstance()?.recordEvent("Half Interstitial Image")
    }
    @IBAction func fireAllEvents(_ sender: Any) {
        
        CleverTap.sharedInstance()?.recordScreenView("Test: iOS - Simple Screen event")
        CleverTap.sharedInstance()?.recordEvent("Test: iOS - Simple event_1", withProps: [:])
        CleverTap.sharedInstance()?.recordEvent("Test: iOS - Simple event_2", withProps: ["Property1": "Value1"])
        CleverTap.sharedInstance()?.recordEvent("Charged")
        CleverTap.sharedInstance()?.recordEvent("Test: iOS - Simple event_3", withProps: ["Integer": 3])
        CleverTap.sharedInstance()?.recordEvent("Test: iOS - Simple event_4", withProps: ["Not Empty Property": "Okay", "Empty Property": ""])
        
        let props = [ "Product name": "Watch",
                      "Category": "Accessories",
                      "Price": 33.33,
                      "Date": Date()] as [String : Any]
        let props1 = [["key1": "value1", "key2": "value2"], ["key1": "value3", "key2": "value4"]]
        
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: props, andItems: props1)
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: ["Amount": 9900], andItems: props1)
        
        let details = ["Amount": 99900,
                       "Card Type": "CT Platinum"] as [String : Any]
        
        let item1 = [
            "Category": "Electronic",
            "Book name": "iMac",
            "Quantity": 1
            ] as [String : Any]
        
        let item2 = [
            "Category": "Electronic",
            "Book name": "iPhone",
            "Quantity": 1
            ] as [String : Any]
        
        let item3 = [
            "Category": "Electronic",
            "Book name": "ear phones",
            "Quantity": 1
            ] as [String : Any]
        
        var items: [[String : Any]] = [[String : Any]]()
        items.append(item1)
        items.append(item2)
        items.append(item3)
        
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: details, andItems: items)
        
        let profile = ["Name": "आदिति अग्रवाल",
                       "Identity": 1010,
                       "Email": "jayhawks@clevertap.com",
                       "Phone": "9833108201",
                       "Gender": "F",
                       "DOB": "10/09",
                       "Employed": "Y"] as [String : Any]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    @IBAction func fireEventValidation(_ sender: Any) {
        
        CleverTap.sharedInstance()?.recordEvent("Validation test", withProps: ["Hindi long string" : "हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK? हैलो वर्ल्ड OK?"])
        
        CleverTap.sharedInstance()?.recordEvent("Validation test", withProps: ["English long string" : "The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. "])
        
        CleverTap.sharedInstance()?.recordEvent("Validation test", withProps: ["Pure Arabic long string" :  "العالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالممرحبا العالم",
                                                                               "English in the beginning" : "Hello World!: العالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالم I should be TRIMMED",
                                                                               "One eng - remaining arabic" : "jعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمالعالمال"])
        
    }
    
    @IBAction func appInboxTapped() {
        let style = CleverTapInboxStyleConfig.init()
        style.title = "AppInbox"
        style.backgroundColor = UIColor.yellow
        style.messageTags = ["Promotions", "Offers", ""];
        
        if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: nil) {
            let navigationController = UINavigationController.init(rootViewController: inboxController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

