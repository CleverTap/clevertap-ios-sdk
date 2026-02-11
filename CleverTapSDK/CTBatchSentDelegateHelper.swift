//
//  CTBatchSentDelegateHelper.swift
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 1.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

import Foundation

@objc(CTBatchSentDelegateHelper)
@objcMembers
public class CTBatchSentDelegateHelper: NSObject {

    @objc
    public static func isBatchWithAppLaunched(_ batchWithHeader: [[String: Any]]) -> Bool {
        // Find the event with evtName == "App Launched"
        for event in batchWithHeader {
            if let eventName = event["evtName"] as? String,
               eventName == "App Launched" {
                return true
            }
        }
        return false
    }
}
