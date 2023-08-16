import CleverTapSDK

class CTCallbackCoordinator: NSObject, CleverTapPushPermissionDelegate, CleverTapInboxViewControllerDelegate {
    // MARK: CleverTapPushPermissionDelegate
    func onPushPermissionResponse(_ accepted: Bool) {
        print("Push Permission response called ---> accepted = \(accepted)")
    }
    
    // MARK: CleverTapInboxViewControllerDelegate
    func messageDidSelect(_ message: CleverTapInboxMessage, at index: Int32, withButtonIndex buttonIndex: Int32) {
        // This is called when an inbox message or button is clicked
        print("App Inbox tapped with button index: \(buttonIndex)")
    }
}
