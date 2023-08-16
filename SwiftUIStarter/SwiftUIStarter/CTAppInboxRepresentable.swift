import SwiftUI
import CleverTapSDK

struct CTAppInboxRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CleverTapInboxViewController {
        let style = CleverTapInboxStyleConfig()
        style.title = "App Inbox"
        style.navigationTintColor = .black
        style.messageTags = ["tag1", "tag2"]
        let inboxVC: CleverTapInboxViewController = (CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: context.coordinator))!
        return inboxVC
    }
    
    func updateUIViewController(_ uiViewController: CleverTapInboxViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
    
    func makeCoordinator() -> CTCallbackCoordinator {
        CTCallbackCoordinator()
    }
}
