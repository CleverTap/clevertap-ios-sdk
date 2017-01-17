//
//  AppDelegate.swift
//  swiftstarter
//
//  Created by pwilkniss on 12/14/15.
//  Copyright © 2015 CleverTap. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CleverTapSyncDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var clevertap: CleverTap?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.setUpCleverTap()
        
        // Register for Push Notifications
        UNUserNotificationCenter.current().delegate = self
        // request permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) {
            (granted, error) in
            if (granted) {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        return true
    }
    
    func setUpCleverTap() {
        // configure and init CleverTap
        CleverTap.setDebugLevel(1)
        CleverTap.enablePersonalization()
        
        clevertap = CleverTap.autoIntegrate()
        
        // Register for User Profile synchronization updates
        clevertap?.setSyncDelegate(self);
        
        
        // example usage
        let lastTimeAppLaunched = clevertap?.userGetPreviousVisitTime()
        print("last App Launch", Date.init(timeIntervalSince1970: lastTimeAppLaunched!))
        
    }
    
    // CleverTap Sync Delegate
    func profileDataUpdated(_ updates: [AnyHashable: Any]!) {
        print("profile updates", updates);
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APPDELEGATE: didRegisterForRemoteNotification")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotification \(error.localizedDescription)")
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

