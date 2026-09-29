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

/// Strategy for delayed in-app evaluation and scheduling.
@objc
@objcMembers
public class DelayedInAppSelectionStrategy: NSObject, InAppSelectionStrategy {
    
    @objc public static let shared = DelayedInAppSelectionStrategy()
    
    private override init() {
        super.init()
    }
    
    public func shouldUpdateTTL() -> Bool {
        return false
    }
    
    public func selectInApps(_ sortedInApps: [NSDictionary], suppressionHandler: @escaping SuppressionHandler) -> [NSDictionary] {
        var delayedInApps: [Int: [NSDictionary]] = [:]
        for inApp in sortedInApps {
            guard let inAppId = inApp[InAppDelayConstants.INAPP_ID_IN_PAYLOAD], !"\(inAppId)".isEmpty else {
                continue
            }
            let delay = (inApp[InAppDelayConstants.INAPP_DELAY_AFTER_TRIGGER] as? NSNumber)?.intValue ?? 0
            delayedInApps[delay, default: []].append(inApp)
        }
        var selectedInApps: [NSDictionary] = []
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Processing \(delayedInApps.count) delayed in-apps")
        // For each delay group, select first non-suppressed in-app
        for (delay, inAppsWithSameDelay) in delayedInApps {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Processing \(inAppsWithSameDelay.count) in-apps with delay: \(delay)s")
            // Find first non-suppressed in-app. suppressionHandler records the
            // suppression as a side effect, so invoke it exactly once per in-app.
            let selectedInApp = inAppsWithSameDelay.first { inApp in
                let isSuppressed = suppressionHandler(inApp)
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Delayed inApp suppressed: \(isSuppressed)")
                return !isSuppressed
            }
            if let inApp = selectedInApp {
                selectedInApps.append(inApp)
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Selected in-app for delay \(delay)s: \(inApp[InAppDelayConstants.INAPP_ID_IN_PAYLOAD] ?? "")")
            }
        }
        return selectedInApps
    }
}

