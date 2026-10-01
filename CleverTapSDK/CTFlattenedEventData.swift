//
//  CTFlattenedEventData.swift
//  CleverTapSDK
//
//  Swift replacement for CTFlattenedEventData.h/.m. Immutable tagged value describing the
//  flattened payload attached to a queued event — either profile changes, event properties,
//  or "no data". Built via factories and consumed by CleverTap.m (queue/log/evaluate paths).
//
//  Access control:
//  - `@objcMembers public final class` + `@objc public enum` preserve the API surface for the
//    ObjC callers (CleverTap.m switches on `type`, reads `profileChanges`/`eventProperties`,
//    and uses `CTFlattenedEventData.noData`). The enum raw values keep declaration order
//    (profileChanges=0, eventProperties=1, noData=2) to match the original NS_ENUM.
//
//  Notes:
//  - `noData` is a shared singleton (ObjC used dispatch_once); here it is a `static let`,
//    which is lazily initialised exactly once and thread-safe, preserving reference identity.
//  - The dictionaries are stored by value (Swift Dictionary value semantics), preserving the
//    original `[changes copy]` defensive-copy behaviour.

import Foundation

@objc public enum CTFlattenedEventDataType: Int {
    case profileChanges
    case eventProperties
    case noData
}

@objcMembers
public final class CTFlattenedEventData: NSObject {

    public let type: CTFlattenedEventDataType
    private let data: [String: Any]?

    private init(type: CTFlattenedEventDataType, data: [String: Any]?) {
        self.type = type
        self.data = data
        super.init()
    }

    public static func profileChanges(_ changes: [String: Any]) -> CTFlattenedEventData {
        CTFlattenedEventData(type: .profileChanges, data: changes)
    }

    public static func eventProperties(_ properties: [String: Any]) -> CTFlattenedEventData {
        CTFlattenedEventData(type: .eventProperties, data: properties)
    }

    private static let sharedNoData = CTFlattenedEventData(type: .noData, data: nil)

    public static func noData() -> CTFlattenedEventData {
        sharedNoData
    }

    public func profileChanges() -> [String: Any]? {
        type == .profileChanges ? data : nil
    }

    public func eventProperties() -> [String: Any]? {
        type == .eventProperties ? data : nil
    }
}
