//
//  CTTriggerEvaluator.swift
//  CleverTapSDK
//
//  Swift replacement for CTTriggerEvaluator.h/.m. The pure, stateless engine that decides whether
//  an event's `actual` CTTriggerValue satisfies a trigger condition's `expected` CTTriggerValue
//  under a given operator (equals / compare / between / contains / set-exists), plus a geo-distance
//  check. Called by CTTriggersMatcher during in-app trigger evaluation.
//
//  Internal to the (now all-Swift) Matchers cluster: called by CTTriggersMatcher (Swift). No ObjC
//  consumer remains, so the @objc/@objcMembers interop scaffold has been removed.
//
//  Migration notes:
//  - `op` is a raw `UInt`, not the `CTTriggerOperator` enum. It arrives as `CTTriggerCondition.op`
//    (also a raw UInt), so unknown, server-sent operator codes fall through the switch `default` to
//    "no match" — the same forward-compat the ObjC `default: return NO` gave. A sealed enum can't hold
//    an out-of-range code, so `UInt` is the faithful type; `CTTriggerOperator` (now a Swift `@objc enum`)
//    is kept only for the named constants. Codes are named below for readability.
//  - `CLTAP_TRIGGER_BOOL_STRING_YES/NO` are `#define @"true"/@"false"` (Swift-invisible) → inlined.
//  - `CTUtils.numberFromString` / `haversineDistance` are reached directly (already Swift-visible).

import Foundation
import CoreLocation

public final class CTTriggerEvaluator: NSObject {

    // CTTriggerOperator raw codes (mirror CTTriggerOperator.h).
    private enum Op {
        static let greaterThan: UInt = 0
        static let equals: UInt = 1
        static let lessThan: UInt = 2
        static let contains: UInt = 3
        static let between: UInt = 4
        static let notEquals: UInt = 15
        static let set: UInt = 26          // Exists
        static let notSet: UInt = 27       // Not exists
        static let notContains: UInt = 28
    }

    private static let boolStringYes = "true"   // CLTAP_TRIGGER_BOOL_STRING_YES
    private static let boolStringNo = "false"   // CLTAP_TRIGGER_BOOL_STRING_NO

    public static func evaluate(_ op: UInt, expected: CTTriggerValue, actual: CTTriggerValue?) -> Bool {
        if actual?.isArray() == true {
            for val in actual?.arrayValue ?? [] {
                if evaluateBasic(op, expected: expected, actual: CTTriggerValue(value: val)) {
                    return true
                }
            }
            return false
        }
        return evaluateBasic(op, expected: expected, actual: actual)
    }

    public static func evaluateDistance(_ radius: NSNumber, expected: CLLocationCoordinate2D, actual: CLLocationCoordinate2D) -> Bool {
        let distance = CTUtils.haversineDistance(expected, coordinateB: actual)
        return distance <= radius.doubleValue
    }

    // MARK: - Private

    private static func evaluateBasic(_ op: UInt, expected: CTTriggerValue, actual: CTTriggerValue?) -> Bool {
        guard let actual = actual else {
            return op == Op.notSet
        }
        switch op {
        case Op.set: return true
        case Op.lessThan: return isLessThan(expected: expected, actual: actual)
        case Op.greaterThan: return isGreaterThan(expected: expected, actual: actual)
        case Op.equals: return equals(expected: expected, actual: actual)
        case Op.notEquals: return !equals(expected: expected, actual: actual)
        case Op.between: return isInRange(actual: actual, expected: expected)
        case Op.contains: return contains(actual: actual, expected: expected)
        case Op.notContains: return !contains(actual: actual, expected: expected)
        default: return false
        }
    }

    private static func numberFrom(_ triggerValue: CTTriggerValue?) -> NSNumber? {
        if let number = triggerValue?.numberValue {
            return number
        }
        return CTUtils.number(from: triggerValue?.value as? String)
    }

