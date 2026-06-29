// CTTimerResultTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTTimerResult (migrated from CTTimerResultTest.m).
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTTimerResult is an immutable value type with no shared/global state, so the
// suite needs neither .serialized nor an init() fixture — a fresh struct
// instance per @Test is sufficient.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTTimerResult")
struct CTTimerResultTests {

    @Test("completed sets type, id and scheduledAt")
    func completedSetsTypeIdAndScheduledAt() {
        let result = CTTimerResult.completed(withId: "id1", scheduledAt: 42.0)
        #expect(result.type == .completed)
        #expect(result.resultId == "id1")
        #expect(result.scheduledAt == 42.0)
        #expect(result.exception == nil)
    }

    @Test("error sets type, id and exception")
    func errorSetsTypeIdAndException() {
        let error = NSError(domain: "TestDomain", code: 99, userInfo: nil)
        let result = CTTimerResult.error(withId: "id2", exception: error)
        #expect(result.type == .error)
        #expect(result.resultId == "id2")
        #expect(result.exception != nil)
        #expect(result.exception?.code == 99)
    }

    @Test("error with nil exception leaves exception nil and scheduledAt zero")
    func errorWithNilExceptionSetsNilException() {
        let result = CTTimerResult.error(withId: "id2", exception: nil)
        #expect(result.type == .error)
        #expect(result.exception == nil)
        #expect(result.scheduledAt == 0.0)
    }

    @Test("discarded sets type and id")
    func discardedSetsTypeAndId() {
        let result = CTTimerResult.discarded(withId: "id3")
        #expect(result.type == .discarded)
        #expect(result.resultId == "id3")
        #expect(result.exception == nil)
        #expect(result.scheduledAt == 0.0)
    }

    @Test("each call creates an independent instance")
    func eachCallCreatesIndependentInstance() {
        let first = CTTimerResult.completed(withId: "id-a", scheduledAt: 1.0)
        let second = CTTimerResult.completed(withId: "id-b", scheduledAt: 2.0)
        #expect(first !== second)
        #expect(first.resultId == "id-a")
        #expect(second.resultId == "id-b")
        #expect(first.scheduledAt == 1.0)
        #expect(second.scheduledAt == 2.0)
    }
}
