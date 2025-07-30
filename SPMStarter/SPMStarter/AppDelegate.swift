//
//  AppDelegate.swift
//  SPMStarter
//
//  Created by Aditi Agrawal on 04/11/20.
//

import UIKit
import CleverTapSDK
import UserNotifications
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // register for push notifications
        registerForPush()
        // Configure and init the default shared CleverTap instance (add CleverTap Account ID and Account Token in your .plist file)
        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue + 3)
        CleverTap.autoIntegrate()
        checkSession()
        return true
    }
    
    func checkSession() {
        guard WCSession.isSupported() else {
            print("Session is not supported")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
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

extension AppDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        // no-op for demo purposes
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session is inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session is active")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let handled = CleverTap.sharedInstance()?.handleMessage(message, forWatch: session)
        if (!handled!) {
             //handle the message as its not a CleverTap Message
        }
    }
}
