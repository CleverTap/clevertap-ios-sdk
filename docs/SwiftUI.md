## Integration in SwiftUI App
CleverTap iOS SDK can be integrated in SwiftUI sample app. 

#### AppDelegate in SwiftUI
SwiftUI provides a way to use AppDelegate within SwiftUI life cycle by using `@UIApplicationDelegateAdaptor`. Create a file e.g. `AppDelegate.swift` then create a class of AppDelegate and attach it with struct main entry point by `@UIApplicationDelegateAdaptor` property wrapper, Refer sample app for more details.

```swift
import UserNotifications
import CleverTapSDK

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        registerForPush()
        CleverTap.setDebugLevel(2)
        CleverTap.autoIntegrate()
        CleverTap.sharedInstance()?.enableDeviceNetworkInfoReporting(true)
        return true
    }
    
    func registerForPush() {
        // Register for Push notifications
        UNUserNotificationCenter.current().delegate = self
        // request Permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert], completionHandler: {granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })
    }
}
```

#### App Inbox in SwiftUI
App Inbox controller can be added using `UIViewControllerRepresentable` and its callback methods can be used using `makeCoordinator` method. Refer example app for more details.

```swift
struct CTAppInboxRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CleverTapInboxViewController {
        let style = CleverTapInboxStyleConfig()
        let inboxVC: CleverTapInboxViewController = (CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: context.coordinator))!
        return inboxVC
    }
    
    func updateUIViewController(_ uiViewController: CleverTapInboxViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
    
    func makeCoordinator() -> CTCallbackCoordinator {
        // Callback class
    }
}
```

#### Track Screen Views in SwiftUI
There is no direct replacement for `viewDidLoad()` method in SwiftUI, but we can acheive same behaviour using `onAppear` modifier. Refer example for more details:

```swift
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
                // Record any CleverTap events here.
                CleverTap.sharedInstance()?.recordEvent(screenName)
            }
        }
    }
}

@available(iOS 13, *)
public extension View {
    func recordScreenView(screenName: String) -> some View {
        self.modifier(CTViewModifier(screenName: screenName))
    }
}
#endif

```