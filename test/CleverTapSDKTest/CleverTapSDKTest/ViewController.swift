import UIKit
import CoreLocation
import CleverTapSDK

class ViewController: UIViewController, CleverTapInboxViewControllerDelegate {
    
    
    @IBOutlet var testButton: UIButton!
    @IBOutlet var inboxButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("running viewDidLoad")
        inboxRegister()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //CleverTap.sharedInstance().recordScreenView("MainViewController")
        
//        if (@available(iOS 11.0, *)) {
//            UIWindow *window = UIApplication.sharedApplication.keyWindow;
//            CGFloat topPadding = window.safeAreaInsets.left;
//            CGFloat bottomPadding = window.safeAreaInsets.bottom;
//        }
    }
    
    @IBAction func inboxButtonTapped(_ sender: Any) {
        let ctConfig = CleverTapInstanceConfig.init(accountId: "W9R-486-4W5Z", accountToken: "6b4-2c0")
        let ct1  = CleverTap.instance(with: ctConfig)
        let style = CleverTapInboxStyleConfig.init()
        style.title = "AppInbox"
        style.cellBackgroundColor = UIColor.yellow
        style.messageTags = ["Promotions", "Offers"];
        
        if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self) {
            let navigationController = UINavigationController.init(rootViewController: inboxController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func inboxRegister() {
        
        let ctConfig = CleverTapInstanceConfig.init(accountId: "TEST-Z9R-486-4W5Z", accountToken: "TEST-6b4-2c1")
        ctConfig.logLevel = .debug
        ctConfig.cleverTapId = "7898732794941280-84180-48-01"
//        let ct1  = CleverTap.instance(with: ctConfig)
//        ct1.recordEvent("TestCT1WProps", withProps: ["one": NSNumber.init(integerLiteral: 1), "shouldFail":["foo":"bar"]])
//        ct1.profileSetMultiValues(["a", "b", "c"], forKey:"letters")
        
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock(({
            // NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Messages Did Update: %@", ct1.profileGetID() ?? "", [ct1.getAllInboxMessages()])
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            
            DispatchQueue.main.async {
                self.inboxButton.isHidden = false;
                self.inboxButton.setTitle("Show Inbox:\(messageCount)/\(unreadCount) unread", for: .normal)
            }
     }))
        
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
//                NSLog("CleverTapInbox.W9R-486-4W5Z.%@ is: %@", ct1.profileGetID() ?? ", success ? "ready" : "unavailable")
//                NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Message Count is: %@", ct1.profileGetID() ?? "", [ct1.getInboxMessageCount()])
//                NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Message Unread Count is: %@", ct1.profileGetID(), [ct1.getInboxMessageUnreadCount()])
//                NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Messages is: %@", ct1.profileGetID(), [ct1.getAllInboxMessages()])
//                NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Unread Messages is: %@", ct1.profileGetID(), [ct1.getUnreadInboxMessages()])
            //let unread = ct1.getUnreadInboxMessages();
            //NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Unread Messages is: %@", ct1.profileGetID(), [ct1.getUnreadInboxMessages()])
            
            /*
             if (unread.count > 0) {
             ct1.markRead(unread[0])
             }
             if let m = ct1.getInboxMessage(forId: "1") {
             ct1.delete(m)
             }
             
             ct1.onUserLogin(["foo2":"bar2", "Email":"peter+test2@clevertap.com", "identity":"765432"])
             ct1.initializeInbox(callback: ({ (success) in
             NSLog("CleverTapInbox.W9R-486-4W5Z.%@ is: %@", ct1.profileGetID(), success ? "ready" : "unavailable")
             NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Message Count is: %@", ct1.profileGetID(), [ct1.getInboxMessageCount()])
             NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Message Unread Count is: %@", ct1.profileGetID(), [ct1.getInboxMessageUnreadCount()])
             NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Messages is: %@", ct1.profileGetID(), [ct1.getAllInboxMessages()])
             NSLog("CleverTapInbox.W9R-486-4W5Z.%@ Unread Messages is: %@", ct1.profileGetID(), [ct1.getUnreadInboxMessages()])
             }))
             */
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            self.inboxButton.isHidden = false;
            self.inboxButton.setTitle("Show Inbox:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread", for: .normal)
        }))
    }
 
    
    func messageDidSelect(_ message: CleverTapInboxMessage!, at index: UInt, withButtonIndex buttonIndex: UInt) {
        
    }
    
    @IBAction func testButtonTapped(_ sender: Any) {
        NSLog("test button tapped")
//        CleverTap.sharedInstance()?.recordEvent("test ios")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Cover")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Header")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Video")
//        CleverTap.sharedInstance()?.recordEvent("Footer")
//        CleverTap.sharedInstance()?.recordEvent("Cover Image")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Footer")
//        CleverTap.sharedInstance()?.recordEvent("Header")
//        CleverTap.sharedInstance()?.recordEvent("Cover Image")
//        CleverTap.sharedInstance()?.recordEvent("Tablet only Header")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Gif")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial ios")
//        CleverTap.sharedInstance()?.recordEvent("Charged")
        CleverTap.sharedInstance()?.recordEvent("Interstitial video")

        
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Image")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial Image")
//        CleverTap.sharedInstance()?.onUserLogin(["foo2":"bar2", "Email":"aditiagrawal@clevertap.com", "identity":"35353533535"])
//        CleverTap.sharedInstance()?.onUserLogin(["foo2":"bar2", "Email":"agrawaladiti@clevertap.com", "identity":"111111111"], withCleverTapID: "22222222222")

    }
    
    func messageDidSelect(_ message: CleverTapInboxMessage!, at index: Int32, withButtonIndex buttonIndex: Int32) {
        
    }
    
    @objc func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

