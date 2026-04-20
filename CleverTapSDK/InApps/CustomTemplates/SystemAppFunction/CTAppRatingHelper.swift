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
    @objc class public func requestRating(completion: @escaping (Bool) -> Void) {
#if os(tvOS)
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "App rating is not supported on tvOS.")
        completion(false)
#else
        CTAppRatingHelper.runSyncMainQueue {
            var presented: Bool = false
            if #available(iOS 14.0, *) {
                guard let sharedApplication = CTAppRatingHelper.getSharedApplication(),
                      let activeScene: UIScene = sharedApplication.connectedScenes.first(where: { $0.activationState == .foregroundActive }),
                      let windowScene = activeScene as? UIWindowScene else {
                    CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Cannot request for App rating prompt as there is no active scene present.")
                    completion(presented)
                    return
                }

                presented = true
                if #available(iOS 18.0, *) {
                    AppStore.requestReview(in: windowScene)
                } else {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "App rating request successful.")
            } else if #available(iOS 10.3, *) {
                presented = true
                SKStoreReviewController.requestReview()
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "App rating request successful.")
            } else {
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Cannot request for App rating prompt for iOS version 10.2 and below.")
            }
            completion(presented)
        }
#endif
    }
    
    class private func getSharedApplication() -> UIApplication? {
        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: sharedSelector),
                let shared = UIApplication.perform(sharedSelector),
                let application = shared.takeUnretainedValue() as? UIApplication else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Failed to get shared application.")
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
