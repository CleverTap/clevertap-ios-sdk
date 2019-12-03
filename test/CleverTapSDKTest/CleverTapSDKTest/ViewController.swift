import UIKit
import CoreLocation
import CleverTapSDK
import WebKit

class ViewController: UIViewController, CleverTapInboxViewControllerDelegate, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate, CleverTapAdUnitDelegate {
    
    @IBOutlet var testButton: UIButton!
    @IBOutlet var inboxButton: CustomButton!
    @IBOutlet var customButton: CustomButton!
    
    @IBOutlet var customView: UIView!


    var webView: WKWebView!
    var imageArray = [UIImage]()
    @IBOutlet var scrollView: UIScrollView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        CleverTap.sharedInstance()?.setAdUnitDelegate(self)
        
        self.setupImages()
        self.recordUserChargedEvent()
        CleverTap.sharedInstance()?.recordEvent("Added To Cart")

//        CleverTap.sharedInstance()?.recordEvent("Charged")
        CleverTap.sharedInstance()?.registerExperimentsUpdatedBlock {
            print("Experiments updated.")
      }
    
//        inboxRegister()
//        addWebview()
//        addAdUnit()
        
        CleverTap.sharedInstance()?.getBoolVariable(withName: "boolVar", defaultValue: true)
        CleverTap.sharedInstance()?.getDoubleVariable(withName: "doubleVar", defaultValue: 0.0)
        CleverTap.sharedInstance()?.getIntegerVariable(withName: "intVar", defaultValue: 0)
        CleverTap.sharedInstance()?.getStringVariable(withName: "stringVar", defaultValue: "defaultFooValue")

        CleverTap.sharedInstance()?.getArrayOfBoolVariable(withName: "arrayOfboolVar", defaultValue: [true, false])
        CleverTap.sharedInstance()?.getArrayOfDoubleVariable(withName: "arrayOfDoubleVar", defaultValue: [1.1, 1.2])
        CleverTap.sharedInstance()?.getArrayOfIntegerVariable(withName: "arrayOfIntegerVar", defaultValue: [1, 2])
        CleverTap.sharedInstance()?.getArrayOfStringVariable(withName: "arrayOfStringVar", defaultValue: ["foo"])
        
        CleverTap.sharedInstance()?.getDictionaryOfBoolVariable(withName: "dictOfboolVar", defaultValue: ["key1": true, "key2": false])
        CleverTap.sharedInstance()?.getDictionaryOfDoubleVariable(withName: "dictOfdoubleVar", defaultValue: ["key1": 1.1, "key2": 1.2])
        CleverTap.sharedInstance()?.getDictionaryOfIntegerVariable(withName: "dictOfintVar", defaultValue: ["key1": 1, "key2": 2])
        CleverTap.sharedInstance()?.getDictionaryOfStringVariable(withName: "dictOfstringVar", defaultValue: ["key1": "a", "key2": "b"])
        
        profilePush()
        guard let foo = CleverTap.sharedInstance()?.getStringVariable(withName: "foo", defaultValue: "defaultFooValue") else {return}
        guard let int = CleverTap.sharedInstance()?.getIntegerVariable(withName: "intFoo", defaultValue: 12) else {return}
        print(foo)
        print(int)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
//    func addAdUnit() {
//        var view: UIView = CleverTap.sharedInstance()!.adUnitView(forID: "")
////        self.view.addSubview(view)
//    }
    
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
    
    
    // MARK: - Handle Webview

    func addWebview() {
        /*
        let config = WKWebViewConfiguration()
        //let ctInterface: CleverTapJSInterface = CleverTapJSInterface(config: nil)
        let userContentController = WKUserContentController()
        userContentController.add(ctInterface, name: "clevertap1")
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
         
 */
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
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock(({
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            DispatchQueue.main.async {
                self.inboxButton.isHidden = false;
                self.inboxButton.setTitle("Show Inbox:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread", for: .normal)
            }
        }))
    }
    
