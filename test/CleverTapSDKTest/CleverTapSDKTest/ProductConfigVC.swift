import UIKit
import CleverTapSDK

class ProductConfigVC: UIViewController, CleverTapProductConfigDelegate {
    
    @IBOutlet var lblChangeValue: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        CleverTap.sharedInstance()?.productConfig.delegate = self;
        let lastFetchTS = CleverTap.sharedInstance()?.productConfig.getLastFetchTimeStamp()
        print("Last Fetch Time Stamp:", lastFetchTS ?? "")
        CleverTap.sharedInstance()?.productConfig.setMinimumFetchInterval(100)
        
    }
    
    @IBAction func setDefaultsTapped(_ sender: Any) {
        NSLog("fetch button tapped")
        setProductConfigDefaults()
    }
    
    @IBAction func fetchTapped(_ sender: Any) {
        NSLog("fetch button tapped")
        CleverTap.sharedInstance()?.productConfig.fetch(withMinimumInterval: 0)
        //        CleverTap.sharedInstance()?.productConfig.fetch()
    }
    
    @IBAction func activateTapped(_ sender: Any) {
        NSLog("activate button tapped")
        CleverTap.sharedInstance()?.productConfig.activate()
    }
    
    @IBAction func fetchAndActivateTapped(_ sender: Any) {
        CleverTap.sharedInstance()?.productConfig.fetchAndActivate()
    }
    
    @IBAction func reset(_ sender: Any) {
        CleverTap.sharedInstance()?.productConfig.reset()
    }
    
    // MARK: - Product Config
    
    func setProductConfigDefaults() {
        let defaults = NSMutableDictionary()
        defaults.setValue("aditi", forKey: "foo")
        defaults.setValue("agrawal", forKey: "str-key-2")
        defaults.setValue(true, forKey: "bool-test")
        CleverTap.sharedInstance()?.productConfig.setDefaults(defaults as? [String : NSObject])
        //        CleverTap.sharedInstance()?.productConfig.setDefaultsFromPlistFileName("RemoteConfigDefaults")
    }
    
    func ctProductConfigInitialized() {
        
    }
    
    func ctProductConfigFetched() {
        
        //        CleverTap.sharedInstance()?.productConfig.activate() // test case 
        
        let ctValue = CleverTap.sharedInstance()?.productConfig.get("int-key")
        let strValue1 = ctValue?.numberValue
        print("Remote Config after fetch 1:", strValue1 ?? "")
        
        let ctValue2 = CleverTap.sharedInstance()?.productConfig.get("str-key")
        let strValue2 = ctValue2?.stringValue
        print("Remote Config after fetch 2:", strValue2 ?? "")
        
        let ctValue3 = CleverTap.sharedInstance()?.productConfig.get("bool-key")
        let strValue3 = ctValue3?.numberValue
        print("Remote Config after fetch 3:", strValue3 ?? "")
        
        let ctValue4 = CleverTap.sharedInstance()?.productConfig.get("str-key-2")
        let strValue4 = ctValue4?.stringValue
        print("Remote Config after fetch 4:", strValue4 ?? "")
        
        let ctValue5 = CleverTap.sharedInstance()?.productConfig.get("bool-test")
        let strValue5 = ctValue5?.boolValue
        print("Remote Config after fetch 5:", strValue5?.description ?? "")
    }
    
    func ctProductConfigActivated() {
        
        let ctValue = CleverTap.sharedInstance()?.productConfig.get("int-key")
        let strValue1 = ctValue?.numberValue
        print("Remote Config after activate 1:", strValue1 ?? "")
        
        let ctValue2 = CleverTap.sharedInstance()?.productConfig.get("test")
        let strValue2 = ctValue2?.stringValue
        print("Remote Config after activate 2:", strValue2 ?? "")
        
        self.lblChangeValue.text = strValue2

        let ctValue3 = CleverTap.sharedInstance()?.productConfig.get("bool-key")
        let strValue3 = ctValue3?.numberValue
        print("Remote Config after activate 3:", strValue3 ?? "")
        
        let ctValue4 = CleverTap.sharedInstance()?.productConfig.get("str-key-2")
        let strValue4 = ctValue4?.stringValue
        print("Remote Config after activate 4:", strValue4 ?? "")
        
        let ctValue5 = CleverTap.sharedInstance()?.productConfig.get("json-key")
        let strValue5 = ctValue5?.jsonValue
        print("Remote Config after activate 5:", strValue5.debugDescription)
        
        let ctValue6 = CleverTap.sharedInstance()?.productConfig.get("bool-test")
        let strValue6 = ctValue6?.boolValue
        print("Remote Config after fetch 5:", strValue6?.description ?? "")
    }
}
