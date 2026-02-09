//
//  InAppDelayConstants.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 13/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation

// MARK: - Constants
/**
 * Constants for in-app delay configuration
 */
@objc public class InAppDelayConstants: NSObject {
    @objc public static let INAPP_DELAY_AFTER_TRIGGER = "delayAfterTrigger"
    @objc public static let INAPP_ID_IN_PAYLOAD = "ti"
    @objc public static let INAPP_MIN_DELAY_SECONDS = 1
    @objc public static let INAPP_MAX_DELAY_SECONDS = 1200
    @objc public static let INAPP_DEFAULT_DELAY_SECONDS = 0
}

/**
 * Constants for in-app inaction configuration
 */
@objc public class InAppInActionConstants: NSObject {
    @objc public static let INAPP_INACTION_DURATION = "inactionDuration"
    @objc public static let INAPP_MIN_INACTION_SECONDS = 1
    @objc public static let INAPP_MAX_INACTION_SECONDS = 1200
    @objc public static let INAPP_DEFAULT_INACTION_SECONDS = 0
}

// MARK: - Duration Partitioner

/**
 * Utility class for partitioning in-app notifications by their display duration.
 *
 * Duration categories:
 * - **Immediate**: duration = 0, no delay fields present
 * - **Delayed**: has valid `delayAfterTrigger` (1-1200 seconds)
 * - **InAction**: has valid `inactionDuration` (1-1200 seconds)
 * - **Unknown**: actual duration determined later via eval flow (used for SS meta)
 *
 * Provides specialized partition functions for different in-app sources:
 * - `partitionLegacyInApps`: immediate + delayed
 * - `partitionLegacyMetaInApps`: inAction only
 * - `partitionClientSideInApps`: immediate + delayed
 * - `partitionServerSideMetaInApps`: unknown + inAction
 * - `partitionAppLaunchServerSideInApps`: immediate + delayed
 * - `partitionAppLaunchServerSideMetaInApps`: inAction only
 */
@objc @objcMembers public class InAppDurationPartitioner: NSObject {
    
    // MARK: - Public Partition Methods
    
    /**
     * Partitions legacy in-apps by duration: immediate and delayed.
     *
     * Note: This source does NOT contain `inactionDuration` items.
     * InAction items come separately in `inapp_notifs_meta`.
     *
     * @param inAppsArray The array of legacy in-app notifications
     * @return ImmediateAndDelayed containing partitioned in-apps
     */
    public static func partitionImmediateDelayedInApps(_ inAppsArray: NSArray?) -> ImmediateAndDelayed {
        guard let inAppsArray = inAppsArray else {
            return ImmediateAndDelayed.empty()
        }
        var immediate = [NSDictionary]()
        var delayed = [NSDictionary]()
        
        for item in inAppsArray {
            guard let inApp = item as? NSDictionary else { continue }
            
            if hasDelayedDuration(inApp) {
                delayed.append(inApp)
            } else {
                immediate.append(inApp)
            }
        }
        return ImmediateAndDelayed(
            immediateInApps: NSArray(array: immediate),
            delayedInApps: NSArray(array: delayed)
        )
    }
    /**
     * Wraps legacy metadata in-apps as inAction only.
     *
     * All items in `inapp_notifs_meta` have `inactionDuration`
     * → fetch content after inactivity timer.
     *
     * Note: No partitioning needed as all items are inAction.
     *
     * @param inAppsArray The array of legacy metadata in-app notifications
     * @return InActionOnly containing inAction in-apps
     */
    public static func partitionLegacyMetaInApps(_ inAppsArray: NSArray?) -> InActionOnly {
        return InActionOnly(inActionInApps: inAppsArray ?? NSArray())
    }
    
    /**
     * Partitions server-side metadata in-apps by duration: unknown and inAction.
     *
     * - **Unknown**: No `inactionDuration` → goes through `inApps_eval` flow
     *   → actual duration (immediate/delayed) determined after eval response
     * - **InAction**: Has `inactionDuration` → fetch content after inactivity timer
     *
     * Note: Server-side meta does NOT have `delayAfterTrigger` directly
     * (delay info comes only after eval or inAction fetch).
     *
     * @param inAppsArray The array of server-side metadata in-app notifications
     * @return UnknownAndInAction containing partitioned in-apps
     */
    public static func partitionServerSideMetaInApps(_ inAppsArray: NSArray?) -> UnknownAndInAction {
        guard let inAppsArray = inAppsArray else {
            return UnknownAndInAction.empty()
        }
        
        var unknownDuration = [NSDictionary]()
        var inAction = [NSDictionary]()
        
        for item in inAppsArray {
            guard let inApp = item as? NSDictionary else { continue }
            
            if hasInActionDuration(inApp) {
                inAction.append(inApp)
            } else {
                unknownDuration.append(inApp)
            }
        }
        
        return UnknownAndInAction(
            unknownDurationInApps: NSArray(array: unknownDuration),
            inActionInApps: NSArray(array: inAction)
        )
    }
    /**
     * Wraps app-launch server-side metadata in-apps as inAction only.
     *
     * All items in `inapp_notifs_applaunched_meta` have `inactionDuration`
     * → fetch content after inactivity timer.
     *
     * Note: No partitioning needed as all items are inAction.
     *
     * @param inAppsArray The array of app-launch server-side metadata in-app notifications
     * @return InActionOnly containing inAction in-apps
     */
    public static func partitionAppLaunchServerSideMetaInApps(_ inAppsArray: NSArray?) -> InActionOnly {
        return InActionOnly(inActionInApps: inAppsArray ?? NSArray())
    }
    
    // MARK: - Private Helper Methods
    
    /**
     * Checks if the in-app has a valid inAction duration.
     * Valid range: 1-1200 seconds
     */
    private static func hasInActionDuration(_ inApp: NSDictionary) -> Bool {
        let inactionSeconds = (inApp[InAppInActionConstants.INAPP_INACTION_DURATION] as? Int) 
            ?? InAppInActionConstants.INAPP_DEFAULT_INACTION_SECONDS
        
        return inactionSeconds >= InAppInActionConstants.INAPP_MIN_INACTION_SECONDS 
            && inactionSeconds <= InAppInActionConstants.INAPP_MAX_INACTION_SECONDS
    }
    
    /**
     * Checks if the in-app has a valid delayed duration.
     * Valid range: 1-1200 seconds
     */
    private static func hasDelayedDuration(_ inApp: NSDictionary) -> Bool {
        let delaySeconds = (inApp[InAppDelayConstants.INAPP_DELAY_AFTER_TRIGGER] as? Int) 
            ?? InAppDelayConstants.INAPP_DEFAULT_DELAY_SECONDS
        
        return delaySeconds >= InAppDelayConstants.INAPP_MIN_DELAY_SECONDS 
            && delaySeconds <= InAppDelayConstants.INAPP_MAX_DELAY_SECONDS
    }
}
