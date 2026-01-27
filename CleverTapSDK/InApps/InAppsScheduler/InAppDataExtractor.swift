//
//  InAppDataExtractor.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 22/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation

// MARK: - InAppDataExtractor Protocol

/// Protocol for extracting type-specific data from in-apps
@objc public protocol InAppDataExtractor {
    func extractDelay(inApp: [String: Any]) -> TimeInterval
    func createSuccessResult(id: String, data: [String: Any]) -> Any
    func createErrorResult(id: String, message: String) -> Any
    func createDiscardedResult(id: String) -> Any
}

// MARK: - DelayedInAppDataExtractor

/// Data extractor for delayed in-apps
@objc public class DelayedInAppDataExtractor: NSObject, InAppDataExtractor {
    
    @objc public func extractDelay(inApp: [String: Any]) -> TimeInterval {
        // Extract delay from in-app dictionary
        // Assuming delay is stored in milliseconds, convert to seconds
        if let delayMs = inApp["delayAfterTrigger"] as? Int {
            return TimeInterval(delayMs)
        }
        if let delayMs = inApp["delayAfterTrigger"] as? Double {
            return TimeInterval(delayMs)
        }
        return 0
    }
    
    @objc public func createSuccessResult(id: String, data: [String: Any]) -> Any {
        return CTDelayedInAppResult.success(withId: id, data: data)
    }
    
    @objc public func createErrorResult(id: String, message: String) -> Any {
        let error = NSError(
            domain: "DelayedInAppError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        return CTDelayedInAppResult.error(withId: id, reason: .unknown, exception: error)
    }
    
    @objc public func createDiscardedResult(id: String) -> Any {
        return CTDelayedInAppResult.discarded(withId: id, message: "Timer expired while app was backgrounded")
    }
}

// MARK: - InActionDataExtractor

/// Data extractor for in-action in-apps
@objc public class InActionDataExtractor: NSObject, InAppDataExtractor {
    
    @objc public func extractDelay(inApp: [String: Any]) -> TimeInterval {
        // Extract in-action delay from in-app dictionary
        // Assuming delay is stored in milliseconds, convert to seconds
        if let delayMs = inApp["inactionDuration"] as? Int {
            return TimeInterval(delayMs)
        }
        if let delayMs = inApp["inactionDuration"] as? Double {
            return TimeInterval(delayMs)
        }
        return 0
    }
    
    @objc public func createSuccessResult(id: String, data: [String: Any]) -> Any {
        return CTInActionResult.readyToFetch(withId: id, data: data)
    }
    
    @objc public func createErrorResult(id: String, message: String) -> Any {
        return CTInActionResult.error(withId: id, message: message)
    }
    
    @objc public func createDiscardedResult(id: String) -> Any {
        return CTInActionResult.discarded(withId: id, message: "Timer expired while app was backgrounded")
    }
    
    @objc public func createCancelledResult(id: String) -> Any {
        return CTInActionResult.discarded(withId: id, message: "Timer expired while app was backgrounded")
    }
}
