// CleverTapDefineVarPrimitiveTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for the primitive-typed defineVar(...) wrappers on
// CleverTap that were previously uncovered. Each wrapper just boxes a C
// primitive into an NSNumber and registers a Var, so the test defines one and
// reads the value back through the matching typed accessor.
//
// Follows the same pattern as CTSessionManagerTests.swift: a struct-based
// @Suite (fresh instance per @Test) with a single shared CleverTap instance so
// the SDK is initialised once for the whole run.

import Testing
import CoreGraphics
@testable import CleverTapSDK

@Suite("CleverTap defineVar primitive wrappers", .serialized)
struct CleverTapDefineVarPrimitiveTests {

    // Created once for the whole run; defineVar only touches the local Var
    // cache, so no network/launch is required.
    private static let sharedInstance: CleverTap = {
        let cfg = CleverTapInstanceConfig(accountId: "testSwiftVars", accountToken: "testSwiftVars")
        return CleverTap.instance(with: cfg)
    }()

    let instance: CleverTap

    init() {
        instance = Self.sharedInstance
    }

    @Test("defineVar withCGFloat stores the value")
    func cgFloat() {
        let v = instance.defineVar(name: "CT_Var_CGFloat", cgFloat: 2.5)
        #expect(abs(v.cgFloatValue() - 2.5) < 1e-6)
    }

    @Test("defineVar withShort stores the value")
    func short() {
        let v = instance.defineVar(name: "CT_Var_Short", short: 5)
        #expect(v.shortValue() == 5)
    }

    @Test("defineVar withLong stores the value")
    func long() {
        let v = instance.defineVar(name: "CT_Var_Long", long: 7)
        #expect(v.longValue() == 7)
    }

    @Test("defineVar withLongLong stores the value")
    func longLong() {
        let v = instance.defineVar(name: "CT_Var_LongLong", longLong: 9)
        #expect(v.longLongValue() == 9)
    }

    @Test("defineVar withUnsignedChar stores the value")
    func unsignedChar() {
        let v = instance.defineVar(name: "CT_Var_UnsignedChar", unsignedChar: 3)
        #expect(v.unsignedCharValue() == 3)
    }

    @Test("defineVar withUnsignedInt stores the value")
    func unsignedInt() {
        let v = instance.defineVar(name: "CT_Var_UnsignedInt", unsignedInt: 11)
        #expect(v.unsignedIntValue() == 11)
    }

    @Test("defineVar withUnsignedInteger stores the value")
    func unsignedInteger() {
        let v = instance.defineVar(name: "CT_Var_UnsignedInteger", unsignedInteger: 13)
        #expect(v.unsignedIntegerValue() == 13)
    }

    @Test("defineVar withUnsignedLong stores the value")
    func unsignedLong() {
        let v = instance.defineVar(name: "CT_Var_UnsignedLong", unsignedLong: 15)
        #expect(v.unsignedLongValue() == 15)
    }

    @Test("defineVar withUnsignedLongLong stores the value")
    func unsignedLongLong() {
        let v = instance.defineVar(name: "CT_Var_UnsignedLongLong", unsignedLongLong: 17)
        #expect(v.unsignedLongLongValue() == 17)
    }

    @Test("defineVar withUnsignedShort stores the value")
    func unsignedShort() {
        // NS_SWIFT_NAME in CleverTap+CTVar.h spells this argument with a
        // capital U (defineVar(name:UnsignedShort:)); match it verbatim.
        let v = instance.defineVar(name: "CT_Var_UnsignedShort", UnsignedShort: 19)
        #expect(v.unsignedShortValue() == 19)
    }

    // getInstances is declared in CleverTapInternal.h (exposed to Swift via the
    // test bridging header), so it is one of the few internal CleverTap methods
    // reachable from the Swift suite. Creating sharedInstance above registers it.
    @Test("getInstances returns the registered instances")
    func getInstances() {
        let instances = CleverTap.getInstances()
        #expect(instances != nil)
        #expect((instances?.count ?? 0) > 0)
    }
}
