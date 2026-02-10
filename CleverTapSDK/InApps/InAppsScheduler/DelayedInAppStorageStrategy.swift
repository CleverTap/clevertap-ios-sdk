//
//  DelayedInAppStorageStrategy.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 25/01/26.
//

import Foundation

/// Storage strategy for delayed in-apps (requires database persistence)
@objc
@objcMembers
public class DelayedInAppStorageStrategy: NSObject, InAppSchedulingStrategy {
    public var delayedLegacyInAppStore: CTInAppStore?
    
    @objc public init(delayedLegacyInAppStore: CTInAppStore? = nil) {
        self.delayedLegacyInAppStore = delayedLegacyInAppStore
        super.init()
    }
    
    public func prepareForScheduling(inApps: [[String : Any]]) -> Bool {
        guard let store = delayedLegacyInAppStore else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "DelayedLegacyInAppStore is null, cannot prepare")
            return false
        }
        return store.storeDelayed(inApps: inApps)
    }
    
    public func retrieveAfterTimer(id: String) -> [String : Any]? {
        guard let store = delayedLegacyInAppStore else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "DelayedLegacyInAppStore is null, cannot retrieve")
            return nil
        }
        let inApp = store.dequeueDelayedInApp(withCampaignId: id)
        return (inApp as? [String : Any]?) ?? nil
    }

    public func clearAll() {
        delayedLegacyInAppStore?.clearDelayedInApps()
    }
}
