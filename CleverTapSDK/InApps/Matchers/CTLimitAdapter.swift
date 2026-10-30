//
//  CTLimitAdapter.swift
//  CleverTapSDK
//
//  Swift replacement for CTLimitAdapter.h/.m. Thin, immutable wrapper around a
//  frequency-cap limit JSON dictionary (as delivered by the dashboard/server) that
//  exposes the parsed limit type, limit, frequency, and an emptiness check.
//
//  Internal to the (now all-Swift) Matchers cluster: CTLimitsMatcher (Swift) constructs it via
//  init(json:) and reads limitType()/limit()/frequency()/isEmpty(). No ObjC consumer remains, so
//  the @objc/@objcMembers interop scaffold has been removed. Accessors are kept as methods (not
//  computed properties) to match the original ObjC method contract.
//
//  No collection returns (enum / Int / Bool only), so the mutable-return-bridging rule does
//  not apply here.

import Foundation

enum CTLimitType: Int {
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

final class CTLimitAdapter: NSObject {

    private let limitJSON: [AnyHashable: Any]

    @available(*, unavailable)
    override init() {
        fatalError("init() is unavailable; use init(json:)")
    }

    init(json limitJSON: [AnyHashable: Any]) {
        self.limitJSON = limitJSON
        super.init()
    }

    func limitType() -> CTLimitType {
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

    func limit() -> Int {
        (limitJSON["limit"] as? NSNumber)?.intValue ?? 0
    }

    func frequency() -> Int {
        (limitJSON["frequency"] as? NSNumber)?.intValue ?? 0
    }

    func isEmpty() -> Bool {
        limitJSON.isEmpty
    }
}
