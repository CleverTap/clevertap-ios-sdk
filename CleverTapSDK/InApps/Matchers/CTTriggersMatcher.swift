//
//  CTTriggersMatcher.swift
//  CleverTapSDK
//
//  Swift replacement for CTTriggersMatcher.h/.m — the last class in the InApps/Matchers cluster.
//  Decides whether a fired event satisfies any of an in-app campaign's `whenTriggers`: it builds a
//  CTTriggerAdapter per trigger and matches event name / profile attribute, property conditions,
//  first-time-only, geo-radius (and, for Charged events, item conditions) via CTTriggerEvaluator.
//
//  Access control:
//  - `@objcMembers public final class`: it MUST be public. The CocoaPods `use_frameworks!` build only
//    emits *public* @objc Swift into the pod's generated CleverTapSDK-Swift.h, so CTInAppEvaluationManager
//    (still ObjC) can only construct it via initWithDataStore: and call matchEventWhenTriggers:event:
//    (both selectors pinned) if it is public. The rest of the cluster is Swift and reaches it directly,
//    and CTNdEvaluationManager holds it as a `private` property.
//  - Unlike CTLimitsMatcher, its public signature exposes only public types (CTEventAdapter,
//    CTLocalDataStore), so it does not leak anything into the distributed public .swiftinterface. See
//    [[matchers-objc-pin-cleanup]].
//
//  Migration notes:
//  - `dataStore` is optional: the class is constructed both with `init()` (no store — triggers that
//    aren't first-time-only never consult it) and `initWithDataStore:`. A nil store makes a
//    first-time-only check fail (matching the ObjC `[nil isEventLoggedFirstTime:]` → NO).
//  - The ObjC `matchProperties` / `matchGeoRadius` wrapped CTTriggerEvaluator calls in `@try/@catch`
//    (and `matchProperties` then read an uninitialized `BOOL matched` if it ever threw — a latent
//    bug). The evaluator is Swift now and cannot raise an NSException, so the try/catch is dropped;
//    `let matched = …` also removes the uninitialized-read. No observable behaviour change.
//  - `CLTAP_CHARGED_EVENT` is `#define @"Charged"` (Swift-invisible) → inlined.
//  - CTUtils / CTLocalDataStore / CTTrigger* / CTEventAdapter are all reached directly.

import Foundation
import CoreLocation

@objcMembers
public final class CTTriggersMatcher: NSObject {

    private let dataStore: CTLocalDataStore?

    public override init() {
        self.dataStore = nil
        super.init()
    }

    @objc(initWithDataStore:)
    public init(dataStore: CTLocalDataStore) {
        self.dataStore = dataStore
        super.init()
    }

    @objc(matchEventWhenTriggers:event:)
    public func matchEvent(whenTriggers: [Any], event: CTEventAdapter) -> Bool {
        // Events in the array are OR-ed.
        for case let triggerObject as [AnyHashable: Any] in whenTriggers {
            let trigger = CTTriggerAdapter(json: triggerObject)
            if event.eventName == "Charged" { // CLTAP_CHARGED_EVENT
                if matchCharged(trigger: trigger, event: event) {
                    return true
                }
            } else if match(trigger: trigger, event: event) {
                return true
            }
        }
        return false
    }

    private func match(trigger: CTTriggerAdapter, event: CTEventAdapter) -> Bool {
        let eventNameMatch = CTUtils.areEqualNormalizedName(event.eventName, andName: trigger.eventName)
        let profileAttrNameMatch = event.profileAttrName != nil
            && CTUtils.areEqualNormalizedName(event.profileAttrName, andName: trigger.profileAttrName)
        if !eventNameMatch && !profileAttrNameMatch {
            return false
        }
        if !matchProperties(event: event, trigger: trigger) {
            return false
        }
        if !matchFirstTimeOnly(trigger: trigger) {
            return false
        }
        if !matchGeoRadius(event: event, trigger: trigger) {
            return false
        }
        return true
    }

    private func matchProperties(event: CTEventAdapter, trigger: CTTriggerAdapter) -> Bool {
        // Property conditions are AND-ed.
        for i in 0..<trigger.propertyCount {
            guard let condition = trigger.property(at: i) else { continue }
            let eventValue = event.propertyValueNamed(condition.propertyName)
            if !CTTriggerEvaluator.evaluate(condition.op, expected: condition.value, actual: eventValue) {
                return false
            }
        }
        return true
    }

    private func matchGeoRadius(event: CTEventAdapter, trigger: CTTriggerAdapter) -> Bool {
        let geoRadiusCount = trigger.geoRadiusCount
        if geoRadiusCount == 0 {
            return true
        }
        if CLLocationCoordinate2DIsValid(event.location) {
            // GeoRadius conditions are OR-ed.
            for i in 0..<geoRadiusCount {
                guard let triggerRadius = trigger.geoRadius(at: i) else { continue }
                let expected = CLLocationCoordinate2D(latitude: triggerRadius.latitude?.doubleValue ?? 0,
                                                      longitude: triggerRadius.longitude?.doubleValue ?? 0)
                if CTTriggerEvaluator.evaluateDistance(triggerRadius.radius ?? NSNumber(value: 0),
                                                       expected: expected, actual: event.location) {
                    return true
                }
            }
        }
        return false
    }

    private func matchCharged(trigger: CTTriggerAdapter, event: CTEventAdapter) -> Bool {
        if !match(trigger: trigger, event: event) {
            return false
        }
        // Item property conditions are AND-ed (Charged event only).
        for i in 0..<trigger.itemsCount {
            guard let itemCondition = trigger.item(at: i) else { continue }
            let eventValues = event.itemValueNamed(itemCondition.propertyName)
            if !CTTriggerEvaluator.evaluate(itemCondition.op, expected: itemCondition.value, actual: eventValues) {
                return false
            }
        }
        return true
    }

    private func matchFirstTimeOnly(trigger: CTTriggerAdapter) -> Bool {
        if !trigger.firstTimeOnly {
            return true
        }
        let nameToCheck = trigger.profileAttrName ?? trigger.eventName
        return dataStore?.isEventLoggedFirstTime(nameToCheck) ?? false
    }
}
