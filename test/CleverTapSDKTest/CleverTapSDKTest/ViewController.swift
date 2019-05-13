import UIKit
import CoreLocation
import CleverTapSDK
import WebKit

class ViewController: UIViewController, CleverTapInboxViewControllerDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    @IBOutlet var testButton: UIButton!
    @IBOutlet var inboxButton: UIButton!
    var webView: WKWebView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        CleverTap.sharedInstance(withCleverTapID: "i1010")
//        CleverTap.sharedInstance()?.recordEvent("Aditi new instance")
        CleverTap.sharedInstance()?.recordEvent("Alert")
        CleverTap.setDebugLevel(3)
        inboxRegister()
        addWebview()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Handle Webview

    func addWebview() {
        let config = WKWebViewConfiguration()
        let ctInterface: CleverTapJSInterface = CleverTapJSInterface(config: nil)
        let userContentController = WKUserContentController()
        userContentController.add(ctInterface, name: "clevertap")
        userContentController.add(self, name: "appDefault")
        config.userContentController = userContentController
        let customFrame =  CGRect(x: 20, y: 220, width: self.view.frame.width - 40, height: 400)
        self.webView = WKWebView (frame: customFrame , configuration: config)
        self.webView.layer.cornerRadius = 3.0
        self.webView.layer.masksToBounds = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        webView.navigationDelegate = self
        self.webView.loadHTMLString(self.htmlStringFromFile(with: "sampleHTMLCode"), baseURL: nil)

    }
    
    private func htmlStringFromFile(with name: String) -> String {
        let path = Bundle.main.path(forResource: name, ofType: "html")
        if let result = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8) {
            return result
        }
        return ""
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        print("I'm inside the main application: %@", body)
    }
    
    // MARK: - Register Inbox
    
    func inboxRegister() {
//        CleverTap.sharedInstance()?.registerInboxUpdatedBlock(({
//            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
//            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
//            
//            DispatchQueue.main.async {
//                self.inboxButton.isHidden = false;
//                self.inboxButton.setTitle("Show Inbox:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread", for: .normal)
//            }
//        }))
//        
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            self.inboxButton.isHidden = false;
            self.inboxButton.setTitle("Show Inbox:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread", for: .normal)
        }))
    }
    
    // MARK: - Action Button
    
    @IBAction func inboxButtonTapped(_ sender: Any) {
        let style = CleverTapInboxStyleConfig.init()
        style.title = "AppInbox"
        style.messageTags = ["Promotions", "Offers"];
        style.backgroundColor = UIColor.brown
        style.navigationBarTintColor = UIColor.gray
        style.tabSelectedTextColor = UIColor.green
        style.tabSelectedBgColor = UIColor.white
        style.tabUnSelectedTextColor = UIColor.red
        
        if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self) {
            let navigationController = UINavigationController.init(rootViewController: inboxController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    @IBAction func testButtonTapped(_ sender: Any) {
        NSLog("test button tapped")
//        CleverTap.sharedInstance()?.recordScreenView("recordScreen")
//        CleverTap.sharedInstance()?.recordEvent("test ios")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Cover")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Header")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Video")
//        CleverTap.sharedInstance()?.recordEvent("Footer")
//        CleverTap.sharedInstance()?.recordEvent("Cover Image")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
        CleverTap.sharedInstance()?.recordEvent("Footer")
//        CleverTap.sharedInstance()?.recordEvent("Header")
//        CleverTap.sharedInstance()?.recordEvent("Cover Image")
//        CleverTap.sharedInstance()?.recordEvent("Tablet only Header")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Gif")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial ios")
//        CleverTap.sharedInstance()?.recordEvent("Charged")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial video")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Image")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial Image")
//        CleverTap.sharedInstance()?.recordEvent("in-app")
//        CleverTap.sharedInstance()?.onUserLogin(["foo2":"bar2", "Email":"aditiagrawal@clevertap.com", "identity":"35353533535"])
//        CleverTap.sharedInstance()?.onUserLogin(["foo2":"bar2", "Email":"agrawaladiti@clevertap.com", "identity":"111111111"], withCleverTapID: "22222222222")

    }
    
    func messageDidSelect(_ message: CleverTapInboxMessage, at index: Int32, withButtonIndex buttonIndex: Int32) {
        
    }
}

