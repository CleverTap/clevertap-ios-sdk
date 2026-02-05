//
//  InAppSchedulingStrategy.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 22/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation
import UIKit

private struct TimerData {
    let workItem: DispatchWorkItem
    let delay: TimeInterval
    let scheduledAt: TimeInterval
    let callback: (CTTimerResult) -> Void
}

/// Core timer manager that handles scheduling, lifecycle, and callback management
/// This is the reusable component for both delay and in-action features
@objc @objcMembers public class InAppTimerManager: NSObject {
    
    // MARK: - Properties
    private let tagSuffix: String
    private let queue = DispatchQueue(label: "com.clevertap.InAppTimerManager", attributes: .concurrent)
    private let workQueue = DispatchQueue(label: "com.clevertap.InAppTimerManager.work", attributes: .concurrent)
    
    private var activeJobs: [String: TimerData] = [:]
    private var cancelledJobs: [String: CancelledJobData] = [:]
    private let lock = NSRecursiveLock()
    
    private var tag: String {
        return "[InAppTimerManager:\(tagSuffix)]:"
    }
    
    // MARK: - Initialization
    
    @objc public init(tagSuffix: String = "") {
        self.tagSuffix = tagSuffix
        super.init()
        setupLifecycleObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Lifecycle Setup
    
    @objc private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
   
    @objc private func handleForeground() {
        onAppForeground()
    }
    
    @objc private func handleBackground() {
        onAppBackground()
    }

    /// Schedule a timer with callback after specified delay
    @discardableResult
    public func scheduleTimer( id: String, delay: TimeInterval, callback: @escaping (CTTimerResult) -> Void) -> DispatchWorkItem {
        lock.lock()
        defer { lock.unlock() }
        // Keep existing active job if present
        if let existingTimer = activeJobs[id], !existingTimer.workItem.isCancelled {
                CTLogger.logWithLevel(1, type: 1, message: "\(tag) Timer with id '\(id)' already scheduled, keeping existing")
                return existingTimer.workItem
            }
        let scheduledAt = Date().timeIntervalSince1970
        var workItemRef: DispatchWorkItem?
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            defer {
                self.removeActiveJob(id: id)
            }
            // Check cancellation
            guard let item = workItemRef, !item.isCancelled else {
                self.storeCancelledJob(
                    id: id,
                    delay: delay,
                    scheduledAt: scheduledAt,
                    callback: callback
                )
                CTLogger.logWithLevel(0, type: 0, message: "\(self.tag) Cancelled timer with id: \(id)")
                return  // stop execution
            }
            // Timer completed successfully
            callback(CTTimerResult.completed(withId: id, scheduledAt: scheduledAt))
            self.removeCancelledJob(id: id)
        }
        workItemRef = workItem
        // Store metadata with work item
            let timerData = TimerData(
                workItem: workItem,
                delay: delay,
                scheduledAt: scheduledAt,
                callback: callback
            )
        activeJobs[id] = timerData
        workQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
        CTLogger.logWithLevel(0, type: 0, message: "\(tag) Scheduled timer with id '\(id)' for \(delay)s delay")
        return workItem
    }
    
    @objc public func cancelTimer(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let timerData = activeJobs[id] else {
            return false
        }
        
        timerData.workItem.cancel()
        activeJobs.removeValue(forKey: id)
        CTLogger.logWithLevel(0, type: 0, message: "\(tag) Cancelled timer with id: \(id)")
        return true
    }

    /// Cancel all active timers (without storing cancelled state)
    @objc public func cancelAllTimers() {
        lock.lock()
        let cancelledCount = activeJobs.count
        let jobsToCancel = activeJobs.values.map { $0.workItem }
        activeJobs.removeAll() 
        lock.unlock()
        for workItem in jobsToCancel {
            workItem.cancel()
        }
        CTLogger.logWithLevel(0, type: 0, message: "\(tag) Cancelled \(cancelledCount) timers")
    }

    /// Check if a timer is scheduled and active
    func isTimerScheduled(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        guard let timerData = activeJobs[id] else {
            return false
        }
        return !timerData.workItem.isCancelled
    }

    /// Cleanup all timer state
    func cleanup() {
        CTLogger.logWithLevel(1, type: 1, message: "\(tag) cleaning up timer state")
        cancelAllTimers()
        lock.lock()
        activeJobs.removeAll()
        cancelledJobs.removeAll()
        lock.unlock()
        CTLogger.logWithLevel(1, type: 1, message: "\(tag) cleanup complete")
    }
    
