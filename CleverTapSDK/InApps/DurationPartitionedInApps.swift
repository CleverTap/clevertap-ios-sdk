//
//  CTDurationPartitionedInApps.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 13/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation

/**
 * Protocol representing in-app notifications partitioned by their display duration.
 *
 * Duration types:
 * - **Immediate**: No delay, display right away
 * - **Delayed**: Has `delayAfterTrigger`, display after specified seconds
 * - **InAction**: Has `inactionDuration`, fetch content after user inactivity timer
 * - **Unknown**: Actual duration (immediate/delayed) determined later via eval flow
 *
 * Conforming types:
 * - `ImmediateAndDelayed`: For Legacy, Client-Side, and AppLaunch Server-Side in-apps
 * - `UnknownAndInAction`: For Server-Side metadata in-apps
 * - `InActionOnly`: For Legacy metadata and AppLaunch Server-Side metadata in-apps
 */
@objc public protocol DurationPartitionedInApps { }

/**
 * Partition containing immediate and delayed duration in-apps.
 *
 * Used for:
 * - Legacy in-apps (`inapp_notifs`)
 * - Client-Side in-apps (`inapp_notifs_cs`)
 * - AppLaunch Server-Side in-apps (`inapp_notifs_applaunched`)
 *
 * Note: These sources do NOT contain `inactionDuration` items.
 * InAction items come separately in their respective `_meta` keys.
 */
@objc @objcMembers public class ImmediateAndDelayed: NSObject, DurationPartitionedInApps {
    public let immediateInApps: NSArray
    public let delayedInApps: NSArray
    
    init(immediateInApps: NSArray, delayedInApps: NSArray) {
        self.immediateInApps = immediateInApps
        self.delayedInApps = delayedInApps
        super.init()
    }
    @objc public func hasImmediateInApps() -> Bool {
        return (immediateInApps.count > 0)
    }
    @objc public func hasDelayedInApps() -> Bool {
        return (delayedInApps.count > 0)
    }
    @objc public static func empty() -> ImmediateAndDelayed {
        return ImmediateAndDelayed(immediateInApps: [], delayedInApps: [])
    }
}

/**
 * Partition containing unknown and inAction duration in-apps.
 *
 * Used for:
 * - Server-Side metadata in-apps (`inapp_notifs_ss`)
 *
 * - **Unknown**: No `inactionDuration` → goes through `inApps_eval` flow
 *   → actual duration (immediate/delayed) determined after eval response
 * - **InAction**: Has `inactionDuration` → fetch content after inactivity timer
 */
@objc @objcMembers public class UnknownAndInAction: NSObject, DurationPartitionedInApps {
    public let unknownDurationInApps: NSArray
    public let inActionInApps: NSArray
    
    init(unknownDurationInApps: NSArray, inActionInApps: NSArray) {
        self.unknownDurationInApps = unknownDurationInApps
        self.inActionInApps = inActionInApps
        super.init()
    }
    
    @objc public func hasUnknownDurationInApps() -> Bool {
        return (unknownDurationInApps.count > 0)
    }
    
    @objc public func hasInActionInApps() -> Bool {
        return (inActionInApps.count > 0)
    }
    
    @objc public static func empty() -> UnknownAndInAction {
        return UnknownAndInAction(unknownDurationInApps: [], inActionInApps: [])
    }
}

/**
 * Partition containing only inAction duration in-apps.
 *
 * Used for:
 * - Legacy metadata in-apps (`inapp_notifs_meta`)
 * - AppLaunch Server-Side metadata in-apps (`inapp_notifs_applaunched_meta`)
 *
 * All items have `inactionDuration` → fetch content after inactivity timer.
 */
@objc @objcMembers public class InActionOnly: NSObject, DurationPartitionedInApps {
    public let inActionInApps: NSArray
    
    init(inActionInApps: NSArray) {
        self.inActionInApps = inActionInApps
        super.init()
    }
    
    @objc public func hasInActionInApps() -> Bool {
        return (inActionInApps.count > 0)
    }
    
    @objc public static func empty() -> InActionOnly {
        return InActionOnly(inActionInApps: [])
    }
}

