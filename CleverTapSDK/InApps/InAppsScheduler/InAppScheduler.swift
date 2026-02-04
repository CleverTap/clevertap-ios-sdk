//
//  InAppScheduler.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 22/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation


/// Unified scheduler that combines timer management with storage strategy
/// Can be used for both delayed and in-action features
@objc @objcMembers public class CTInAppScheduler: NSObject {
    
    // MARK: - Properties
    
    private let timerManager: InAppTimerManager
    private let storageStrategy: InAppSchedulingStrategy?
    private let dataExtractor: InAppDataExtractor?
    private let queue = DispatchQueue(label: "com.clevertap.CTInAppScheduler", attributes: .concurrent)
    
    private var tag: String {
        return "[CleverTap]: [CTInAppScheduler]:"
    }
    
    // MARK: - Initialization
    @objc public init(timerManager: InAppTimerManager, storageStrategy: InAppSchedulingStrategy?, dataExtractor: InAppDataExtractor?) {
        self.timerManager = timerManager
        self.storageStrategy = storageStrategy
        self.dataExtractor = dataExtractor
    }
    
    // MARK: - Public Methods
    
    /// Schedule multiple in-apps with appropriate storage strategy
    @objc public func schedule(inApps: [[String: Any]], onComplete: @escaping (Any?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            // Step 1: Filter already scheduled in-apps
            var newInApps: [[String: Any]] = []
            for inApp in inApps {
                let inAppId = "\(inApp[InAppDelayConstants.INAPP_ID_IN_PAYLOAD] ?? "")"
                guard !inAppId.isEmpty else { continue }
                
                let isScheduled = self.timerManager.isTimerScheduled(id: inAppId)
                if !isScheduled {
                    newInApps.append(inApp)
                }
            }
            // Step 2: Prepare/store data using strategy
            let prepared = self.storageStrategy?.prepareForScheduling(inApps: newInApps)
            if !(prepared ?? false) {
                print("\(self.tag) Failed to prepare in-apps for scheduling")
                for inApp in newInApps {
                    guard let id = inApp[InAppDelayConstants.INAPP_ID_IN_PAYLOAD] as? String else { continue }
                    let result = self.dataExtractor?.createErrorResult(id: id, message: "Preparation failed")
                    onComplete(result)
                }
                return
            }
            // Step 3: Schedule timers for each in-app
            for inApp in newInApps {
                let inAppId = "\(inApp[InAppDelayConstants.INAPP_ID_IN_PAYLOAD] ?? "")"
                guard !inAppId.isEmpty else { continue }
                let delay = self.dataExtractor?.extractDelay(inApp: inApp) ?? 0
                
                if delay > 0 {
                    self.scheduleWithTimer(id: inAppId, delay: delay, onComplete: onComplete)
                }
            }
        }
    }
    
    /// Get active count
    func getActiveCount(completion: @escaping (Int) -> Void) {
        queue.async { [weak self] in
            guard let self = self else {
                completion(0)
                return
            }
            let count = self.timerManager.getActiveTimerCount()
            completion(count)
        }
    }
    
    /// Cancel all scheduling
    func cancelAllScheduling(completion: (() -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            self.timerManager.cleanup()
            self.storageStrategy?.clearAll()
            completion?()
        }
    }
    
    // MARK: - Private Methods
    /// Schedule a single in-app with timer
    private func scheduleWithTimer(id: String, delay: TimeInterval, onComplete: @escaping (Any) -> Void ) {
        timerManager.scheduleTimer(id: id, delay: delay) { [weak self] timerResult in
            guard let self = self else { return }
            switch timerResult.type {
            case .completed:
                // Timer completed, retrieve and process
                let result: Any
                guard let resultId = timerResult.resultId else {
                    result = self.dataExtractor?.createErrorResult(id: id, message: "Data not found")
                    onComplete(result)
                    return
                }
                let data = self.storageStrategy?.retrieveAfterTimer(id: resultId)
                
                if let data = data {
                    result = self.dataExtractor?.createSuccessResult(id: resultId, data: data)
                } else {
                    result = self.dataExtractor?.createErrorResult(id: resultId, message: "Data not found")
                }
                onComplete(result)
                
            case .error:
                let resultId = timerResult.resultId
                let exception = timerResult.exception
                let result = self.dataExtractor?.createErrorResult(
                    id: id,
                    message: exception?.localizedDescription ?? ""
                )
                onComplete(result)
                self.storageStrategy?.retrieveAfterTimer(id: resultId ?? "")
                
            case .discarded:
                let resultId = timerResult.resultId
                let result = self.dataExtractor?.createDiscardedResult(id: id)
                onComplete(result)
                self.storageStrategy?.retrieveAfterTimer(id: resultId ?? "")
                print("\(self.tag) Timer discarded, cleaned up: \(id)")
                
            @unknown default:
                print("\(self.tag) Unknown timer result type for id: \(id)")
                break
            }
        }
    }
}
