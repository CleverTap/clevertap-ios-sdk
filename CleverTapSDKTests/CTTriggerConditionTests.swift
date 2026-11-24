// CTTriggerConditionTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTTriggerCondition — mirrors CTTriggerConditionTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// `op` is the raw CTTriggerOperator code (UInt), stored verbatim. Known raw values used:
//   GreaterThan = 0, Equals = 1, NotContains = 28.
// Unknown codes are preserved as-is (forward-compat) so CTTriggerEvaluator's switch
// default routes them to "no match" rather than a clamped operator matching by accident.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTTriggerCondition")
struct CTTriggerConditionTests {

    @Test("init sets all properties")
    func initSetsAllProperties() {
        let value = CTTriggerValue(value: "shoes")
        let cond = CTTriggerCondition(properyName: "category", op: 1, value: value) // Equals
        #expect(cond.propertyName == "category")
        #expect(cond.op == 1)
        #expect(cond.value === value)
    }

    @Test("init stores Equals operator code (1)")
    func initStoresEqualsCode() {
        let cond = CTTriggerCondition(properyName: "price", op: 1, value: CTTriggerValue(value: 0))
        #expect(cond.op == 1)
    }

    @Test("init stores GreaterThan operator code (0)")
    func initStoresGreaterThanCode() {
        let cond = CTTriggerCondition(properyName: "amount", op: 0, value: CTTriggerValue(value: 100))
        #expect(cond.op == 0)
    }

    @Test("init stores NotContains operator code (28)")
    func initStoresNotContainsCode() {
        let cond = CTTriggerCondition(properyName: "color", op: 28, value: CTTriggerValue(value: "red"))
        #expect(cond.op == 28)
    }

    @Test("init stores an unknown operator code verbatim (forward-compat)")
    func initStoresUnknownCodeVerbatim() {
        // A code the SDK does not recognise must be kept as-is so the evaluator's `default`
        // path yields no match, instead of being clamped onto a known operator.
        let cond = CTTriggerCondition(properyName: "x", op: 99, value: CTTriggerValue(value: "y"))
        #expect(cond.op == 99)
    }
}
