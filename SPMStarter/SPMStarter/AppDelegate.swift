//
//  AppDelegate.swift
//  SPMStarter
//
//  Created by Aditi Agrawal on 04/11/20.
//

import UIKit
import CleverTapSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        CleverTap.autoIntegrate()
        // other app launch functions
        CleverTap.setDebugLevel(3)
        return true
    }
}
