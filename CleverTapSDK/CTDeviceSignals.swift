//
//  CTDeviceSignals.swift
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation
#if os(iOS)
import Network

/// Tracks whether the network is expensive (cellular or hotspot) or in Low Data Mode. Shared by all instances.
@objc(CTNetworkCostMonitor)
public final class CTNetworkCostMonitor: NSObject {

    @objc public static let shared = CTNetworkCostMonitor()

    // Written on the monitor's queue, read from the SDK queues.
    private let lock = NSLock()
    private var started = false
    private var currentMetered: NSNumber?
    private var currentLowData: NSNumber?
    // AnyObject so the class needs no iOS 12 availability.
    private var monitor: AnyObject?

    /// Starts once, later calls do nothing.
    @objc public func start() {
        lock.lock()
        defer { lock.unlock() }
        guard !started else { return }
        started = true
        if #available(iOS 12.0, *) {
            let pathMonitor = NWPathMonitor()
            pathMonitor.pathUpdateHandler = { [weak self] path in
                self?.update(with: path)
            }
            pathMonitor.start(queue: DispatchQueue(label: "com.clevertap.networkCostMonitor"))
            monitor = pathMonitor
        }
    }

    /// True on cellular or hotspot, nil while offline or unknown.
    @objc public var metered: NSNumber? {
        lock.lock()
        defer { lock.unlock() }
        return currentMetered
    }

    /// True in Low Data Mode, nil below iOS 13, while offline or unknown.
    @objc public var lowData: NSNumber? {
        lock.lock()
        defer { lock.unlock() }
        return currentLowData
    }

    @available(iOS 12.0, *)
    private func update(with path: NWPath) {
        let usable = path.status == .satisfied
        var lowData: NSNumber?
        if usable, #available(iOS 13.0, *) {
            lowData = NSNumber(value: path.isConstrained)
        }
        lock.lock()
        currentMetered = usable ? NSNumber(value: path.isExpensive) : nil
        currentLowData = lowData
        lock.unlock()
    }
}
#endif
