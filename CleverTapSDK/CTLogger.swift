//
//  CTLogger.swift
//  CleverTapSDK
//
//  Created by Akash Malhotra on 20/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation
import os.log

@objc(CTLogger)
@objcMembers
public class CTLogger: NSObject {
    
    private static var debugLevel: Int32 = 0
    
    @available(iOS 10.0, tvOS 10.0, *)
    private static let osLog = OSLog(subsystem: "com.clevertap.sdk", category: "CleverTap")
    
    public static func setDebugLevel(_ level: Int32) {
        debugLevel = level
    }
    
    public static func getDebugLevel() -> Int32 {
        return debugLevel
    }
    
    public static func logWithLevel(_ level: Int32, type: Int32, message: String) {
        switch type {
        case 0: guard level >= 0 else { return }
        case 1: guard level > 0 else { return }
        case 2: break
        default: break
        }
        
        let fullMessage = "[CleverTap]: \(message)"
        
        if #available(iOS 12.0, tvOS 12.0, *) {
            switch type {
            case 0: os_log(.info, log: osLog, "%{public}@", fullMessage)
            case 1: os_log(.debug, log: osLog, "%{public}@", fullMessage)
            case 2: os_log(.error, log: osLog, "%{public}@", fullMessage)
            default: os_log(.default, log: osLog, "%{public}@", fullMessage)
            }
        } else {
            NSLog("%@", fullMessage)
        }
    }
    
    public static func logInternalError(_ exception: NSException) {
        let message = "\(self): Caught exception: \(exception)\n\(exception.callStackSymbols)"
        logWithLevel(debugLevel, type: 2, message: message)
    }
}
