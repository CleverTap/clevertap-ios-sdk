// ContentMergerTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for ContentMerger — mirrors ContentMergerTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// ContentMerger is a stateless recursive merge utility (a single class method, no shared
// state), so the suite needs neither .serialized nor an init() fixture — a fresh call per
// @Test is sufficient. The ObjC method `+ (id)mergeWithVars:(id)vars diff:(id)diff` imports
// as `ContentMerger.merge(withVars:diff:) -> Any!`; results are cast to the expected NS type.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("ContentMerger")
struct ContentMergerTests {

    @Test("merge primitive (string vars, number diff) returns diff")
    func mergePrimitive() {
        let result = ContentMerger.merge(withVars: "a", diff: 4)
        #expect(result as? NSNumber == NSNumber(value: 4))
    }

    @Test("merge bool NO diff wins")
    func mergeBool() {
        let result = ContentMerger.merge(withVars: true, diff: false)
        #expect(result as? NSNumber == NSNumber(value: false))
        #expect((result as? NSNumber)?.boolValue == false)
    }

    @Test("merge bool YES diff wins")
    func mergeBoolYes() {
        let result = ContentMerger.merge(withVars: false, diff: true)
        #expect(result as? NSNumber == NSNumber(value: true))
        #expect((result as? NSNumber)?.boolValue == true)
    }

    @Test("merge map with primitive diff returns diff")
    func mergeMapWithPrimitive() {
        let vars: [String: Any] = ["abc": "qwe", "1": 123]
        let result = ContentMerger.merge(withVars: vars, diff: "diff")
        #expect(result as? String == "diff")
    }

    @Test("merge primitive values (string, number, null vars) return diff")
    func mergeValues() {
        #expect(ContentMerger.merge(withVars: "defaultValue", diff: "newValue") as? String == "newValue")
        #expect(ContentMerger.merge(withVars: 199, diff: 123456789) as? NSNumber == NSNumber(value: 123456789))
        #expect(ContentMerger.merge(withVars: NSNull(), diff: "newValue") as? String == "newValue")
    }

