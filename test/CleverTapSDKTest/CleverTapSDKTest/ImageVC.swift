import UIKit
import CleverTapSDK

class ImageVC: UIViewController, CleverTapAdUnitDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        CleverTap.sharedInstance()?.setAdUnitDelegate(self)
    }
    
    func adUnitsDidReceive(_ adUnits: [CleverTapAdUnit]) {
        
        print("my values:", adUnits[0].customExtras ?? "")
    }
}
