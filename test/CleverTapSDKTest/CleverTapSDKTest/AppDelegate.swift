import UIKit
import UserNotifications
import CleverTapSDK

@UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CleverTapInAppNotificationDelegate, CleverTapSyncDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Override point for customization after application launch.
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            // Fallback on earlier versions
        };
        
//        CleverTap.setCredentialsWithAccountID("65R-44Z-R65Z", andToken: "144-256")
//        CleverTap.setCredentialsWithAccountID("TEST-Z9R-486-4W5Z", andToken: "TEST-6b4-2c1")
        CleverTap.setCredentialsWithAccountID("ZWW-WWW-WWRZ", andToken: "000-001")
//        [CleverTap setCredentialsWithAccountID:@"ZWW-WWW-WWRZ"
//            andToken:@"000-001"];
//
//        CleverTap.setCredentialsWithAccountID("WWW-WWW-WWRZ", andToken: "000-000")
        CleverTap.setUIEditorConnectionEnabled(true)

        CleverTap.autoIntegrate()
        CleverTap.setDebugLevel(2)
        CleverTap.sharedInstance()?.setInAppNotificationDelegate(self)
        
        //CleverTap.sharedInstance(withCleverTapID: "Aditi09")
        //CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: ["Notification key":"bar2", "Email":"aditiagrawal@clevertap.com", "identity":"35353533535"])
        registerPush()
        CleverTap.sharedInstance()?.registerStringVariable(withName: "foo")
        CleverTap.sharedInstance()?.registerBoolVariable(withName: "boolVar")
        CleverTap.sharedInstance()?.registerDoubleVariable(withName: "doubleVar")
        CleverTap.sharedInstance()?.registerIntegerVariable(withName: "intVar")
        CleverTap.sharedInstance()?.registerStringVariable(withName: "stringVar")
        CleverTap.sharedInstance()?.registerArrayOfBoolVariable(withName: "arrayOfboolVar")
        CleverTap.sharedInstance()?.registerArrayOfDoubleVariable(withName: "arrayOfdoubleVar")
        CleverTap.sharedInstance()?.registerArrayOfIntegerVariable(withName: "arrayOfintVar")
        CleverTap.sharedInstance()?.registerArrayOfStringVariable(withName: "arrayOfstringVar")
        CleverTap.sharedInstance()?.registerDictionaryOfBoolVariable(withName: "dictOfboolVar")
        CleverTap.sharedInstance()?.registerDictionaryOfDoubleVariable(withName: "dictOfdoubleVar")
        CleverTap.sharedInstance()?.registerDictionaryOfIntegerVariable(withName: "dictOfintVar")
        CleverTap.sharedInstance()?.registerDictionaryOfStringVariable(withName: "dictOfstringVar")
        return true
    }

    private func registerPush() {
        // request permissions
        if #available(iOS 10.0, *) {
            if #available(iOS 12.0, *) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge, .provisional]) {
                    (granted, error) in
                    if (granted) {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func profileDidInitialize(_ CleverTapID: String!, forAccountId accountId: String!) {
        print(CleverTapID ?? "unknown")
        print(accountId ?? "unknown")
    }
    
    func shouldShowInAppNotification(withExtras extras: [AnyHashable : Any]!) -> Bool {
//        NSLog("shouldShowNotificationwithExtras called: %@", extras)
        return true;
    }
    
    func inAppNotificationDismissed(withExtras extras: [AnyHashable : Any]!, andActionExtras actionExtras: [AnyHashable : Any]!) {
//        NSLog("inAppNotificationDismissed called withExtras: %@ actionExtras: %@", extras, actionExtras)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("%@: failed to register for remote notifications: %@", self.description, error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        NSLog("%@: registered for remote notifications: %@", self.description, deviceToken.description)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("%@: did receive notification response: %@", self.description, response.notification.request.content.userInfo)
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("%@: will present notification: %@", self.description, notification.request.content.userInfo)
        completionHandler([.badge, .sound, .alert])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog("%@: did receive remote notification completionhandler: %@", self.description, userInfo)
        completionHandler(UIBackgroundFetchResult.noData)
    }
    
    private func application(application: UIApplication, openURL url: NSURL,
                     sourceApplication: String?, annotation: AnyObject) -> Bool {
        CleverTap.sharedInstance()?.handleOpen(url as URL, sourceApplication: sourceApplication)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        CleverTap.sharedInstance()?.handleOpen(url, sourceApplication: nil)
        return true
    }
    
    func open(_ url: URL, options: [String : Any] = [:],
              completionHandler completion: ((Bool) -> Swift.Void)? = nil) {
        CleverTap.sharedInstance()?.handleOpen(url, sourceApplication: nil)
        completion?(false)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }
  
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

