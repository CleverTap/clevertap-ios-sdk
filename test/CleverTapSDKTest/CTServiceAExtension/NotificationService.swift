//
//  NotificationService.swift
//  CTServiceAExtension
//
//  Created by Sonal Kachare on 22/10/21.
//  Copyright © 2021 Peter Wilkniss. All rights reserved.
//

import UserNotifications
import CTNotificationService
import CleverTapSDK

class NotificationService: CTNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        // call to record the Notification viewed
//        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: request.content.userInfo)
        super.didReceive(request, withContentHandler: contentHandler)
        return
    }
//
//    override func serviceExtensionTimeWillExpire() {
//        // Called just before the extension will be terminated by the system.
//        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
//        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
//            contentHandler(bestAttemptContent)
//        }
//    }

}

/**self.contentHandler = contentHandler
 bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
 
 
 if let bca = self.bestAttemptContent {
     
     func save(_ identifier: String, data: Data, options: [AnyHashable: Any]?) -> UNNotificationAttachment? {
         let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
         do {
             try FileManager.default.createDirectory(at: directory,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
             let fileURL = directory.appendingPathComponent(identifier)
             try data.write(to: fileURL, options: [])
             return try UNNotificationAttachment.init(identifier: identifier,
                                                      url: fileURL,
                                                      options: options)
         } catch {}
         return nil
     }
     
     func exitGracefully(_ reason: String = "") {
         let bca = request.content.mutableCopy()
             as? UNMutableNotificationContent
         bca!.title = reason
         contentHandler(bca!)
     }
     
     DispatchQueue.main.async {
         guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
             return exitGracefully()
         }
         
         let userInfo : [AnyHashable: Any] = request.content.userInfo
         
         guard let attachmentURL = userInfo["ct_mediaUrl"] as? String else {
             return exitGracefully()
         }
         guard let imageData = try? Data(contentsOf: URL(string: attachmentURL)!) else {
             return exitGracefully()
         }
         guard let attachment = save("image.png", data: imageData, options: nil) else {
             return exitGracefully()
         }
         
         content.attachments = [attachment]
         contentHandler(content)
     }
 }
 */
