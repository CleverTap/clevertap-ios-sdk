import UIKit
import Foundation
import CleverTapSDK

class TestLoginVC: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var identityField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnLoginTapped() {
        
        guard let name = nameField.text as String?, !(nameField.text?.isEmpty)! else {
            
            let alertController = UIAlertController(title: "", message:
                "Psst! name can't be blank.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
            return }
        
        guard let email = emailField.text as String?, !(emailField.text?.isEmpty)! else {
            
            let alertController = UIAlertController(title: "", message:
                "Psst! email can't be blank.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
            return }
        
        guard let identity = identityField.text as String?, !(identityField.text?.isEmpty)! else {
            
            let alertController = UIAlertController(title: "", message:
                "Psst! identity can't be blank.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style:  UIAlertAction.Style.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
            return }
        
        let profile: Dictionary<String, AnyObject> = [
            "Name": name as AnyObject,                 // String
            "Email": email as AnyObject,
            "Identity": identity as AnyObject,// Email address of the user
            // optional fields. controls whether the user will be sent email, push etc.
            //            "MSG-email": false as AnyObject,                     // Disable email notifications
            //            "MSG-push": true as AnyObject,                       // Enable push notifications
            //            "MSG-sms": false as AnyObject                        // Disable SMS notifications
        ]
        
//        CleverTap.sharedInstance()?.onUserLogin(profile)
        CleverTap.sharedInstance()?.onUserLogin(profile, withCleverTapID: "CUSTOM-CLEVERTAP-ID-4")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