    private static func equalsStringOrNumber(_ a: Any?, _ b: Any?) -> Bool {
        if let aString = a as? String {
            let aClean = cleanString(aString)
            if let bString = b as? String {
                return aClean == cleanString(bString)
            } else if let bNumber = b as? NSNumber {
                var aNumber = CTUtils.number(from: aString)
                if aClean == boolStringYes {
                    aNumber = NSNumber(value: true)
                } else if aClean == boolStringNo {
                    aNumber = NSNumber(value: false)
                }
                if let aNumber = aNumber, aNumber.compare(bNumber) == .orderedSame {
                    return true
                }
            }
        }
        if let aNumber = a as? NSNumber {
            var bNumber: NSNumber?
            if let bNum = b as? NSNumber {
                bNumber = bNum
            } else if let bString = b as? String {
                bNumber = CTUtils.number(from: bString)
            }
            if let bNumber = bNumber, aNumber.compare(bNumber) == .orderedSame {
                return true
            }
        }
        return false
    }

    private static func cleanString(_ string: String) -> String {
        return string.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isLessThan(expected: CTTriggerValue, actual: CTTriggerValue) -> Bool {
        return compare(expected: expected, actual: actual, result: .orderedDescending)
    }

    private static func isGreaterThan(expected: CTTriggerValue, actual: CTTriggerValue) -> Bool {
        return compare(expected: expected, actual: actual, result: .orderedAscending)
    }

    private static func compare(expected: CTTriggerValue, actual: CTTriggerValue, result comparison: ComparisonResult) -> Bool {
        var expectedNumber = expected.numberValue
        if expected.isArray(), let array = expected.arrayValue, array.count == 1, let first = array[0] as? NSNumber {
            expectedNumber = first
        }
        if let expectedNumber = expectedNumber, let actualNumber = numberFrom(actual) {
            return expectedNumber.compare(actualNumber) == comparison
        }
        return false
    }

    private static func equals(expected: CTTriggerValue, actual: CTTriggerValue) -> Bool {
        if !expected.isArray() && !actual.isArray() {
            return equalsStringOrNumber(expected.value, actual.value)
        }
        if expected.isArray() && !actual.isArray() {
            for expectedValue in expected.arrayValue ?? [] {
                if equalsStringOrNumber(expectedValue, actual.value) {
                    return true
                }
            }
        }
        return false
    }

    private static func contains(actual: CTTriggerValue, expected: CTTriggerValue) -> Bool {
        var actualValue = actual.stringValue
        var expectedValue = expected.stringValue
        if let number = actual.numberValue {
            actualValue = number.stringValue
        }
        if let number = expected.numberValue {
            expectedValue = number.stringValue
        }
        if let actualValue = actualValue, let expectedValue = expectedValue {
            return cleanString(actualValue).contains(cleanString(expectedValue))
        }
        if expected.isArray(), let actualValue = actualValue {
            for expectedElement in expected.arrayValue ?? [] {
                var expectedString: String?
                if let string = expectedElement as? String {
                    expectedString = string
                } else if let number = expectedElement as? NSNumber {
                    expectedString = number.stringValue
                }
                if let expectedString = expectedString,
                   cleanString(actualValue).contains(cleanString(expectedString)) {
                    return true
                }
            }
        }
        return false
    }

    private static func isInRange(actual: CTTriggerValue, expected: CTTriggerValue) -> Bool {
        if let range = expected.arrayValue, range.count >= 2, !actual.isArray() {
            let valueFrom = doubleFromAny(range[0])
            let valueTo = doubleFromAny(range[1])
            if let actualNumber = numberFrom(actual) {
                return valueFrom <= actualNumber.doubleValue && actualNumber.doubleValue <= valueTo
            }
        }
        return false
    }

    // Mirrors ObjC `[id doubleValue]` which works for both NSNumber and NSString range bounds.
    private static func doubleFromAny(_ any: Any) -> Double {
        if let number = any as? NSNumber {
            return number.doubleValue
        }
        if let string = any as? String {
            return (string as NSString).doubleValue
        }
        return 0
    }
}
