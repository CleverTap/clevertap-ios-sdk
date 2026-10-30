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
//  - `@objcMembers public final class` keeps it callable from the ObjC frequency-cap managers via the
//    framework's CleverTapSDK-Swift.h; the public selector is pinned with `@objc(...)` so it stays
//    byte-identical for those callers.
//
//  Migration notes:
//  - `whenLimits` is nullable: nil was a live "no limits" path (returns true). Each element is read
//    as a dictionary only to build a CTLimitAdapter (already Swift).
//  - The switch is exhaustive over the Swift `CTLimitType` enum — no `default`. The ObjC original had
//    one, but `CTLimitAdapter.limitType()` always returns a valid case (unknown/missing → `.ever`),
//    so that branch was unreachable.
//  - `CTImpressionManager` / `CTTriggerCounting` are reached directly (both already Swift-visible).

import Foundation

@objcMembers
public final class CTLimitsMatcher: NSObject {

    @objc(matchWhenLimits:forCampaignId:withImpressionManager:andTriggerManager:)
    public func match(whenLimits: [Any]?,
                      forCampaignId campaignId: String,
                      with impressionManager: CTImpressionManager,
                      andTriggerManager triggerManager: CTTriggerCounting) -> Bool {
        guard !campaignId.isEmpty else {
            return false
        }
        for case let limitJSON as [AnyHashable: Any] in whenLimits ?? [] {
            let limitAdapter = CTLimitAdapter(json: limitJSON)
            if limitAdapter.isEmpty() {
                continue
            }
            if !matchLimit(limitAdapter,
                           forCampaignId: campaignId,
                           with: impressionManager,
                           andTriggerManager: triggerManager) {
                return false
            }
        }
        return true
    }

    private func matchLimit(_ limit: CTLimitAdapter,
                            forCampaignId campaignId: String,
                            with impressionManager: CTImpressionManager,
                            andTriggerManager triggerManager: CTTriggerCounting) -> Bool {
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
            let triggerCount = Int(triggerManager.getTriggers(campaignId))
            return triggerCount % limit.limit() == 0
        case .onExactly:
            let triggerCount = Int(triggerManager.getTriggers(campaignId))
            return triggerCount == limit.limit()
        }
    }
}
