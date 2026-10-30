// CTEventAdapterTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTEventAdapter — mirrors CTEventAdapterTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTEventAdapter is still Objective-C at this point (Phase 1 runs these tests against the
// existing ObjC source). It wraps a fired event (name, properties, items, location, optional
// profile attribute) and resolves property / item values by name with CleverTap's name
// normalization + system-property aliasing.
//
// The CLTAP_* keys below are `#define` string macros in CTConstants.h — invisible to Swift — so
// their literal values are inlined here (constant name noted in a comment), the same way the
// operator-code suites inline their raw values.

import Testing
import Foundation
import CoreLocation
@testable import CleverTapSDK

@Suite("CTEventAdapter")
struct CTEventAdapterTests {

    // #define string constants from CTConstants.h (Swift can't see the macros).
    private let wzrkId = "wzrk_id"          // CLTAP_PROP_WZRK_ID
    private let campaignId = "Campaign id"  // CLTAP_PROP_CAMPAIGN_ID
    private let variant = "Variant"         // CLTAP_PROP_VARIANT
    private let wzrkPivot = "wzrk_pivot"    // CLTAP_PROP_WZRK_PIVOT
    private let appVersion = "Version"      // CLTAP_APP_VERSION
    private let sdkVersion = "SDK Version"  // CLTAP_SDK_VERSION

    // MARK: - Helpers (mirror the ObjC test's eventAdapterWith… factory methods)

    private func eventAdapter(properties: [AnyHashable: Any]) -> CTEventAdapter {
        CTEventAdapter(eventName: "event", eventProperties: properties as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
    }

    private func eventAdapter(items: [[AnyHashable: Any]]) -> CTEventAdapter {
        CTEventAdapter(eventName: "event", eventProperties: NSDictionary(), location: kCLLocationCoordinate2DInvalid, andItems: items)
    }

    // MARK: - propertyValueNamed

    @Test("propertyValueNamed resolves direct, trimmed, cased, and fuzzy-normalized keys")
    func propertyValueNamed() throws {
        let value = "value"
        var props: [AnyHashable: Any] = ["prop1": value]
        var adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed("prop1")?.stringValue == value)
        #expect(adapter.propertyValueNamed(" prop 1 ")?.stringValue == value)
        #expect(adapter.propertyValueNamed("Prop1")?.stringValue == value)
        #expect(adapter.propertyValueNamed("Prop 1")?.stringValue == value)
        #expect(adapter.propertyValueNamed("Prop 1 1") == nil)

        props = ["prop 1": value]
        adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed("prop1")?.stringValue == value)
        #expect(adapter.propertyValueNamed(" prop 1 ")?.stringValue == value)
        #expect(adapter.propertyValueNamed("Prop1")?.stringValue == value)
        #expect(adapter.propertyValueNamed("Prop 1")?.stringValue == value)

