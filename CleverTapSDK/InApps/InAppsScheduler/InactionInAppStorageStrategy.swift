//
//  InactionInAppStorageStrategy.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 27/01/26.
//

import Foundation

/// Storage strategy for delayed in-apps (requires database persistence)
@objc
@objcMembers
public class InactionInAppStorageStrategy:NSObject, InAppSchedulingStrategy {
    private var inActionCache: [String: [String: Any]] = [:]
    private let cacheQueue = DispatchQueue(label: "InActionCache", attributes: .concurrent)
    
    @objc public func prepareForScheduling(inApps: [[String : Any]]) -> Bool {
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Preparing \(inApps.count) in-actions inapps for scheduling")
        var swiftInApps: [[String: Any]] = []
        for i in 0..<inApps.count {
            swiftInApps.append(inApps[i])
        }
        var cachedCount = 0
        for inApp in swiftInApps {
            let inAppId = "\(inApp[InAppDelayConstants.INAPP_ID_IN_PAYLOAD] ?? "")"
            if !inAppId.isEmpty {
                self.inActionCache[inAppId] = inApp
                cachedCount += 1
                CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Cached in-action inapp: \(inAppId)")
            }
        }
        CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Cached \(cachedCount) in-action inapps in memory")
        return true
    }
    
    @objc public func retrieveAfterTimer(id: String) -> [String : Any]? {
        var result: [String: Any]?
        cacheQueue.sync {
            result = inActionCache[id]
        }
        if result != nil {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Retrieved in-action inapps from cache: \(id)")
        } else {
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "In-action inapps not found in cache: \(id)")
        }
        return result
    }
    
    @objc public func clearAll() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let count = self.inActionCache.count
            self.inActionCache.removeAll()
            CTLogger.logWithLevel(CTLogger.getDebugLevel(), type: CTLogType.debug.rawValue, message: "Cleared all \(count) in-action inapps from cache")
        }
    }
    
    @objc public func getCacheSize() -> Int {
        var size = 0
        cacheQueue.sync {
            size = inActionCache.count
        }
        return size
    }
}
