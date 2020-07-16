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
        CleverTap.sharedInstance()?.setLocationForGeofences(coords)
    }
    
    @IBAction func recordGeofenceEntered(_ sender: Any) {
        let geofenceDetails: NSMutableDictionary = NSMutableDictionary()
        geofenceDetails["gcId"] = "2"
        geofenceDetails["gcName"] = "iOS Test"
        geofenceDetails["id"] = "303"
        geofenceDetails["lat"] = "17.3449698328624";
        geofenceDetails["lng"] = "77.1718097084959";
        geofenceDetails["lng"] = "77.1718097084959";
        geofenceDetails["r"] = "500";
        CleverTap.sharedInstance()?.recordGeofenceEnteredEvent(geofenceDetails as! [AnyHashable : Any])
    }
    
    @IBAction func recordGeofenceExited(_ sender: Any) {
        let geofenceDetails: NSMutableDictionary = NSMutableDictionary()
        geofenceDetails["gcId"] = "2"
        geofenceDetails["gcName"] = "iOS Test"
        geofenceDetails["id"] = "303"
        geofenceDetails["lat"] = "17.3449698328624";
        geofenceDetails["lng"] = "77.1718097084959";
        geofenceDetails["lng"] = "77.1718097084959";
        geofenceDetails["r"] = "500";
        CleverTap.sharedInstance()?.recordGeofenceExitedEvent(geofenceDetails as! [AnyHashable : Any])
    }
}
