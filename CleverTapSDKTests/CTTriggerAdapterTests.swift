// CTTriggerAdapterTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTTriggerAdapter — mirrors CTTriggerAdapterTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTTriggerAdapter is still Objective-C at this point (Phase 1 runs these tests against the
// existing ObjC source). It wraps a trigger JSON dictionary and exposes the event name,
// profile attribute, first-time flag, and lazily-built CTTriggerCondition / CTTriggerRadius
// views over the eventProperties / itemProperties / geoRadius arrays.
//
// Operator codes (CTTriggerOperator, raw): GreaterThan = 0, Equals = 1. `op` is stored as a
// raw UInt on CTTriggerCondition, so tests compare against the numeric code directly.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTTriggerAdapter")
struct CTTriggerAdapterTests {

    // MARK: - eventName / profileAttrName / firstTimeOnly

    @Test("initWithJSON sets eventName")
    func initSetsEventName() {
        let adapter = CTTriggerAdapter(json: ["eventName": "Purchase"])
        #expect(adapter.eventName == "Purchase")
    }

    @Test("profileAttrName is set from JSON")
    func profileAttrNameSetFromJSON() {
        let adapter = CTTriggerAdapter(json: ["profileAttrName": "age"])
        #expect(adapter.profileAttrName == "age")
    }

    @Test("firstTimeOnly is set from JSON")
    func firstTimeOnlySetFromJSON() {
        let adapter = CTTriggerAdapter(json: ["firstTimeOnly": true])
        #expect(adapter.firstTimeOnly == true)
    }

    // Backend sends a boolean (true/false); 0/1 are accepted too. These read the real value via
    // NSNumber.boolValue — the migration fixed the former pointer-to-BOOL bug that read truthy
    // for any present key.
    @Test("firstTimeOnly false reads false")
    func firstTimeOnlyFalseReadsFalse() {
        let adapter = CTTriggerAdapter(json: ["firstTimeOnly": false])
        #expect(adapter.firstTimeOnly == false)
    }

    @Test("firstTimeOnly numeric 1 reads true")
    func firstTimeOnlyOneReadsTrue() {
        let adapter = CTTriggerAdapter(json: ["firstTimeOnly": 1])
        #expect(adapter.firstTimeOnly == true)
    }

    @Test("firstTimeOnly numeric 0 reads false")
    func firstTimeOnlyZeroReadsFalse() {
        let adapter = CTTriggerAdapter(json: ["firstTimeOnly": 0])
        #expect(adapter.firstTimeOnly == false)
    }

    @Test("firstTimeOnly absent defaults to false")
    func firstTimeOnlyAbsentDefaultsFalse() {
        let adapter = CTTriggerAdapter(json: [:])
        #expect(adapter.firstTimeOnly == false)
    }

    // MARK: - propertyCount

    @Test("propertyCount with nil properties returns zero")
    func propertyCountNilReturnsZero() {
        let adapter = CTTriggerAdapter(json: ["eventName": "Viewed"])
        #expect(adapter.propertyCount == 0)
    }

    @Test("propertyCount with properties returns count")
    func propertyCountReturnsCount() {
        let json: [String: Any] = [
            "eventName": "Viewed",
            "eventProperties": [
                ["propertyName": "category", "operator": 1, "propertyValue": "shoes"],
                ["propertyName": "price", "operator": 0, "propertyValue": 50]
            ]
        ]
        let adapter = CTTriggerAdapter(json: json)
        #expect(adapter.propertyCount == 2)
    }

    // MARK: - itemsCount

    @Test("itemsCount with nil items returns zero")
    func itemsCountNilReturnsZero() {
        let adapter = CTTriggerAdapter(json: [:])
        #expect(adapter.itemsCount == 0)
    }

