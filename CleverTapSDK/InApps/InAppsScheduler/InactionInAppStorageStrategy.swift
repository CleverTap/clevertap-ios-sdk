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
        print("Preparing \(inApps.count) in-actions for scheduling")
        
        var swiftInApps: [[String: Any]] = []
        for i in 0..<inApps.count {
            if let dict = inApps[i] as? [String: Any] {
                swiftInApps.append(dict)
            }
        }
        var cachedCount = 0
//        cacheQueue.async(flags: .barrier) { [weak self] in
//            guard let self = self else { return }
//            
//
//        }
        
        for inApp in swiftInApps {
            let inAppId = "\(inApp["ti"] ?? "")"
            if !inAppId.isEmpty {
                self.inActionCache[inAppId] = inApp
                cachedCount += 1
                print("Cached in-action: \(inAppId)")
            }
        }
        print("Cached \(cachedCount) in-actions in memory")
        return true
    }
    
    @objc public func retrieveAfterTimer(id: String) -> [String : Any]? {
        var result: [String: Any]?
        cacheQueue.sync {
            result = inActionCache[id]
        }
        if result != nil {
            print("Retrieved in-action from cache: \(id)")
        } else {
            print("In-action not found in cache: \(id)")
        }
        
        return result as? [String : Any]
    }
    
    @objc public func clear(id: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.inActionCache.removeValue(forKey: id)
            print("Cleared in-action from cache: \(id)")
        }
    }
    
    @objc public func clearAll() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let count = self.inActionCache.count
            self.inActionCache.removeAll()
            print("Cleared all \(count) in-actions from cache")
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
