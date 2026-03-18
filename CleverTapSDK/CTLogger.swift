//
//  CTLogger.swift
//  CleverTapSDK
//
//  Created by Akash Malhotra on 20/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation
import os.log

@objc public enum CTLogType: Int32 {
    case info = 0
    case debug = 1
}

@objc(CTLogger)
@objcMembers
public class CTLogger: NSObject {
    
    private static var debugLevel: Int32 = 0
    
    private static let osLog = OSLog(subsystem: "com.clevertap.sdk", category: "CleverTap")
    
    public static func setDebugLevel(_ level: Int32) {
        debugLevel = level
    }
    
    public static func getDebugLevel() -> Int32 {
        return debugLevel
    }
    
    public static func logWithLevel(_ level: Int32, type: Int32, message: String) {
        guard let logType = CTLogType(rawValue: type) else { return }
        
        switch logType {
        case .info: guard level >= 0 else { return }
        case .debug: guard level > 0 else { return }
        }
        
        let fullMessage = "[CleverTap]: \(message)"
        
        switch logType {
        case .info:
            os_log("%{public}@", log: osLog, type: .info, fullMessage)
        case .debug:
            os_log("%{public}@", log: osLog, type: .debug, fullMessage)
        }
    }
    
    public static func logInternalError(_ exception: NSException) {
        let message = "\(self): Caught exception: \(exception)\n\(exception.callStackSymbols)"
        logWithLevel(debugLevel, type: CTLogType.debug.rawValue, message: message)
    }
}
