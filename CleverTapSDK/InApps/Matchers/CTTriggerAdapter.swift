//
//  CTTriggerAdapter.swift
//  CleverTapSDK
//
//  Swift replacement for CTTriggerAdapter.h/.m. Wraps a single in-app trigger definition
//  (one "whenTriggers" entry) and exposes the event name / profile attribute / first-time flag
//  plus the CTTriggerCondition and CTTriggerRadius views built from its eventProperties /
//  itemProperties / geoRadius arrays. Built and read by CTTriggersMatcher.
//
//  Internal to the (now all-Swift) Matchers cluster: built and read by CTTriggersMatcher (Swift).
//  No ObjC consumer remains, so the @objc/@objcMembers interop scaffold has been removed.
//
//  Migration notes:
//  - The ObjC header was NS_ASSUME_NONNULL, but `eventName` and `profileAttrName` are read
//    straight from the JSON (nil when the key is absent) and CTTriggersMatcher reads them via
//    `trigger.profileAttrName ?: trigger.eventName`, which tolerates nil. They are therefore
//    optional here, matching the runtime reality rather than the (incorrect) nonnull annotation.
//  - `firstTimeOnly` bug fix (approved): the ObjC code did
//    `self.firstTimeOnly = triggerJSON[@"firstTimeOnly"]`, assigning an NSNumber *pointer* to a
//    BOOL — so the flag reflected the key's *presence*, not its value (a present key read truthy
//    even for `false`). It now reads the real boolean via `NSNumber.boolValue`, which also
//    accepts numeric 0 / 1. Consumed by CTTriggersMatcher's first-time-only gate.
//  - `op` is kept as a raw UInt literal default (Equals = 1) rather than importing the ObjC
//    CTTriggerOperator enum into the Swift scaffold — same forward-compat reasoning as
//    CTTriggerCondition: an NSNumber operator is used verbatim so unknown, server-sent codes
//    pass through to CTTriggerEvaluator's switch default ("no match") instead of being clamped.
//  - `properties` / `items` / `geoRadius` are stored as the raw arrays (`[Any]?`) so the
//    *count* accessors match the ObjC `NSArray.count` exactly; each element is interpreted as a
//    dictionary only when a condition/radius is actually requested.

import Foundation

public final class CTTriggerAdapter: NSObject {

    public let eventName: String?
    public let profileAttrName: String?
    public var firstTimeOnly: Bool

    private let properties: [Any]?
    private let items: [Any]?
    private let geoRadius: [Any]?

    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable; use init(json:)")
    }

    public init(json triggerJSON: [AnyHashable: Any]) {
        self.eventName = triggerJSON["eventName"] as? String
        self.properties = triggerJSON["eventProperties"] as? [Any]
        self.items = triggerJSON["itemProperties"] as? [Any]
        self.geoRadius = triggerJSON["geoRadius"] as? [Any]
        self.profileAttrName = triggerJSON["profileAttrName"] as? String
        self.firstTimeOnly = (triggerJSON["firstTimeOnly"] as? NSNumber)?.boolValue ?? false
        super.init()
    }

    public var propertyCount: Int {
        return properties?.count ?? 0
    }

    public var itemsCount: Int {
        return items?.count ?? 0
    }

    public var geoRadiusCount: Int {
        return geoRadius?.count ?? 0
    }

    public func property(at index: Int) -> CTTriggerCondition? {
        guard let properties = properties else { return nil }
        return triggerCondition(from: properties[index])
    }

    public func item(at index: Int) -> CTTriggerCondition? {
        guard let items = items else { return nil }
        return triggerCondition(from: items[index])
    }

    public func geoRadius(at index: Int) -> CTTriggerRadius? {
        guard let geoRadius = geoRadius else { return nil }
        let item = geoRadius[index] as? [AnyHashable: Any]
        let triggerRadius = CTTriggerRadius()
        triggerRadius.latitude = item?["lat"] as? NSNumber
        triggerRadius.longitude = item?["lng"] as? NSNumber
        triggerRadius.radius = item?["rad"] as? NSNumber
        return triggerRadius
    }

    private func triggerCondition(from property: Any) -> CTTriggerCondition {
        let dict = property as? [AnyHashable: Any]
        let value = CTTriggerValue(value: dict?["propertyValue"])

        var op: UInt = 1 // CTTriggerOperatorEquals — default when operator is absent/non-numeric
        if let opNumber = dict?["operator"] as? NSNumber {
            op = opNumber.uintValue
        } else {
            // Mirrors CleverTapLogStaticDebug: build the message only when debug logging is on.
            let level = CTLogger.getDebugLevel()
            if level > 0 {
                CTLogger.logWithLevel(level, type: CTLogType.debug.rawValue,
                                      message: "Cannot parse operator: \(dict?["operator"] ?? "nil").")
            }
        }

        return CTTriggerCondition(properyName: dict?["propertyName"] as? String ?? "",
                                  op: op,
                                  value: value)
    }
}
