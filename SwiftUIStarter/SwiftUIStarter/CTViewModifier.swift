#if canImport(SwiftUI)
import SwiftUI
import CleverTapSDK

@available(iOS 13, *)
internal struct CTViewModifier: ViewModifier {
    @State private var viewDidLoad = false
    let screenName: String

    func body(content: Content) -> some View {
        content.onAppear {
            if viewDidLoad == false {
                // `viewDidLoad` eqivalent in SwiftUI
                viewDidLoad = true
                if (screenName == "Home Screen") {
                    self.registerAppInbox()
                    self.initializeAppInbox()
                }
                // Record any CleverTap events here.
                CleverTap.sharedInstance()?.recordEvent(screenName)
            }
        }
    }
    
    func registerAppInbox() {
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock({
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        })
    }

    func initializeAppInbox() {
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        }))
    }
}

@available(iOS 13, *)
public extension View {
    func recordScreenView(screenName: String) -> some View {
        self.modifier(CTViewModifier(screenName: screenName))
    }
}
#endif