    func profilePush() {
        let profile: Dictionary<String, AnyObject> = [
            "Email": "agrawaladiti@clevertap.com" as AnyObject,
            "Prefered Language": "English" as AnyObject
        ]
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    
    // MARK: - Action Button
    
    @IBAction func inboxButtonTapped(_ sender: Any) {
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            if (success) {
                let style = CleverTapInboxStyleConfig.init()
                style.title = "AppInbox"
                style.backgroundColor = UIColor.yellow
                style.messageTags = ["Promotions", "Offers"];
              
                let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
                let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
                
                DispatchQueue.main.async {
                    self.inboxButton.isHidden = false;
                    self.inboxButton.setTitle("Show Inbox:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread", for: .normal)
                }
                
                if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self) {
                    let navigationController = UINavigationController.init(rootViewController: inboxController)
//                    navigationController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                    self.present(navigationController, animated: true, completion: nil)
                }
            }
        }))
    }
    
    @IBAction func testButtonTapped(_ sender: Any) {
        NSLog("test button tapped")
//        CleverTap.sharedInstance()?.recordScreenView("recordScreen")
          CleverTap.sharedInstance()?.recordEvent("Custom-HTML ios")
          CleverTap.sharedInstance()?.recordEvent("Tablet only Cover Image")
          CleverTap.sharedInstance()?.recordEvent("Cover ios")
          CleverTap.sharedInstance()?.recordEvent("Added To Cart")

//        CleverTap.sharedInstance()?.recordEvent("in-app")
//        CleverTap.sharedInstance()?.recordEvent("test ios")
//        CleverTap.sharedInstance()?.recordEvent("Battery Alert")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Cover")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial")
//        CleverTap.sharedInstance()?.recordEvent("Header")
//        CleverTap.sharedInstance()?.recordEvent("Interstitial Video")
//        CleverTap.sharedInstance()?.recordEvent("Footer")
//        CleverTap.sharedInstance()?.recordEvent("Cover")
//        CleverTap.sharedInstance()?.recordEvent("Footer iOS")
//        CleverTap.sharedInstance()?.recordEvent("Half Interstitial")
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
    
//    func messageDidSelect(_ message: CleverTapInboxMessage, at index: Int32, withButtonIndex buttonIndex: Int32) {
//        print("message selected")
//        CleverTap.sharedInstance()?.markRead(message)
//    }

    func messageButtonTapped(withCustomExtras customExtras: [AnyHashable : Any]?) {
        print("App Inbox Button Tapped with custom extras: %@", customExtras ?? "");
    }
    
    func adUnitsUpdated(_ adUnits: [CleverTapAdUnit]) {
          let units:[CleverTapAdUnit] = adUnits;
          print("yes, I'm getting ad ids:", adUnits)
          print("yes, I'm getting ad id:", units[0].adID ?? "")
          print("yes, I'm getting ad json:", units[0].json ?? "")
          print("yes, I'm getting ad custom Extras:", units[0].customExtras ?? "")
          
          let unitsTest:[CleverTapAdUnit] = CleverTap.sharedInstance()?.getAllAdUnits() ?? [CleverTapAdUnit]()
          print("Getting all ad units", unitsTest)
          
          let unit:CleverTapAdUnit = CleverTap.sharedInstance()?.getAdUnit(forID: units[0].adID ?? "") ?? CleverTapAdUnit()
          print("Getting ad unit", unit.customExtras ?? "")
    }
    
    func adUnitIDList(_ ids: [Any]) {
        print("yes, I'm getting ad ids:", ids )
//        let customExtras: [AnyHashable : Any] = CleverTap.sharedInstance()!.getAdUnitCustomExtras(forID: ids[0] as? String ?? "") ?? ["":""]
//        let dict: NSDictionary = customExtras as NSDictionary
//        print("Hello Ad View:", dict)
        let adUnit: CleverTapAdUnit = CleverTapAdUnit()
        CleverTap.sharedInstance()?.recordAdUnitViewedEvent(forID:ids[0]  as? String ?? "")
//        CleverTap.sharedInstance()?.recordAdUnitViewedEvent(forID: adUnit.adID ?? "")
//        CleverTap.sharedInstance()?.recordAdUnitViewedEvent(forID: adUnit.adID ?? "")

    }
    
    func adUnits(_ adUnits: [CleverTapAdUnit]) {
        print("I'm getting ad units:", adUnits);
        for units in adUnits {
            let dict: NSDictionary = units.customExtras! as NSDictionary
            print("Hello Ad View:", dict)
        }
    }
        
    func setupImages(){
        
        imageArray = [UIImage(named:"meal1"), UIImage(named: "meal2")] as! [UIImage]
        
        for i in 0..<imageArray.count {
            
            let imageView = UIImageView()
            imageView.image = imageArray[i]
            let xPosition = UIScreen.main.bounds.width * CGFloat(i)
            imageView.frame = CGRect(x: xPosition, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
            imageView.contentMode = .scaleAspectFit
            
            scrollView.contentSize.width = scrollView.frame.width * CGFloat(i + 2)
            scrollView.addSubview(imageView)
            scrollView.delegate = self
            
        }
    }
}

