//
//  NotificationViewController.swift
//  NotificationContent
//
//  Created by Yogesh Singh on 03/06/20.
//  Copyright © 2020 CleverTap. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import CleverTapSDK

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    // This will be called to send the notification to be displayed by
    // the extension. If the extension is being displayed and more related
    // notifications arrive (eg. more messages for the same conversation)
    // the same method will be called for each new notification.
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body
    }

    // If implemented, the method will be called when the user taps on one
    // of the notification actions. The completion handler can be called
    // after handling the action to dismiss the notification and forward the
    // action to the app if necessary.
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        
        CleverTap.sharedInstance()?.recordClickedNotificationEvent(withData: response.notification.request.content.userInfo)
    }
}