    /// Get count of active timers
    func getActiveTimerCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return activeJobs.count
    }

    // MARK: - Lifecycle Handlers
    
    /// App went to background - cancel all timers
    func onAppBackground() {
        lock.lock()
        // Store all active timers as cancelled BEFORE cancelling them
        let currentTime = Date().timeIntervalSince1970
        for (id, timerData) in activeJobs {
            if !timerData.workItem.isCancelled {
                // Calculate elapsed time
                let elapsedTime = currentTime - timerData.scheduledAt
                // Store cancelled job data
                cancelledJobs[id] = CancelledJobData(
                    originalDelay: timerData.delay,
                    scheduledAt: timerData.scheduledAt,
                    callback: timerData.callback
                )
                CTLogger.logWithLevel(1, type: 1, message: "\(tag) Stored cancelled timer: \(id), elapsed: \(elapsedTime)s")
            }
        }
        // Now cancel all work items
        let jobsToCancel = activeJobs.values.map { $0.workItem }
        lock.unlock()
        for workItem in jobsToCancel {
            workItem.cancel()
        }
        CTLogger.logWithLevel(1, type: 1, message: "\(tag) Cancelled all timers on background")
    }
    
    /// App came to foreground - reschedule cancelled timers with remaining time
    func onAppForeground() {
        lock.lock()
        let currentTime = Date().timeIntervalSince1970
        var toReschedule: [RescheduleData] = []
        var toDiscard: [String] = []
        
        for (id, cancelledData) in cancelledJobs {
            let originalDelay = cancelledData.originalDelay
            let scheduledAt = cancelledData.scheduledAt
            
            let elapsedTime = currentTime - scheduledAt
            let remainingTime = originalDelay - elapsedTime
            CTLogger.logWithLevel(1, type: 1, message: "\(tag) Id \(id) - Original delay: \(originalDelay)s, " + "Elapsed: \(elapsedTime)s, Remaining: \(remainingTime)s")
            if remainingTime > 0 {
                toReschedule.append(
                    RescheduleData(
                        id: id,
                        remainingTime: remainingTime,
                        callback: cancelledData.callback
                    )
                )
            } else {
                toDiscard.append(id)
            }
        }
        lock.unlock()
        
        // Reschedule timers
        var rescheduledCount = 0
        for data in toReschedule {
            scheduleTimer(id: data.id, delay: data.remainingTime, callback: data.callback)
            rescheduledCount += 1
            CTLogger.logWithLevel(0, type: 0, message: "\(tag) Rescheduled \(data.id) with \(data.remainingTime)s remaining")
        }
        // Discard expired timers
        var discardedCount = 0
        for id in toDiscard {
            lock.lock()
            let cancelledData = cancelledJobs.removeValue(forKey: id)
            lock.unlock()
            
            if let cancelledData = cancelledData {
                discardedCount += 1
                cancelledData.callback(CTTimerResult.discarded(withId: id))
            }
        }
    }
    
    // MARK: - Private Helpers
    private func storeCancelledJob(id: String, delay: TimeInterval, scheduledAt: TimeInterval, callback: @escaping (CTTimerResult) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        cancelledJobs[id] = CancelledJobData(
            originalDelay: delay,
            scheduledAt: scheduledAt,
            callback: callback
        )
    }
    
    private func removeCancelledJob(id: String) {
        lock.lock()
        defer { lock.unlock() }
        cancelledJobs.removeValue(forKey: id)
    }
    
    private func removeActiveJob(id: String) {
        lock.lock()
        defer { lock.unlock() }
        activeJobs.removeValue(forKey: id)
    }
    
    // MARK: - Data Types
    private struct RescheduleData {
        let id: String
        let remainingTime: TimeInterval
        let callback: (CTTimerResult) -> Void
    }
    
    private struct CancelledJobData {
        let originalDelay: TimeInterval
        let scheduledAt: TimeInterval
        let callback: (CTTimerResult) -> Void
    }
}

typealias CTTimerResultCallback = (CTTimerResult) -> Void

@objc class CTCancelledJobData: NSObject {
    @objc let originalDelay: TimeInterval
    @objc let scheduledAt: TimeInterval
    let callback: CTTimerResultCallback
    
    @objc init(originalDelay: TimeInterval, scheduledAt: TimeInterval, callback: @escaping CTTimerResultCallback) {
        self.originalDelay = originalDelay
        self.scheduledAt = scheduledAt
        self.callback = callback
        super.init()
    }
    
    @objc func invokeCallback(with result: CTTimerResult) {
        callback(result)
    }
}
