//
//  NotificationService.swift
//  NotificationService
//
//  Created by Aditi on 6/27/18.
//  Copyright © 2018 Aditi Agrawal. All rights reserved.
//

import CTNotificationService
import CleverTapSDK

class NotificationService: CTNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
        // While running the Application add CleverTap Account ID and Account token in your .plist file
        CleverTap.sharedInstance()?.recordEvent("testEventFromAppex")
        let profile: Dictionary<String, AnyObject> = [
            "Identity": 61026032 as AnyObject,
            "Email": "jack@gmail.com" as AnyObject]
        CleverTap.sharedInstance()?.profilePush(profile)
        // call to record the Notification viewed
        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: request.content.userInfo)
        super.didReceive(request, withContentHandler: contentHandler)
    }
}
