// CTTriggerEvaluatorTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTTriggerEvaluator — mirrors CTTriggerEvaluatorTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTTriggerEvaluator is still Objective-C at this point (Phase 1 runs these tests against the
// existing ObjC source). It decides whether an `actual` CTTriggerValue satisfies an `expected`
// one under a CTTriggerOperator (equals / compare / between / contains / set-exists), plus a geo
// distance check. CTTriggerOperator is an ObjC NS_ENUM; its Swift cases are used below.
//
// Note: the "unknown operator → NO" case (CTTriggerEvaluatorTest.test_evaluate_unknownOperator…)
// is ObjC-only — Swift cannot build an out-of-range CTTriggerOperator (`init(rawValue: 99)` is nil).

import Testing
import Foundation
import CoreLocation
@testable import CleverTapSDK

@Suite("CTTriggerEvaluator")
struct CTTriggerEvaluatorTests {

    // CTTriggerOperator codes (mirror CTTriggerOperator.h); `evaluate` takes a raw UInt.
    private let greaterThan: UInt = 0
    private let equals: UInt = 1
    private let lessThan: UInt = 2
    private let contains: UInt = 3
    private let between: UInt = 4
    private let notEquals: UInt = 15
    private let set: UInt = 26
    private let notSet: UInt = 27
    private let notContains: UInt = 28

    private func tv(_ val: Any?) -> CTTriggerValue { CTTriggerValue(value: val) }

    // MARK: - Set / NotSet / nil actual

    @Test("Set with a non-nil actual returns true")
    func setNonNilActual() {
        #expect(CTTriggerEvaluator.evaluate(set, expected: tv("x"), actual: tv("anything")))
    }

    @Test("NotSet with a nil actual returns true")
    func notSetNilActual() {
        #expect(CTTriggerEvaluator.evaluate(notSet, expected: tv("x"), actual: nil))
    }

    @Test("NotSet with a non-nil actual returns false")
    func notSetNonNilActual() {
        #expect(!CTTriggerEvaluator.evaluate(notSet, expected: tv("x"), actual: tv("something")))
    }

    @Test("Equals with a nil actual returns false")
    func equalsNilActual() {
        #expect(!CTTriggerEvaluator.evaluate(equals, expected: tv("hello"), actual: nil))
    }

    @Test("LessThan with a nil actual returns false")
    func lessThanNilActual() {
        #expect(!CTTriggerEvaluator.evaluate(lessThan, expected: tv(10), actual: nil))
    }

    // MARK: - Equals (strings)