    @Test("merge nested vars replaced by diff")
    func mergeValuesComplex() {
        let vars: [String: Any] = ["messageId1": ["vars": ["myNumber": 0, "myString": "defaultValue"]]]
        let diff: [String: Any] = ["messageId1": ["vars": ["myNumber": 1, "myString": "newValue"]]]
        let expected = diff as NSDictionary
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == expected)
    }

    @Test("merge keeps defaults for keys absent in diff")
    func mergeValuesIncludeDefaults() {
        let vars: [String: Any] = ["messageId1": ["vars": ["myNumber": 0, "myString": "defaultValue"]]]
        let diff: [String: Any] = ["messageId1": ["vars": ["myString": "newValue"]]]
        let expected: NSDictionary = ["messageId1": ["vars": ["myNumber": 0, "myString": "newValue"]]]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == expected)
    }

    @Test("merge dictionaries overrides values")
    func mergeDictionaries() {
        let vars: [String: Any] = ["abc": "qwe", "nested2": ["a": "a", "c": NSNull(), "d": 4444]]
        let diff: [String: Any] = ["abc": "rty", "nested2": ["a": "a", "c": "value", "d": 555]]
        let expected: NSDictionary = ["abc": "rty", "nested2": ["a": "a", "c": "value", "d": 555]]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == expected)
    }

    @Test("merge dictionaries with null defaults")
    func mergeDictionariesWithNull() {
        let vars: [String: Any] = ["a": NSNull(), "b": NSNull()]
        let diff: [String: Any] = ["a": "text", "c": NSNull()]
        let expected: NSDictionary = ["a": "text", "b": NSNull(), "c": NSNull()]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == expected)
    }

    @Test("merge dictionaries include defaults (deep)")
    func mergeDictionariesIncludeDefaults() {
        let vars: [String: Any] = [
            "abc": "qwe",
            "nested": ["abc": "qwe", "1": 123],
            "nested2": ["a": "a", "b": [1, 2, 3, 4], "c": NSNull(), "d": 4444]
        ]
        let diff: [String: Any] = [
            "nested": ["abc": "abc", "qwerty": "qwerty"],
            "nested2": ["a": "b", "d": 111, "e": 999]
        ]
        let expected: NSDictionary = [
            "abc": "qwe",
            "nested": ["abc": "abc", "1": 123, "qwerty": "qwerty"],
            "nested2": ["a": "b", "b": [1, 2, 3, 4], "c": NSNull(), "d": 111, "e": 999]
        ]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == expected)
    }

    @Test("merge dictionaries include diffs (new nested keys)")
    func mergeDictionariesIncludeDiffs() {
        let vars: [String: Any] = ["abc": "qwe", "nested": ["abc": "qwe", "1": 123]]
        let diff: [String: Any] = ["nested": ["qwerty": "qwerty", "nested2": ["a": "b"]]]
        let expected: NSDictionary = [
            "abc": "qwe",
            "nested": ["abc": "qwe", "1": 123, "qwerty": "qwerty", "nested2": ["a": "b"]]
        ]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == expected)
    }

    @Test("merge with empty diff returns vars")
    func mergeWithEmpty() {
        let vars: [String: Any] = ["abc": "qwe", "nested": ["abc": "qwe", "1": 123]]
        let diff: [String: Any] = [:]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == vars as NSDictionary)
    }

    @Test("merge into empty vars returns diff")
    func mergeEmpty() {
        let vars: [String: Any] = [:]
        let diff: [String: Any] = ["abc": "qwe", "nested": ["abc": "qwe", "1": 123]]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == diff as NSDictionary)
    }

    @Test("merge null vars with dict diff returns diff")
    func mergeNull() {
        let diff: [String: Any] = ["abc": "qwe", "nested": ["abc": "qwe", "1": 123]]
        #expect(ContentMerger.merge(withVars: NSNull(), diff: diff) as? NSDictionary == diff as NSDictionary)
    }

    @Test("merge dict vars with null diff returns null")
    func mergeWithNull() {
        let vars: [String: Any] = [:]
        let result = ContentMerger.merge(withVars: vars, diff: NSNull())
        #expect(result is NSNull)
    }

    @Test("merge different primitive types per key")
    func mergeDifferentTypes() {
        let vars: [String: Any] = ["k1": 20, "k2": "hi", "k3": true, "k4": 4.3]
        let diff: [String: Any] = ["k1": 21, "k3": false, "k4": -4.8]
        let expected: NSDictionary = ["k1": 21, "k2": "hi", "k3": false, "k4": -4.8]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == expected)
    }

    @Test("merge nested dictionaries recursively")
    func mergeNestedDictionaries() {
        let vars: [String: Any] = [
            "k2": ["m1": 1, "m2": "hello", "m3": false],
            "k3": ["m1": 1, "m2": "hello", "m3": false],
            "k4": ["m1": 1, "m2": "hello", "m3": false],
            "k5": 4.3
        ]
        let diffs: [String: Any] = [
            "k2": ["m1": 1, "m2": "hello", "m3": false],
            "k3": ["m1": 2, "m2": "bye", "m3": true],
            "k4": ["m1": 2, "m3": true, "m4": "new key"]
        ]
        let expected: NSDictionary = [
            "k2": ["m1": 1, "m2": "hello", "m3": false],
            "k3": ["m1": 2, "m2": "bye", "m3": true],
            "k4": ["m1": 2, "m2": "hello", "m3": true, "m4": "new key"],
            "k5": 4.3
        ]
        #expect(ContentMerger.merge(withVars: vars, diff: diffs) as? NSDictionary == expected)
    }

    @Test("merge arrays not supported returns nil")
    func mergeArr() {
        let vars = [1, 2, 3, 4]
        let diff = [1, 2, 3, 6]
        let result = ContentMerger.merge(withVars: vars, diff: diff)
        #expect(result == nil)
    }

    @Test("merge dictionaries with array values keeps vars array")
    func mergeDictionariesArr() {
        let vars: [String: Any] = ["arr": [1, 2, 3, 4]]
        let diff: [String: Any] = ["arr": [1, 2, 3, 5]]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == vars as NSDictionary)
    }

    @Test("merge with nil diff returns vars unchanged")
    func mergeWithNilDiff() {
        let result = ContentMerger.merge(withVars: "someString", diff: nil)
        #expect(result as? String == "someString")
    }

    @Test("merge array vars with dict diff returns diff")
    func mergeArrayVarsWithDictDiff() {
        let vars = [1, 2]
        let diff: [String: Any] = ["key": "val"]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == diff as NSDictionary)
    }

    @Test("merge dict vars with array diff returns copy of vars")
    func mergeDictVarsWithArrayDiff() {
        let vars: [String: Any] = ["a": 1, "b": 2]
        let diff = [9, 8]
        #expect(ContentMerger.merge(withVars: vars, diff: diff) as? NSDictionary == vars as NSDictionary)
    }
}
