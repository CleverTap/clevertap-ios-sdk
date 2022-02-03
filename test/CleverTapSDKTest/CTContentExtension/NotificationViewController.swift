//
//  NotificationViewController.swift
//  CTContentExtension
//
//  Created by Sonal Kachare on 22/10/21.
//  Copyright © 2021 Peter Wilkniss. All rights reserved.
//

import UIKit
//import CleverTapSDK
//import CTNotificationContent

class NotificationViewController: UIViewController {

//class NotificationViewController: CTNotificationViewController {
    
    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
//        self.contentType = .contentSlider // default is .contentSlider, just here for illustration
        super.viewDidLoad()
        //        self.contentType = CTNotificationContentType.contentSlider
        // Do any required interface initialization here.
    }
    
    //    func didReceive(_ notification: UNNotification) {
    //        super.didre
    //        print("enetered didreceive :::::  \(notification.request.content.attachments.first)")
    //        self.label?.text = "Sonal \(notification.request.content.body)"
    //    }
    
    // optional: implement to get user event data
//    override func userDidPerformAction(_ action: String, withProperties properties: [AnyHashable : Any]!) {
//        print("userDidPerformAction \(action) with props \(String(describing: properties))")
//    }
//
//    // optional: implement to get notification response
//    override func userDidReceive(_ response: UNNotificationResponse?) {
//        print("Push Notification Payload \(String(describing: response?.notification.request.content.userInfo))")
//        let notificationPayload = response?.notification.request.content.userInfo
//        if (response?.actionIdentifier == "action_2") {
////            CleverTap.sharedInstance()?.recordNotificationClickedEvent(withData: notificationPayload ?? "")
//        }
//    }
}