    @Test("Equals matching strings returns true")
    func equalsMatchingStrings() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv("shoes"), actual: tv("shoes")))
    }

    @Test("Equals mismatched strings returns false")
    func equalsMismatchedStrings() {
        #expect(!CTTriggerEvaluator.evaluate(equals, expected: tv("shoes"), actual: tv("hats")))
    }

    @Test("Equals is case-insensitive")
    func equalsCaseInsensitive() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv("Hello"), actual: tv("hello")))
    }

    @Test("Equals ignores surrounding whitespace")
    func equalsWhitespaceIgnored() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv(" Hello "), actual: tv("hello")))
    }

    // MARK: - Equals (numbers)

    @Test("Equals matching numbers returns true")
    func equalsMatchingNumbers() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv(42), actual: tv(42)))
    }

    @Test("Equals different numbers returns false")
    func equalsDifferentNumbers() {
        #expect(!CTTriggerEvaluator.evaluate(equals, expected: tv(42), actual: tv(43)))
    }

    @Test("Equals coerces a string expected against a number actual")
    func equalsStringNumberCoercion() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv("42"), actual: tv(42)))
    }

    @Test("Equals coerces a number expected against a string actual")
    func equalsNumberStringCoercion() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv(42), actual: tv("42")))
    }

    // MARK: - NotEquals

    @Test("NotEquals different returns true")
    func notEqualsDifferent() {
        #expect(CTTriggerEvaluator.evaluate(notEquals, expected: tv("shoes"), actual: tv("hats")))
    }

    @Test("NotEquals same returns false")
    func notEqualsSame() {
        #expect(!CTTriggerEvaluator.evaluate(notEquals, expected: tv("shoes"), actual: tv("shoes")))
    }

    // MARK: - LessThan

    @Test("LessThan actual lower returns true")
    func lessThanActualLower() {
        #expect(CTTriggerEvaluator.evaluate(lessThan, expected: tv(10), actual: tv(5)))
    }

    @Test("LessThan actual higher returns false")
    func lessThanActualHigher() {
        #expect(!CTTriggerEvaluator.evaluate(lessThan, expected: tv(10), actual: tv(15)))
    }

    @Test("LessThan equal returns false")
    func lessThanEqual() {
        #expect(!CTTriggerEvaluator.evaluate(lessThan, expected: tv(10), actual: tv(10)))
    }

    // MARK: - GreaterThan

    @Test("GreaterThan actual higher returns true")
    func greaterThanActualHigher() {
        #expect(CTTriggerEvaluator.evaluate(greaterThan, expected: tv(10), actual: tv(15)))
    }

    @Test("GreaterThan actual lower returns false")
    func greaterThanActualLower() {
        #expect(!CTTriggerEvaluator.evaluate(greaterThan, expected: tv(10), actual: tv(5)))
    }

    // MARK: - Between

    @Test("Between in range returns true")
    func betweenInRange() {
        #expect(CTTriggerEvaluator.evaluate(between, expected: tv([10, 20]), actual: tv(15)))
    }

    @Test("Between out of range returns false")
    func betweenOutOfRange() {
        #expect(!CTTriggerEvaluator.evaluate(between, expected: tv([10, 20]), actual: tv(25)))
    }

    @Test("Between at the lower boundary returns true")
    func betweenLowerBoundary() {
        #expect(CTTriggerEvaluator.evaluate(between, expected: tv([10, 20]), actual: tv(10)))
    }

    @Test("Between at the upper boundary returns true")
    func betweenUpperBoundary() {
        #expect(CTTriggerEvaluator.evaluate(between, expected: tv([10, 20]), actual: tv(20)))
    }

    // MARK: - Contains / NotContains

    @Test("Contains substring returns true")
    func containsSubstring() {
        #expect(CTTriggerEvaluator.evaluate(contains, expected: tv("world"), actual: tv("hello world")))
    }

    @Test("Contains no substring returns false")
    func containsNoSubstring() {
        #expect(!CTTriggerEvaluator.evaluate(contains, expected: tv("bar"), actual: tv("foo")))
    }

    @Test("Contains is case-insensitive")
    func containsCaseInsensitive() {
        #expect(CTTriggerEvaluator.evaluate(contains, expected: tv("WORLD"), actual: tv("hello world")))
    }

    @Test("NotContains with substring present returns false")
    func notContainsPresent() {
        #expect(!CTTriggerEvaluator.evaluate(notContains, expected: tv("world"), actual: tv("hello world")))
    }

    @Test("NotContains with substring absent returns true")
    func notContainsAbsent() {
        #expect(CTTriggerEvaluator.evaluate(notContains, expected: tv("xyz"), actual: tv("hello world")))
    }

    // MARK: - Array actual (iterates each element)

    @Test("Equals with an array actual matches one element")
    func equalsArrayActualMatchesOne() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv(3), actual: tv([1, 3, 5])))
    }

    @Test("Equals with an array actual and no match returns false")
    func equalsArrayActualNoMatch() {
        #expect(!CTTriggerEvaluator.evaluate(equals, expected: tv(9), actual: tv([1, 2, 4])))
    }

    @Test("Contains with an array actual matches one element")
    func containsArrayActualMatchesOne() {
        #expect(CTTriggerEvaluator.evaluate(contains, expected: tv("oo"), actual: tv(["bar", "foo", "baz"])))
    }

    // MARK: - Boolean-string coercion ("true"/"false" ↔ number)

    @Test("Equals coerces the string \"true\" against a bool number")
    func equalsTrueStringVsBoolNumber() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv("true"), actual: tv(true)))
    }

    @Test("Equals coerces the string \"false\" against a bool number")
    func equalsFalseStringVsBoolNumber() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv("false"), actual: tv(false)))
    }

    // MARK: - Array expected

    @Test("Equals with an array expected matches one element")
    func equalsArrayExpectedMatchesOne() {
        #expect(CTTriggerEvaluator.evaluate(equals, expected: tv(["a", "b"]), actual: tv("b")))
    }

    @Test("Contains with an array expected matches one element")
    func containsArrayExpectedMatchesOne() {
        #expect(CTTriggerEvaluator.evaluate(contains, expected: tv(["foo", "bar"]), actual: tv("xfooy")))
    }

    // MARK: - Coercion / flexible shapes in comparisons

    @Test("LessThan coerces a string actual to a number")
    func lessThanStringActualCoerced() {
        #expect(CTTriggerEvaluator.evaluate(lessThan, expected: tv(10), actual: tv("5")))
    }

    @Test("GreaterThan treats a single-element array expected as the scalar")
    func greaterThanSingleElementArrayExpected() {
        #expect(CTTriggerEvaluator.evaluate(greaterThan, expected: tv([10]), actual: tv(15)))
    }

    @Test("Contains matches a numeric element of an array expected by its string form")
    func containsArrayExpectedNumberElement() {
        #expect(CTTriggerEvaluator.evaluate(contains, expected: tv([123]), actual: tv("x123y")))
    }

    // MARK: - Negative / defensive paths

    @Test("LessThan against a non-numeric actual returns false")
    func lessThanNonNumericActual() {
        #expect(!CTTriggerEvaluator.evaluate(lessThan, expected: tv(10), actual: tv("abc")))
    }

    @Test("Equals with an array expected and no match returns false")
    func equalsArrayExpectedNoMatch() {
        #expect(!CTTriggerEvaluator.evaluate(equals, expected: tv(["a", "b"]), actual: tv("c")))
    }

    @Test("Contains with an array expected and no match returns false")
    func containsArrayExpectedNoMatch() {
        #expect(!CTTriggerEvaluator.evaluate(contains, expected: tv(["foo", "bar"]), actual: tv("zzz")))
    }

    @Test("Between with a single-element range returns false")
    func betweenSingleElementRange() {
        #expect(!CTTriggerEvaluator.evaluate(between, expected: tv([10]), actual: tv(15)))
    }

    @Test("Between with string bounds returns true")
    func betweenStringBounds() {
        #expect(CTTriggerEvaluator.evaluate(between, expected: tv(["10", "20"]), actual: tv(15)))
    }

    // MARK: - evaluateDistance

    @Test("evaluateDistance within the radius returns true")
    func evaluateDistanceWithinRadius() {
        let coord = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
        #expect(CTTriggerEvaluator.evaluateDistance(NSNumber(value: 1000), expected: coord, actual: coord))
    }

    @Test("evaluateDistance outside the radius returns false")
    func evaluateDistanceOutsideRadius() {
        let bangalore = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)
        let mumbai = CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)
        #expect(!CTTriggerEvaluator.evaluateDistance(NSNumber(value: 100), expected: bangalore, actual: mumbai))
    }
}
