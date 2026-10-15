// CTFlattenedEventDataTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTFlattenedEventData — mirrors CTFlattenedEventDataTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTFlattenedEventData is an immutable value type with factory initialisers. The header is
// NS_ASSUME_NONNULL, so the factories import as non-optional and the dictionary accessors
// import as optional ([AnyHashable: Any]?). `noData` is a shared singleton (dispatch_once),
// so its identity is checked with `===`. A fresh @Test instance per test is sufficient
// (no shared mutable state beyond the noData singleton, which is intentionally shared).

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTFlattenedEventData")
struct CTFlattenedEventDataTests {

    // MARK: - profileChanges factory

    @Test("profileChanges sets correct type")
    func profileChangesSetsCorrectType() {
        let event = CTFlattenedEventData.profileChanges(["Name": "Alice"])
        #expect(event.type == .profileChanges)
    }

    @Test("profileChanges returns input dictionary")
    func profileChangesReturnsInputDictionary() {
        let changes = ["Name": "Alice", "Age": "30"]
        let event = CTFlattenedEventData.profileChanges(changes)
        #expect(event.profileChanges() as? [String: String] == changes)
    }

    @Test("profileChanges: eventProperties returns nil")
    func profileChangesEventPropertiesReturnsNil() {
        let event = CTFlattenedEventData.profileChanges(["Name": "Alice"])
        #expect(event.eventProperties() == nil)
    }

    // MARK: - eventProperties factory

    @Test("eventProperties sets correct type")
    func eventPropertiesSetsCorrectType() {
        let event = CTFlattenedEventData.eventProperties(["key": "value"])
        #expect(event.type == .eventProperties)
    }

    @Test("eventProperties returns input dictionary")
    func eventPropertiesReturnsInputDictionary() {
        let props = ["event_key": "event_value"]
        let event = CTFlattenedEventData.eventProperties(props)
        #expect(event.eventProperties() as? [String: String] == props)
    }

    @Test("eventProperties: profileChanges returns nil")
    func eventPropertiesProfileChangesReturnsNil() {
        let event = CTFlattenedEventData.eventProperties(["key": "value"])
        #expect(event.profileChanges() == nil)
    }

    // MARK: - noData factory

    @Test("noData sets correct type")
    func noDataSetsCorrectType() {
        let event = CTFlattenedEventData.noData()
        #expect(event.type == .noData)
    }

    @Test("noData returns singleton instance")
    func noDataReturnsSingletonInstance() {
        let first = CTFlattenedEventData.noData()
        let second = CTFlattenedEventData.noData()
        #expect(first === second)
    }

    @Test("noData accessors return nil")
    func noDataAccessorsReturnNil() {
        let event = CTFlattenedEventData.noData()
        #expect(event.profileChanges() == nil)
        #expect(event.eventProperties() == nil)
    }

    // MARK: - defensive copy

    @Test("profileChanges copies input")
    func profileChangesCopiesInput() {
        let changes = NSMutableDictionary(dictionary: ["Name": "Alice"])
        let event = CTFlattenedEventData.profileChanges(changes as! [String: Any])
        changes["Name"] = "Bob" // mutate caller's dict after creation
        #expect(event.profileChanges() as? [String: String] == ["Name": "Alice"])
    }
}
