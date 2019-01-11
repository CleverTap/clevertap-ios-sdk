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
        let ctConfig = CleverTapInstanceConfig.init(accountId: "ZWW-WWW-WWRZ", accountToken: "000-001")
        let ct1  = CleverTap.instance(with: ctConfig)
        let style = CleverTapInboxStyleConfig.init()
        style.title = "AppInbox"
        style.cellBackgroundColor = UIColor.yellow
        style.messageTags = ["Promotions", "Offers"];
        
            if let inboxController = ct1.newInboxViewController(with: style, andDelegate: self) {
//                inboxController.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
                let navigationController = UINavigationController.init(rootViewController: inboxController)
//                navigationController.navigationBar.isTranslucent = false
                self.present(navigationController, animated: true, completion: nil)
            }
    }
    
    func inboxRegister() {
        
        let ctConfig = CleverTapInstanceConfig.init(accountId: "ZWW-WWW-WWRZ", accountToken: "000-001")
        ctConfig.logLevel = .debug
        let ct1  = CleverTap.instance(with: ctConfig)
        ct1.onUserLogin(["foo1":"bar1", "Email":"peter@clevertap.com", "identity":"89899999999999"])
        ct1.recordEvent("TestCT1WProps", withProps: ["one": NSNumber.init(integerLiteral: 1), "shouldFail":["foo":"bar"]])
        ct1.profileSetMultiValues(["a", "b", "c"], forKey:"letters")
        
        ct1.registerInboxUpdatedBlock(({
            // NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Messages Did Update: %@", ct1.profileGetID() ?? "", [ct1.getAllInboxMessages()])
            let messageCount = ct1.getInboxMessageCount()
            let unreadCount = ct1.getInboxMessageUnreadCount()
            
            DispatchQueue.main.async {
                self.inboxButton.isHidden = false;
                self.inboxButton.setTitle("Show Inbox:\(messageCount)/\(unreadCount) unread", for: .normal)
            }
     }))
        
        ct1.initializeInbox(callback: ({ (success) in
//                NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ is: %@", ct1.profileGetID() ?? ", success ? "ready" : "unavailable")
//                NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Message Count is: %@", ct1.profileGetID() ?? "", [ct1.getInboxMessageCount()])
//                NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Message Unread Count is: %@", ct1.profileGetID(), [ct1.getInboxMessageUnreadCount()])
//                NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Messages is: %@", ct1.profileGetID(), [ct1.getAllInboxMessages()])
//                NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Unread Messages is: %@", ct1.profileGetID(), [ct1.getUnreadInboxMessages()])
            //let unread = ct1.getUnreadInboxMessages();
            //NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Unread Messages is: %@", ct1.profileGetID(), [ct1.getUnreadInboxMessages()])
            
            /*
             if (unread.count > 0) {
             ct1.markRead(unread[0])
             }
             if let m = ct1.getInboxMessage(forId: "1") {
             ct1.delete(m)
             }
             
             ct1.onUserLogin(["foo2":"bar2", "Email":"peter+test2@clevertap.com", "identity":"765432"])
             ct1.initializeInbox(callback: ({ (success) in
             NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ is: %@", ct1.profileGetID(), success ? "ready" : "unavailable")
             NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Message Count is: %@", ct1.profileGetID(), [ct1.getInboxMessageCount()])
             NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Message Unread Count is: %@", ct1.profileGetID(), [ct1.getInboxMessageUnreadCount()])
             NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Messages is: %@", ct1.profileGetID(), [ct1.getAllInboxMessages()])
             NSLog("CleverTapInbox.ZWW-WWW-WWRZ.%@ Unread Messages is: %@", ct1.profileGetID(), [ct1.getUnreadInboxMessages()])
             }))
             */
            let messageCount = ct1.getInboxMessageCount()
            let unreadCount = ct1.getInboxMessageUnreadCount()
            self.inboxButton.isHidden = false;
            self.inboxButton.setTitle("Show Inbox:\(messageCount)/\(unreadCount) unread", for: .normal)
        }))
    }
 
    
    func messageDidSelect(_ message: CleverTapInboxMessage!, at index: UInt, withButtonIndex buttonIndex: UInt) {
        
    }
    
    @IBAction func testButtonTapped(_ sender: Any) {
        NSLog("test button tapped")
        CleverTap.sharedInstance()?.recordEvent("test ios")
        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
        CleverTap.sharedInstance()?.recordEvent("Cover")
    }
    
    func messageDidSelect(_ message: CleverTapInboxMessage!, at index: Int32, withButtonIndex buttonIndex: Int32) {
        
    }
    
    @objc func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