    @Test("itemsCount with items returns count")
    func itemsCountReturnsCount() {
        let json: [String: Any] = [
            "itemProperties": [
                ["propertyName": "color", "operator": 1, "propertyValue": "red"]
            ]
        ]
        let adapter = CTTriggerAdapter(json: json)
        #expect(adapter.itemsCount == 1)
    }

    // MARK: - geoRadiusCount

    @Test("geoRadiusCount with nil geoRadius returns zero")
    func geoRadiusCountNilReturnsZero() {
        let adapter = CTTriggerAdapter(json: [:])
        #expect(adapter.geoRadiusCount == 0)
    }

    @Test("geoRadiusCount with geoRadius returns count")
    func geoRadiusCountReturnsCount() {
        let json: [String: Any] = [
            "geoRadius": [
                ["lat": 12.9, "lng": 77.6, "rad": 500]
            ]
        ]
        let adapter = CTTriggerAdapter(json: json)
        #expect(adapter.geoRadiusCount == 1)
    }

    // MARK: - propertyAtIndex

    @Test("propertyAtIndex returns the correct condition")
    func propertyAtIndexReturnsCondition() throws {
        let json: [String: Any] = [
            "eventProperties": [
                ["propertyName": "age", "operator": 1, "propertyValue": 30]
            ]
        ]
        let adapter = CTTriggerAdapter(json: json)
        let cond = try #require(adapter.property(at: 0))
        #expect(cond.propertyName == "age")
        #expect(cond.op == 1) // Equals
        #expect(cond.value.numberValue == NSNumber(value: 30))
    }

    @Test("propertyAtIndex with nil properties returns nil")
    func propertyAtIndexNilReturnsNil() {
        let adapter = CTTriggerAdapter(json: [:])
        #expect(adapter.property(at: 0) == nil)
    }

    // MARK: - itemAtIndex

    @Test("itemAtIndex returns the correct condition")
    func itemAtIndexReturnsCondition() throws {
        let json: [String: Any] = [
            "itemProperties": [
                ["propertyName": "color", "operator": 1, "propertyValue": "red"]
            ]
        ]
        let adapter = CTTriggerAdapter(json: json)
        let item = try #require(adapter.item(at: 0))
        #expect(item.propertyName == "color")
        #expect(item.op == 1) // Equals
        #expect(item.value.stringValue == "red")
    }

    @Test("itemAtIndex with nil items returns nil")
    func itemAtIndexNilReturnsNil() {
        let adapter = CTTriggerAdapter(json: [:])
        #expect(adapter.item(at: 0) == nil)
    }

    // MARK: - operator parsing

    @Test("propertyAtIndex with a missing operator defaults to Equals")
    func propertyAtIndexMissingOperatorDefaultsToEquals() throws {
        let json: [String: Any] = [
            "eventProperties": [
                ["propertyName": "age", "propertyValue": 30]
            ]
        ]
        let adapter = CTTriggerAdapter(json: json)
        let cond = try #require(adapter.property(at: 0))
        #expect(cond.op == 1) // Equals (default when operator is absent/non-numeric)
    }

    // MARK: - geoRadiusAtIndex

    @Test("geoRadiusAtIndex returns lat / lon / radius")
    func geoRadiusAtIndexReturnsValues() throws {
        let json: [String: Any] = [
            "geoRadius": [
                ["lat": 12.9716, "lng": 77.5946, "rad": 1000]
            ]
        ]
        let adapter = CTTriggerAdapter(json: json)
        let geo = try #require(adapter.geoRadius(at: 0))
        #expect(geo.latitude == NSNumber(value: 12.9716))
        #expect(geo.longitude == NSNumber(value: 77.5946))
        #expect(geo.radius == NSNumber(value: 1000))
    }

    @Test("geoRadiusAtIndex with nil geoRadius returns nil")
    func geoRadiusAtIndexNilReturnsNil() {
        let adapter = CTTriggerAdapter(json: [:])
        #expect(adapter.geoRadius(at: 0) == nil)
    }
}
