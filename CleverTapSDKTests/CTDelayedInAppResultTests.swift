// CTDelayedInAppResultTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTDelayedInAppResult — mirrors the original CTDelayedInAppResultTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTDelayedInAppResult is an immutable value type with no shared/global state, so the
// suite needs neither .serialized nor an init() fixture — a fresh struct instance
// per @Test is sufficient. The Swift factory methods return non-optional instances
// (the accidental `_Nullable` from the ObjC header was dropped in the migration), so
// no #require unwrapping is needed.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTDelayedInAppResult")
struct CTDelayedInAppResultTests {

    @Test("success sets type, id and data")
    func successSetsTypeIdAndData() {
        let data = ["k": "v"]
        let result = CTDelayedInAppResult.success(withId: "id1", data: data)
        #expect(result.type == .success)
        #expect(result.resultId == "id1")
        #expect(result.data as? [String: String] == data)
        #expect(result.exception == nil)
        #expect(result.message == nil)
    }

    @Test("success with nil data leaves data nil")
    func successWithNilDataSetsNilData() {
        let result = CTDelayedInAppResult.success(withId: "id1", data: nil)
        #expect(result.type == .success)
        #expect(result.data == nil)
    }

    @Test("error sets type, id, reason and exception")
    func errorSetsTypeReasonAndException() {
        let error = NSError(domain: "TestDomain", code: 42, userInfo: nil)
        let result = CTDelayedInAppResult.error(withId: "id2", reason: .dataNotFound, exception: error)
        #expect(result.type == .error)
        #expect(result.resultId == "id2")
        #expect(result.reason == .dataNotFound)
        #expect(result.exception != nil)
        #expect(result.exception?.code == 42)
    }

    @Test("error with nil exception leaves exception nil")
    func errorWithNilExceptionSetsNilException() {
        let result = CTDelayedInAppResult.error(withId: "id2", reason: .unknown, exception: nil)
        #expect(result.type == .error)
        #expect(result.reason == .unknown)
        #expect(result.exception == nil)
    }

    @Test("discarded sets type, id and message")
    func discardedSetsTypeIdAndMessage() {
        let result = CTDelayedInAppResult.discarded(withId: "id3", message: "some reason")
        #expect(result.type == .discarded)
        #expect(result.resultId == "id3")
        #expect(result.message == "some reason")
        #expect(result.exception == nil)
        #expect(result.data == nil)
    }

    @Test("discarded with nil message leaves message nil")
    func discardedWithNilMessageSetsNilMessage() {
        let result = CTDelayedInAppResult.discarded(withId: "id3", message: nil)
        #expect(result.type == .discarded)
        #expect(result.message == nil)
    }

    // MARK: - Coverage gaps added in Step 1 (default reasons, unused enum case, instance identity)

    @Test("success defaults reason to unknown")
    func successDefaultsReasonToUnknown() {
        let result = CTDelayedInAppResult.success(withId: "id1", data: ["k": "v"])
        #expect(result.reason == .unknown)
    }

    @Test("error leaves data and message nil")
    func errorSetsNilDataAndMessage() {
        let error = NSError(domain: "TestDomain", code: 7, userInfo: nil)
        let result = CTDelayedInAppResult.error(withId: "id2", reason: .dataNotFound, exception: error)
        #expect(result.data == nil)
        #expect(result.message == nil)
    }

    @Test("error with preparationFailed reason")
    func errorWithPreparationFailedReason() {
        let result = CTDelayedInAppResult.error(withId: "id2", reason: .preparationFailed, exception: nil)
        #expect(result.type == .error)
        #expect(result.reason == .preparationFailed)
    }

    @Test("discarded defaults reason to unknown")
    func discardedDefaultsReasonToUnknown() {
        let result = CTDelayedInAppResult.discarded(withId: "id3", message: "some reason")
        #expect(result.reason == .unknown)
    }

    @Test("each call creates an independent instance")
    func eachCallCreatesIndependentInstance() {
        let first = CTDelayedInAppResult.success(withId: "id-a", data: ["k": "a"])
        let second = CTDelayedInAppResult.success(withId: "id-b", data: ["k": "b"])
        #expect(first !== second)
        #expect(first.resultId == "id-a")
        #expect(second.resultId == "id-b")
        #expect(first.data as? [String: String] == ["k": "a"])
        #expect(second.data as? [String: String] == ["k": "b"])
    }
}
