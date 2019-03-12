import UIKit
import CoreLocation
import CleverTapSDK
import WebKit

class ViewController: UIViewController, CleverTapInboxViewControllerDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    @IBOutlet var testButton: UIButton!
    @IBOutlet var inboxButton: UIButton!
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inboxRegister()
//        addWebview()
    }
    
    func addWebview() {
        
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "clevertap")
        let scriptSource = "window.webkit.messageHandlers.clevertap1.postMessage(`Hello, world!`);"
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)
        config.userContentController = userContentController
        
        let customFrame =  CGRect(x: 40, y: 70, width: self.view.frame.width, height: 400)
        self.webView = WKWebView (frame: customFrame , configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        webView.navigationDelegate = self
        let myURL = URL(string: "https://www.apple.com")
        let myRequest = URLRequest(url: myURL!)
//        webView.load(myRequest)
        
        self.webView.loadHTMLString(self.htmlStringFromFile(with: "sampleHTMLCode"), baseURL: nil)

    }
    
    private func htmlStringFromFile(with name: String) -> String {
        let path = Bundle.main.path(forResource: name, ofType: "html")
        if let result = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8) {
            return result
        }
        return ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    @IBAction func inboxButtonTapped(_ sender: Any) {
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
         CleverTap.sharedInstance()?.registerInboxUpdatedBlock(({
                let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
                let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
                
                DispatchQueue.main.async {
                    self.inboxButton.isHidden = false;
                    self.inboxButton.setTitle("Show Inbox:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread", for: .normal)
                }
         }))
        
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            self.inboxButton.isHidden = false;
            self.inboxButton.setTitle("Show Inbox:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread", for: .normal)
        }))
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        guard let body = message.body as? [String: Any] else { return }
//        guard let command = body["action"] as? String else { return }
//        guard let name = body["event"] as? String else { return }
//
//        if command == "recordEvent" {
//            guard let value = body["value"] as? String else { return }
//        }
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
        CleverTap.sharedInstance()?.recordEvent("Cover Image")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Footer")
//        CleverTap.sharedInstance()?.recordEvent("Header")
//        CleverTap.sharedInstance()?.recordEvent("Cover Image")
//        CleverTap.sharedInstance()?.recordEvent("Tablet only Header")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Gif")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial ios")
//        CleverTap.sharedInstance()?.recordEvent("Charged")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial video")
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

