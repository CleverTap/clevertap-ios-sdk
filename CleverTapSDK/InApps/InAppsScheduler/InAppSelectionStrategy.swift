//
//  InAppSelectionStrategy.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 27/01/26.
//

import Foundation

// MARK: - Type Aliases

public typealias SuppressionHandler = (NSDictionary) -> Bool

// MARK: - Protocol

@objc
public protocol InAppSelectionStrategy {
    /**
     * Selects eligible in-apps based on strategy-specific logic.
     * This is the core differentiator between Immediate and Delayed strategies.
     *
     * @param sortedInApps List of in-apps already sorted by priority (highest first)
     * @param suppressionHandler Handler that checks and applies suppression, returns true if suppressed
     * @return List of selected in-apps for display/scheduling
     */
    @objc func selectInApps(_ sortedInApps: [NSDictionary], suppressionHandler: @escaping SuppressionHandler) -> [NSDictionary]
    
    /**
     * Determines whether TTL should be updated during evaluation.
     * @return true if TTL should be updated now, false if deferred to display time
     */
    @objc func shouldUpdateTTL() -> Bool
}

// MARK: - Immediate Strategy

/**
 * Strategy for immediate in-app evaluation and display.
 * - Updates TTL at evaluation time (for client-side only)
 * - Returns only the first non-suppressed in-app
 * - Used for both client-side and app launch server-side immediate in-apps
 */
@objc
@objcMembers
public class ImmediateInAppSelectionStrategy: NSObject, InAppSelectionStrategy {
    
    // Singleton instance
    @objc public static let shared = ImmediateInAppSelectionStrategy()
    
    private override init() {
        super.init()
    }
    
    public func shouldUpdateTTL() -> Bool {
        return true
    }
    
    public func selectInApps(_ sortedInApps: [NSDictionary], suppressionHandler: @escaping SuppressionHandler) -> [NSDictionary] {
        for inApp in sortedInApps {
            if !suppressionHandler(inApp) {
                return [inApp]
            }
        }
        return []
    }
}

// MARK: - Delayed Strategy

/**
 * Strategy for delayed in-app evaluation and scheduling.
 * - Defers TTL update to display time
 * - Groups in-apps by delay value
 * - Returns one in-app per delay group for concurrent scheduling
 * - Used for both client-side and app launch server-side delayed in-apps
 */
@objc
@objcMembers
public class DelayedInAppSelectionStrategy: NSObject, InAppSelectionStrategy {
    
    private static let TAG = "DelayedInAppSelectionStrategy"
    
    // Singleton instance
    @objc public static let shared = DelayedInAppSelectionStrategy()
    
    private override init() {
        super.init()
    }
    
    public func shouldUpdateTTL() -> Bool {
        return false
    }
    
    public func selectInApps(
        _ sortedInApps: [NSDictionary],
        suppressionHandler: @escaping SuppressionHandler
    ) -> [NSDictionary] {
        
        // Group by delay value
        var delayedInAppsByDelay: [Int: [NSDictionary]] = [:]
        
        for inApp in sortedInApps {
            let delay = (inApp[INAPP_DELAY_AFTER_TRIGGER] as? NSNumber)?.intValue ?? 0
            
            if delayedInAppsByDelay[delay] == nil {
                delayedInAppsByDelay[delay] = []
            }
            delayedInAppsByDelay[delay]?.append(inApp)
        }
        
        var selectedInApps: [NSDictionary] = []
        
        // For each delay group, select first non-suppressed in-app
        for (delay, inAppsWithSameDelay) in delayedInAppsByDelay {
            print( "\(DelayedInAppSelectionStrategy.TAG), message: Processing \(inAppsWithSameDelay.count) in-apps with delay: \(delay)s")

            
            // Find first non-suppressed in-app
            let selectedInApp = inAppsWithSameDelay.first { inApp in
                !suppressionHandler(inApp)
            }
            
            if let inApp = selectedInApp {
                selectedInApps.append(inApp)
                
                let inAppId = inApp[INAPP_ID_IN_PAYLOAD] as? String ?? "unknown"
                print( "\(DelayedInAppSelectionStrategy.TAG), message: Selected in-app for delay \(delay)s: \(inAppId)")
            }
        }
        
        return selectedInApps
    }
}

// MARK: - Constants (if not already defined)

let INAPP_DELAY_AFTER_TRIGGER = "delay"
let INAPP_ID_IN_PAYLOAD = "ti"

