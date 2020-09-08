import UIKit
import CleverTapSDK

class ProfileVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func profilePush(_ sender: Any) {
        let profile: Dictionary<String, AnyObject> = [
            "Name": "Cosby" as AnyObject,
            "Identity": "cosby" as AnyObject,
            "Email": "cosby@gmail.com" as AnyObject,
            "Phone": "+14155551234" as AnyObject,
            "Gender": "M" as AnyObject,
            "Employed": "Y" as AnyObject,
            "Education": "Graduate" as AnyObject,
            "Married": "Y" as AnyObject,
            "DOB": "09/09" as AnyObject,
            "Age": 26 as AnyObject,
            "Tz":"Asia/Kolkata" as AnyObject,
            "Photo": "www.foobar.com/image.jpeg" as AnyObject,
            "MSG-email": false as AnyObject,
            "MSG-push": true as AnyObject,
            "MSG-sms": false as AnyObject
        ]
        
        CleverTap.sharedInstance()?.profilePush(profile)
    }
    @IBAction func onUserLogin(_ sender: Any) {
        
    }
    
    @IBAction func setUserProperty(_ sender: Any) {
        CleverTap.sharedInstance()?.profileSetMultiValues(["bag", "shoes"], forKey: "myStuff")
    }
    
    @IBAction func addUserProperty(_ sender: Any) {
        CleverTap.sharedInstance()?.profileAddMultiValue("coat", forKey: "myStuff")
        CleverTap.sharedInstance()?.profileAddMultiValues(["socks", "scarf"], forKey: "myStuff")
        CleverTap.sharedInstance()?.profileAddMultiValue("Jayhawks", forKey: "Music")
        CleverTap.sharedInstance()?.profileAddMultiValues(["Iron&Wine", "Beatles"], forKey: "Rock")
    }
    
    @IBAction func removeUserProperty(_ sender: Any) {
        CleverTap.sharedInstance()?.profileRemoveMultiValue("bag", forKey: "myStuff")
        CleverTap.sharedInstance()?.profileRemoveMultiValues(["shoes", "coat"], forKey: "myStuff")
        CleverTap.sharedInstance()?.profileRemoveValue(forKey: "myStuff")
    }
}
