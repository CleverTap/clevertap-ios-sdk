//
//  CTLimitAdapter.swift
//  CleverTapSDK
//
//  Swift replacement for CTLimitAdapter.h/.m. Thin, immutable wrapper around a
//  frequency-cap limit JSON dictionary (as delivered by the dashboard/server) that
//  exposes the parsed limit type, limit, frequency, and an emptiness check.
//
//  Access control:
//  - `@objcMembers public final class` + `@objc public enum` keep the type usable from
//    Objective-C. CTLimitsMatcher.m constructs instances via init(json:), reads
//    limitType()/limit()/frequency()/isEmpty(), and switches on CTLimitType. `public` is
//    required so the in-pod ObjC caller sees it via the framework's CleverTapSDK-Swift.h.
//  - Accessors are methods (not computed properties) to match the original ObjC method
//    contract exactly (call sites use `limit.limit` / `[limit limitType]`).
//
//  No collection returns (enum / Int / Bool only), so the mutable-return-bridging rule does
//  not apply here.

import Foundation

@objc public enum CTLimitType: Int {
    case ever
    case session
    case seconds
    case minutes
    case hours
    case days
    case weeks
    case onEvery
    case onExactly
}

@objcMembers
public final class CTLimitAdapter: NSObject {

    private let limitJSON: [AnyHashable: Any]

    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable; use init(json:)")
    }

    @objc(initWithJSON:)
    public init(json limitJSON: [AnyHashable: Any]) {
        self.limitJSON = limitJSON
        super.init()
    }

    public func limitType() -> CTLimitType {
        guard let limitType = limitJSON["type"] as? String else {
            return .ever
        }
        switch limitType {
        case "ever": return .ever
        case "session": return .session
        case "seconds": return .seconds
        case "minutes": return .minutes
        case "hours": return .hours
        case "days": return .days
        case "weeks": return .weeks
        case "onEvery": return .onEvery
        case "onExactly": return .onExactly
        default: return .ever
        }
    }

    public func limit() -> Int {
        (limitJSON["limit"] as? NSNumber)?.intValue ?? 0
    }

    public func frequency() -> Int {
        (limitJSON["frequency"] as? NSNumber)?.intValue ?? 0
    }

    public func isEmpty() -> Bool {
        limitJSON.isEmpty
    }
}
