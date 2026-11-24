//
//  CTLimitsMatcher.swift
//  CleverTapSDK
//
//  Swift replacement for CTLimitsMatcher.h/.m. Decides whether a campaign still satisfies all of its
//  frequency-cap limits (session / seconds / minutes / hours / days / weeks / ever / onEvery /
//  onExactly), consulting the live CTImpressionManager (impression counts) and a CTTriggerCounting
//  source (trigger counts). Used by CTInAppFCManager and CTInAppEvaluationManager.
//
//  Access control:
//  - `@objcMembers public final class`: it MUST be public. The CocoaPods `use_frameworks!` build only
//    emits *public* @objc Swift into the pod's generated CleverTapSDK-Swift.h, so the framework's own
//    ObjC frequency-cap managers (CTInAppFCManager / CTInAppEvaluationManager) can only see it if it is
//    public. (The xcframework/archive build emits internal @objc too, which is why internal compiled
//    there but broke Pods.) The selector is pinned with `@objc(...)` so it stays byte-identical.
//  - The `andTriggerManager` parameter is deliberately typed `Any`, NOT `CTTriggerCounting`.
//    CTTriggerCounting is an ObjC protocol that the xcframework ships under PrivateHeaders, and a
//    `public` method that names it leaks a private type into the distributed public .swiftinterface —
//    which then fails to compile on import ("'CTTriggerCounting' is unavailable: cannot find Swift
//    declaration for this protocol"). The framework emits the interface with
//    -no-verify-emitted-module-interface, so that break is silent at build time and only surfaces in a
//    consuming app (e.g. SPMStarter via SPM). Taking `Any` and casting to CTTriggerCounting internally
//    keeps the private protocol out of the public interface while preserving behaviour for every
//    conformer (CTInAppTriggerManager and CTOffsetTriggerCounter). See [[matchers-objc-pin-cleanup]].
//
//  Migration notes:
//  - `whenLimits` is nullable: nil was a live "no limits" path (returns true). Each element is read
//    as a dictionary only to build a CTLimitAdapter (already Swift).
//  - The switch is exhaustive over the Swift `CTLimitType` enum — no `default`. The ObjC original had
//    one, but `CTLimitAdapter.limitType()` always returns a valid case (unknown/missing → `.ever`),
//    so that branch was unreachable.

import Foundation

@objcMembers
public final class CTLimitsMatcher: NSObject {

    @objc(matchWhenLimits:forCampaignId:withImpressionManager:andTriggerManager:)
    public func match(whenLimits: [Any]?,
                      forCampaignId campaignId: String,
                      with impressionManager: CTImpressionManager,
                      andTriggerManager triggerManager: Any) -> Bool {
        guard !campaignId.isEmpty else {
            return false
        }
        // `triggerManager` is `Any` only to keep the private CTTriggerCounting protocol out of the
        // public interface (see the access-control note above). Every real caller passes a conformer.
        let triggerCounter = triggerManager as? CTTriggerCounting
        for case let limitJSON as [AnyHashable: Any] in whenLimits ?? [] {
            let limitAdapter = CTLimitAdapter(json: limitJSON)
            if limitAdapter.isEmpty() {
                continue
            }
            if !matchLimit(limitAdapter,
                           forCampaignId: campaignId,
                           with: impressionManager,
                           andTriggerManager: triggerCounter) {
                return false
            }
        }
        return true
    }

    private func matchLimit(_ limit: CTLimitAdapter,
                            forCampaignId campaignId: String,
                            with impressionManager: CTImpressionManager,
                            andTriggerManager triggerManager: CTTriggerCounting?) -> Bool {
        switch limit.limitType() {
        case .session:
            return impressionManager.perSession(campaignId) < limit.limit()
        case .seconds:
            return impressionManager.perSecond(campaignId, seconds: limit.frequency()) < limit.limit()
        case .minutes:
            return impressionManager.perMinute(campaignId, minutes: limit.frequency()) < limit.limit()
        case .hours:
            return impressionManager.perHour(campaignId, hours: limit.frequency()) < limit.limit()
        case .days:
            return impressionManager.perDay(campaignId, days: limit.frequency()) < limit.limit()
        case .weeks:
            return impressionManager.perWeek(campaignId, weeks: limit.frequency()) < limit.limit()
        case .ever:
            return impressionManager.getImpressions(campaignId).count < limit.limit()
        case .onEvery:
            let frequency = limit.limit()
            // A non-positive frequency would trap on `% 0` in Swift (release included); treat it as
            // unsatisfied. A missing trigger counter likewise can't satisfy a trigger-based limit.
            guard frequency > 0, let triggerManager = triggerManager else {
                return false
            }
            let triggerCount = Int(triggerManager.getTriggers(campaignId))
            return triggerCount % frequency == 0
        case .onExactly:
            guard let triggerManager = triggerManager else {
                return false
            }
            let triggerCount = Int(triggerManager.getTriggers(campaignId))
            return triggerCount == limit.limit()
        }
    }
}
