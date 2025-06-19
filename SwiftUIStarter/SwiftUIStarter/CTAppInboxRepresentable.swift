import SwiftUI
import CleverTapSDK

struct CTAppInboxRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CleverTapInboxViewController {
        let style = CleverTapInboxStyleConfig()
        style.title = "App Inbox"
        style.navigationTintColor = .black
        let inboxVC: CleverTapInboxViewController = (CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: nil)!)!
        return inboxVC
    }
    
    func updateUIViewController(_ uiViewController: CleverTapInboxViewController, context: Context) { }
}
