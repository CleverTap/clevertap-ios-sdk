import CTNotificationService
import CleverTapSDK

class NotificationService: CTNotificationServiceExtension {
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        CleverTap.setDebugLevel(2)
        // While running the Application add CleverTap Account ID and Account token in your .plist file
        CleverTap.sharedInstance()?.recordEvent("testEventFromNotificationService")
        let profile: Dictionary<String, AnyObject> = [
            "Identity": 63344 as AnyObject,
            "Email": "test63344@gmail.com" as AnyObject]
        CleverTap.sharedInstance()?.profilePush(profile)
        // call to record the Notification viewed
        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: request.content.userInfo)
        super.didReceive(request, withContentHandler: contentHandler)
    }
}
