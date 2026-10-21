//
//  CTTriggerValue.swift
//  CleverTapSDK
//
//  Swift replacement for CTTriggerValue.h/.m. A tagged wrapper around a trigger-condition
//  value: it stores the raw value and, for the recognised kinds, a typed view
//  (string / number / array). Used by CTEventAdapter, CTTriggerCondition, CTTriggerAdapter
//  and CTTriggerEvaluator.
//
//  Access control:
//  - `@objcMembers public final class` keeps the type usable from the ObjC matcher cluster via
//    the framework's CleverTapSDK-Swift.h. `init(value:)` pins the ObjC selector `initWithValue:`.
//
//  Migration notes:
//  - The ObjC header was NS_ASSUME_NONNULL, but the typed accessors are nil when the stored
//    value isn't that kind, and `initWithValue:` is called with a possibly-nil dictionary value
//    (CTTriggerAdapter: property[@"propertyValue"]) which ObjC tolerated. So `value` and the
//    typed accessors are optional here — matching the runtime reality and avoiding a trap the
//    ObjC version never had.
//  - Independent `as?` casts replace the ObjC `isKindOfClass:` else-if chain (the kinds are
//    mutually exclusive, so the behaviour is identical).
//  - Returns are immutable (value / arrayValue are only read by consumers — verified — so the
//    mutable-return-bridging rule does not require NSMutable*).

import Foundation

@objcMembers
public final class CTTriggerValue: NSObject {

    public let value: Any?
    public let stringValue: String?
    public let numberValue: NSNumber?
    public let arrayValue: [Any]?

    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable; use init(value:)")
    }

    @objc(initWithValue:)
    public init(value: Any?) {
        self.value = value
        self.stringValue = value as? String
        self.numberValue = value as? NSNumber
        self.arrayValue = value as? [Any]
        super.init()
    }

    public func isArray() -> Bool {
        arrayValue != nil
    }
}
