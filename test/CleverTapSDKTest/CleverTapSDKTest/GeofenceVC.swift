import UIKit
import CleverTapSDK

class GeofenceVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: (#selector(self.geofencesDidUpdate(notification:))), name: NSNotification.Name.CleverTapGeofencesDidUpdate, object: nil)        
    }
    
    @objc func geofencesDidUpdate(notification: Notification) {
      // Take Action on Notification
        print("Geofences:", notification.userInfo ?? "")
    }
    
    @IBAction func setLocation(_ sender: Any) {
        let coords = CLLocationCoordinate2DMake(19.100009001977014, 73.03798211097717)
        //        let coords = CLLocationCoordinate2DMake(51.5083, -0.1384)
        CleverTap.sharedInstance()?.setLocationForGeofences(coords)
    }
}
