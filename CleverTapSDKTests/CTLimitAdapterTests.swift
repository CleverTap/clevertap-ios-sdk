// CTLimitAdapterTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTLimitAdapter — mirrors CTLimitAdapterTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTLimitAdapter is a stateless JSON wrapper (no shared/global state), so the suite
// needs neither .serialized nor an init() fixture — a fresh instance per @Test is
// sufficient. The header is NS_ASSUME_NONNULL, so initWithJSON: imports as a
// non-optional [AnyHashable: Any] parameter and the accessor methods import as
// non-optional returns.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTLimitAdapter")
struct CTLimitAdapterTests {

    // MARK: - limitType enum mappings

    @Test("limitType ever")
    func limitTypeEver() {
        let a = CTLimitAdapter(json: ["type": "ever"])
        #expect(a.limitType() == .ever)
    }

    @Test("limitType session")
    func limitTypeSession() {
        let a = CTLimitAdapter(json: ["type": "session"])
        #expect(a.limitType() == .session)
    }

    @Test("limitType seconds")
    func limitTypeSeconds() {
        let a = CTLimitAdapter(json: ["type": "seconds"])
        #expect(a.limitType() == .seconds)
    }

    @Test("limitType minutes")
    func limitTypeMinutes() {
        let a = CTLimitAdapter(json: ["type": "minutes"])
        #expect(a.limitType() == .minutes)
    }

    @Test("limitType hours")
    func limitTypeHours() {
        let a = CTLimitAdapter(json: ["type": "hours"])
        #expect(a.limitType() == .hours)
    }

    @Test("limitType days")
    func limitTypeDays() {
        let a = CTLimitAdapter(json: ["type": "days"])
        #expect(a.limitType() == .days)
    }

    @Test("limitType weeks")
    func limitTypeWeeks() {
        let a = CTLimitAdapter(json: ["type": "weeks"])
        #expect(a.limitType() == .weeks)
    }

    @Test("limitType onEvery")
    func limitTypeOnEvery() {
        let a = CTLimitAdapter(json: ["type": "onEvery"])
        #expect(a.limitType() == .onEvery)
    }

    @Test("limitType onExactly")
    func limitTypeOnExactly() {
        let a = CTLimitAdapter(json: ["type": "onExactly"])
        #expect(a.limitType() == .onExactly)
    }

    @Test("limitType unknown defaults to ever")
    func limitTypeUnknownDefaultsToEver() {
        let a = CTLimitAdapter(json: ["type": "unknownType"])
        #expect(a.limitType() == .ever)
    }

    @Test("limitType missing key defaults to ever")
    func limitTypeMissingKeyDefaultsToEver() {
        let a = CTLimitAdapter(json: [:])
        #expect(a.limitType() == .ever)
    }

    // MARK: - limit and frequency

    @Test("limit returns integer value")
    func limitReturnsIntegerValue() {
        let a = CTLimitAdapter(json: ["type": "ever", "limit": 5])
        #expect(a.limit() == 5)
    }

    @Test("limit missing key returns zero")
    func limitMissingKeyReturnsZero() {
        let a = CTLimitAdapter(json: ["type": "ever"])
        #expect(a.limit() == 0)
    }

    @Test("frequency returns integer value")
    func frequencyReturnsIntegerValue() {
        let a = CTLimitAdapter(json: ["type": "seconds", "frequency": 30])
        #expect(a.frequency() == 30)
    }

    @Test("frequency missing key returns zero")
    func frequencyMissingKeyReturnsZero() {
        let a = CTLimitAdapter(json: ["type": "seconds"])
        #expect(a.frequency() == 0)
    }

    // MARK: - isEmpty

    @Test("isEmpty empty dict returns true")
    func isEmptyEmptyDictReturnsTrue() {
        let a = CTLimitAdapter(json: [:])
        #expect(a.isEmpty())
    }

    @Test("isEmpty with data returns false")
    func isEmptyWithDataReturnsFalse() {
        let a = CTLimitAdapter(json: ["type": "ever"])
        #expect(!a.isEmpty())
    }
}