        props = ["prop 1": "value1", "prop1": value, "Prop 1": "value2"]
        adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed("prop1")?.stringValue == value)
        #expect(adapter.propertyValueNamed("Prop 1")?.stringValue == "value2")
        // " prop  1" normalizes to "prop1", which matches all three keys — any of their values is valid.
        let v1 = try #require(adapter.propertyValueNamed(" prop  1")?.stringValue)
        #expect([value, "value1", "value2"].contains(v1))

        props = ["prop 1": "value1", "prop  1": "value2", "Prop 1": "value3"]
        adapter = eventAdapter(properties: props)
        // "prop1" normalizes to "prop1", which matches all three keys — any of their values is valid.
        let v2 = try #require(adapter.propertyValueNamed("prop1")?.stringValue)
        #expect(["value1", "value2", "value3"].contains(v2))
    }

    // MARK: - system property aliasing

    @Test("system property aliasing: campaign/wzrk_id, variant/wzrk_pivot, app-field mapping")
    func systemPropertyValueNamed() {
        var props: [AnyHashable: Any] = [
            wzrkId: "wzrk_id value",
            appVersion: "Version value",
            sdkVersion: "SDK Version value"
        ]
        var adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed(campaignId)?.stringValue == "wzrk_id value")
        #expect(adapter.propertyValueNamed("CT App Version")?.stringValue == "Version value")
        #expect(adapter.propertyValueNamed("CT SDK Version")?.stringValue == "SDK Version value")

        props = [campaignId: "Campaign id value"]
        adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed(wzrkId)?.stringValue == "Campaign id value")

        props = [variant: "Variant value"]
        adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed(wzrkPivot)?.stringValue == "Variant value")

        props = [wzrkPivot: "wzrk_pivot value"]
        adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed(variant)?.stringValue == "wzrk_pivot value")
    }

    @Test("system property names require an exact match, but normalize against the event-property keys")
    func systemPropertyValueNamedNormalized() {
        var props: [AnyHashable: Any] = [wzrkId: "wzrk_id value", appVersion: "Version value"]
        var adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed(campaignId)?.stringValue == "wzrk_id value")
        #expect(adapter.propertyValueNamed("CT App Version")?.stringValue == "Version value")
        // The system property names must be an exact match.
        #expect(adapter.propertyValueNamed(campaignId.lowercased()) == nil)
        #expect(adapter.propertyValueNamed("CT App Version".lowercased()) == nil)
        #expect(adapter.propertyValueNamed("CTApp Version") == nil)

        // The property name is normalized if it matches the evaluated system property name.
        props = ["wzrk_ID": "wzrk_id value", "version": "Version value"]
        adapter = eventAdapter(properties: props)
        #expect(adapter.propertyValueNamed(campaignId)?.stringValue == "wzrk_id value")
        #expect(adapter.propertyValueNamed("CT App Version")?.stringValue == "Version value")
    }

    // MARK: - itemValueNamed

    @Test("itemValueNamed collects matching item values; nil for no match or no items")
    func itemValueNamed() {
        let items: [[AnyHashable: Any]] = [
            ["productName": "product 1", "price": 5.99],
            ["productName": "product 2", "price": 5.50]
        ]
        let adapter = eventAdapter(items: items)
        #expect(adapter.itemValueNamed("productName")?.arrayValue as? [String] == ["product 1", "product 2"])
        #expect(adapter.itemValueNamed("price")?.arrayValue as? [NSNumber] == [NSNumber(value: 5.99), NSNumber(value: 5.50)])
        #expect(adapter.itemValueNamed("none") == nil)

        // No items. Swift can't pass nil to the nonnull andItems:; an empty array yields the same
        // nil result. The ObjC suite covers the literal-nil path.
        let emptyAdapter = eventAdapter(items: [])
        #expect(emptyAdapter.itemValueNamed("none") == nil)
    }

    @Test("itemValueNamed normalizes the looked-up name")
    func itemValueNamedNormalized() {
        let items: [[AnyHashable: Any]] = [["productName": "product 1"], ["productName": "product 2"]]
        let expected = ["product 1", "product 2"]
        let adapter = eventAdapter(items: items)
        #expect(adapter.itemValueNamed("productName")?.arrayValue as? [String] == expected)
        #expect(adapter.itemValueNamed("ProductName")?.arrayValue as? [String] == expected)
        #expect(adapter.itemValueNamed("product Name")?.arrayValue as? [String] == expected)
        #expect(adapter.itemValueNamed("Product Name")?.arrayValue as? [String] == expected)
    }

    @Test("itemValueNamed normalizes the item keys too")
    func itemValueNamedNormalizedItem() {
        let items: [[AnyHashable: Any]] = [
            ["product Name": "product 1"],
            ["ProductName": "product 2"],
            ["Product Name": "product 3"],
            ["product name": "product 4"],
            ["product_name": "product 5"]
        ]
        let expected = ["product 1", "product 2", "product 3", "product 4"]
        let adapter = eventAdapter(items: items)
        #expect(adapter.itemValueNamed("productName")?.arrayValue as? [String] == expected)
        #expect(adapter.itemValueNamed("ProductName")?.arrayValue as? [String] == expected)
        #expect(adapter.itemValueNamed("product Name")?.arrayValue as? [String] == expected)
        #expect(adapter.itemValueNamed("Product Name")?.arrayValue as? [String] == expected)
        #expect(adapter.itemValueNamed("product_name")?.arrayValue as? [String] == ["product 5"])
        #expect(adapter.itemValueNamed("Product_Name")?.arrayValue as? [String] == ["product 5"])
    }

    // MARK: - initializers

    @Test("init sets eventName and eventProperties")
    func initSetsEventNameAndProperties() {
        let props: [AnyHashable: Any] = ["prop1": "value"]
        let adapter = eventAdapter(properties: props)
        #expect(adapter.eventName == "event")
        #expect((adapter.eventProperties as? [String: String]) == ["prop1": "value"])
        // profileAttrName is not read here: the public header types it nonnull but it is nil for
        // this initializer, so reading it from Swift would trap. The ObjC suite asserts it is nil.
    }

    @Test("init sets the location")
    func initSetsLocation() {
        let loc = CLLocationCoordinate2D(latitude: 12.97, longitude: 77.59)
        let adapter = CTEventAdapter(eventName: "event", eventProperties: NSDictionary(), andLocation: loc)
        #expect(adapter.location.latitude == 12.97)
        #expect(adapter.location.longitude == 77.59)
    }

    @Test("profileAttrName initializer sets eventName, profileAttrName, and properties")
    func initWithProfileAttrName() {
        let props: [AnyHashable: Any] = ["prop1": "value"]
        let adapter = CTEventAdapter(eventName: "event", profileAttrName: "age", eventProperties: props as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
        #expect(adapter.eventName == "event")
        #expect(adapter.profileAttrName == "age")
        #expect(adapter.propertyValueNamed("prop1")?.stringValue == "value")
    }
}
