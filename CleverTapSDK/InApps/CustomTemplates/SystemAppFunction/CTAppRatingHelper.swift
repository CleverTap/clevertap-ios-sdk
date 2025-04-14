//
//  CTAppRatingHelper.swift
//  CleverTapSDK
//
//  Created by Nishant Kumar on 02/04/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

@objc(CTAppRatingHelper)
public class CTAppRatingHelper : NSObject {

    @MainActor
    @objc class public func requestRating() {
        CTAppRatingHelper.runSyncMainQueue {
            if #available(iOS 14.0, *) {
                if let sharedApplication = CTAppRatingHelper.getSharedApplication() {
                    let activeScene: UIScene? = sharedApplication.connectedScenes.first(where: { $0.activationState == .foregroundActive })
                    
                    guard let windowScene = activeScene as? UIWindowScene else {
                        NSLog("[CleverTap]: Cannot request for App rating prompt as there is no active scene present.")
                        return
                    }
                    
                    if #available(iOS 18.0, *) {
                        AppStore.requestReview(in: windowScene)
                    } else {
                        SKStoreReviewController.requestReview(in: windowScene)
                    }
                    NSLog("[CleverTap]: App rating request successful.")
                }
            } else if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                NSLog("[CleverTap]: App rating request successful.")
            } else {
                NSLog("[CleverTap]: Cannot request for App rating prompt for iOS version 10.2 and below.")
            }
        }
    }
    
    class private func getSharedApplication() -> UIApplication? {
        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: sharedSelector),
                let shared = UIApplication.perform(sharedSelector),
                let application = shared.takeUnretainedValue() as? UIApplication else {
            NSLog("[CleverTap]: Failed to get shared application.")
            return nil
        }

        return application
    }
    
    @MainActor
    class private func runSyncMainQueue(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
