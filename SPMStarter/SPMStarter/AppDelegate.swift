//
//  AppDelegate.swift
//  SPMStarter
//
//  Created by Aditi Agrawal on 04/11/20.
//

import UIKit
import CleverTapSDK
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // register for push notifications
        registerForPush()
        // Configure and init the default shared CleverTap instance (add CleverTap Account ID and Account Token in your .plist file)
        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue + 3)
        CleverTap.autoIntegrate()
        return true
    }
    
    
    // MARK: - Setup Push Notifications
    
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
