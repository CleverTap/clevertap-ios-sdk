// CTInActionResultTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTInActionResult — mirrors CTInActionResultTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTInActionResult is an immutable value type with no shared/global state, so the
// suite needs neither .serialized nor an init() fixture — a fresh struct instance
// per @Test is sufficient. The header is NS_ASSUME_NONNULL, so the factory methods
// import as non-optional and need no #require unwrapping.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTInActionResult")
struct CTInActionResultTests {

    @Test("readyToFetch sets type, id and data")
    func readyToFetchSetsTypeIdAndData() {
        let data = ["key": "value"]
        let result = CTInActionResult.readyToFetch(withId: "action1", data: data)
        #expect(result.type == .readyToFetch)
        #expect(result.inActionId == "action1")
        #expect(result.data as? [String: String] == data)
        #expect(result.message == nil)
    }

    @Test("error sets type, id and message")
    func errorSetsTypeIdAndMessage() {
        let result = CTInActionResult.error(withId: "action2", message: "something failed")
        #expect(result.type == .error)
        #expect(result.inActionId == "action2")
        #expect(result.message == "something failed")
        #expect(result.data == nil)
    }

    @Test("cancelled sets type, id and message")
    func cancelledSetsTypeIdAndMessage() {
        let result = CTInActionResult.cancelled(withId: "action3", message: "cancelled by user")
        #expect(result.type == .cancelled)
        #expect(result.inActionId == "action3")
        #expect(result.message == "cancelled by user")
        #expect(result.data == nil)
    }

    @Test("discarded sets type, id and message")
    func discardedSetsTypeIdAndMessage() {
        let result = CTInActionResult.discarded(withId: "action4", message: "discarded reason")
        #expect(result.type == .discarded)
        #expect(result.inActionId == "action4")
        #expect(result.message == "discarded reason")
        #expect(result.data == nil)
    }

    @Test("each call creates an independent instance")
    func eachCallCreatesIndependentInstance() {
        let first = CTInActionResult.readyToFetch(withId: "id-a", data: ["k": "a"])
        let second = CTInActionResult.readyToFetch(withId: "id-b", data: ["k": "b"])
        #expect(first !== second)
        #expect(first.inActionId == "id-a")
        #expect(second.inActionId == "id-b")
        #expect(first.data as? [String: String] == ["k": "a"])
        #expect(second.data as? [String: String] == ["k": "b"])
    }
}
