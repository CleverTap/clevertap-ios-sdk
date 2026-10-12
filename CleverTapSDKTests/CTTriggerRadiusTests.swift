// CTTriggerRadiusTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTTriggerRadius — mirrors CTTriggerRadiusTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTTriggerRadius is a plain data holder (no shared/global state), so the suite needs
// neither .serialized nor an init() fixture — a fresh instance per @Test is sufficient.
//
// The Swift class declares the three properties as optional (NSNumber?), fixing the
// original ObjC nonnull-but-nil-default nullability mismatch, so the default-nil
// assertions use plain `== nil`.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTTriggerRadius")
struct CTTriggerRadiusTests {

    // MARK: - default state

    @Test("init leaves all properties nil")
    func initPropertiesAreNil() {
        let radius = CTTriggerRadius()
        #expect(radius.latitude == nil)
        #expect(radius.longitude == nil)
        #expect(radius.radius == nil)
    }

    // MARK: - property round-trips

    @Test("latitude set/get")
    func latitudeSetGet() {
        let radius = CTTriggerRadius()
        radius.latitude = NSNumber(value: 12.9716)
        #expect(radius.latitude == NSNumber(value: 12.9716))
    }

    @Test("longitude set/get")
    func longitudeSetGet() {
        let radius = CTTriggerRadius()
        radius.longitude = NSNumber(value: 77.5946)
        #expect(radius.longitude == NSNumber(value: 77.5946))
    }

    @Test("radius set/get")
    func radiusSetGet() {
        let radius = CTTriggerRadius()
        radius.radius = NSNumber(value: 1000)
        #expect(radius.radius == NSNumber(value: 1000))
    }

    @Test("all properties set/get")
    func allPropertiesSetGet() {
        let radius = CTTriggerRadius()
        radius.latitude = NSNumber(value: 12.9716)
        radius.longitude = NSNumber(value: 77.5946)
        radius.radius = NSNumber(value: 1000)
        #expect(radius.latitude == NSNumber(value: 12.9716))
        #expect(radius.longitude == NSNumber(value: 77.5946))
        #expect(radius.radius == NSNumber(value: 1000))
    }
}
