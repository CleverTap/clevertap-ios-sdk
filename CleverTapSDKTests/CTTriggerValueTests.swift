// CTTriggerValueTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTTriggerValue — mirrors CTTriggerValueTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTTriggerValue is a stateless tagged value (no shared state), so a fresh instance per
// @Test suffices. The Swift type's typed accessors (stringValue/numberValue/arrayValue) are
// optional, so the "nil" assertions compare directly with `== nil`.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTTriggerValue")
struct CTTriggerValueTests {

    @Test("init with string sets stringValue")
    func initWithStringSetsStringValue() {
        let tv = CTTriggerValue(value: "hello")
        #expect(tv.value as? String == "hello")
        #expect(tv.stringValue == "hello")
        #expect(tv.numberValue == nil)
        #expect(tv.arrayValue == nil)
        #expect(!tv.isArray())
    }

    @Test("init with number sets numberValue")
    func initWithNumberSetsNumberValue() {
        let tv = CTTriggerValue(value: 42)
        #expect(tv.value as? NSNumber == 42)
        #expect(tv.numberValue == 42)
        #expect(tv.stringValue == nil)
        #expect(tv.arrayValue == nil)
        #expect(!tv.isArray())
    }

    @Test("init with array sets arrayValue and isArray is true")
    func initWithArraySetsArrayValue() {
        let arr = [1, 2, 3]
        let tv = CTTriggerValue(value: arr)
        #expect(tv.value as? [Int] == arr)
        #expect(tv.arrayValue as? [Int] == arr)
        #expect(tv.stringValue == nil)
        #expect(tv.numberValue == nil)
        #expect(tv.isArray())
    }

    @Test("init with unknown type sets no typed value")
    func initWithUnknownTypeSetsNoTypedValue() {
        let tv = CTTriggerValue(value: ["key": "val"])
        #expect(tv.value as? [String: String] == ["key": "val"])
        #expect(tv.stringValue == nil)
        #expect(tv.numberValue == nil)
        #expect(tv.arrayValue == nil)
        #expect(!tv.isArray())
    }

    @Test("isArray is false for string")
    func isArrayFalseForString() {
        #expect(!CTTriggerValue(value: "text").isArray())
    }

    @Test("isArray is false for number")
    func isArrayFalseForNumber() {
        #expect(!CTTriggerValue(value: 3.14).isArray())
    }

    @Test("init with nil sets no value")
    func initWithNilSetsNoValue() {
        // nil is tolerated (CTTriggerAdapter passes property["propertyValue"] which may be nil) —
        // nothing is set, no trap.
        let tv = CTTriggerValue(value: nil)
        #expect(tv.value == nil)
        #expect(tv.stringValue == nil)
        #expect(tv.numberValue == nil)
        #expect(tv.arrayValue == nil)
        #expect(!tv.isArray())
    }
}
