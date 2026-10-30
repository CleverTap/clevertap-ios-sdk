//
//  CTEventAdapter.swift
//  CleverTapSDK
//
//  Swift replacement for CTEventAdapter.h/.m. Wraps a fired event (name, properties, items,
//  location, optional profile attribute) and resolves a property / item value by name, applying
//  CleverTap's name normalization and system-property aliasing. Built by CTInAppEvaluationManager
//  and read by CTTriggersMatcher during in-app trigger evaluation.
//
//  Access control:
//  - Usable from CTInAppEvaluationManager (still ObjC), which constructs it via the three pinned
//    `initWithEventName:...` selectors and reads `eventName` / `eventProperties` / `profileAttrName`.
//    Only those exact members carry `@objc` — the class is a bare NSObject subclass (no `@objcMembers`),
//    so the resolver methods (propertyValueNamed / itemValueNamed, called only by the Swift
//    CTTriggersMatcher) and the Swift-only `location` stay off the ObjC surface.
//
//  Migration notes:
//  - `profileAttrName` is optional (nonnull-in-header but nil for 2 of 3 inits; consumers nil-check);
//    `eventName` stays non-optional. `andItems:` is nullable (nil means "no items").
//  - `+initialize`/`dispatch_once` → lazy `static let systemPropToKey` (same once semantics).
//  - ⚠️ `eventProperties` is kept as the caller's `NSDictionary` (not a Swift dict): the resolver
//    picks the first key that normalize-matches, and Swift's randomized hash seed would change that
//    enumeration order (round-trips don't help) — see memory `nsdictionary-order-preservation`.
//  - ⚠️ The CLTAP_* keys below are `#define` macros (invisible to Swift); their values are inlined
//    here and must stay in sync with CTConstants.h.

import Foundation
import CoreLocation

public final class CTEventAdapter: NSObject {

    @objc public let eventName: String
    public let location: CLLocationCoordinate2D
    @objc public let profileAttrName: String?
    @objc public var eventProperties: NSDictionary

    private let items: [Any]?

    // System property display names (new + legacy) → App Fields key. Values are the inlined
    // CLTAP_* #define string constants (noted per line).
    private static let systemPropToKey: [String: String] = [
        "CT App Version": "Version",            "ct_app_version": "Version",            // CLTAP_APP_VERSION
        "CT Latitude": "Latitude",              "ct_latitude": "Latitude",              // CLTAP_LATITUDE
        "CT Longitude": "Longitude",            "ct_longitude": "Longitude",            // CLTAP_LONGITUDE
        "CT OS Version": "OS Version",          "ct_os_version": "OS Version",          // CLTAP_OS_VERSION
        "CT SDK Version": "SDK Version",        "ct_sdk_version": "SDK Version",        // CLTAP_SDK_VERSION
        "CT Network Carrier": "Carrier",        "ct_network_carrier": "Carrier",        // CLTAP_CARRIER
        "CT Network Type": "Radio",             "ct_network_type": "Radio",             // CLTAP_NETWORK_TYPE
        "CT Connected To WiFi": "wifi",         "ct_connected_to_wifi": "wifi",         // CLTAP_CONNECTED_TO_WIFI
        "CT Bluetooth Version": "BluetoothVersion", "ct_bluetooth_version": "BluetoothVersion", // CLTAP_BLUETOOTH_VERSION
        "CT Bluetooth Enabled": "BluetoothEnabled", "ct_bluetooth_enabled": "BluetoothEnabled", // CLTAP_BLUETOOTH_ENABLED
        "CT App Name": "appnId"
    ]

    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable; use one of the initWithEventName: initializers")
    }

    @objc(initWithEventName:eventProperties:location:andItems:)
    public init(eventName: String,
                eventProperties: NSDictionary,
                location: CLLocationCoordinate2D,
                andItems items: [Any]?) {
        self.eventName = eventName
        self.eventProperties = eventProperties
        self.location = location
        self.items = items
        self.profileAttrName = nil
        super.init()
    }

    @objc(initWithEventName:eventProperties:andLocation:)
    public convenience init(eventName: String,
                            eventProperties: NSDictionary,
                            andLocation location: CLLocationCoordinate2D) {
        self.init(eventName: eventName, eventProperties: eventProperties, location: location, andItems: [])
    }

    @objc(initWithEventName:profileAttrName:eventProperties:andLocation:)
    public init(eventName: String,
                profileAttrName: String?,
                eventProperties: NSDictionary,
                andLocation location: CLLocationCoordinate2D) {
        self.eventName = eventName
        self.eventProperties = eventProperties
        self.location = location
        self.items = []
        self.profileAttrName = profileAttrName
        super.init()
    }

    public func propertyValueNamed(_ name: String) -> CTTriggerValue? {
        guard let value = getActualPropertyValue(name) else { return nil }
        return CTTriggerValue(value: value)
    }

    public func itemValueNamed(_ name: String) -> CTTriggerValue? {
        guard let items = items else { return nil }
        var itemValues: [Any] = []
        for case let item as NSDictionary in items {
            var value = item.object(forKey: name)
            if value == nil, let normalizedName = CTUtils.getNormalizedName(name) {
                value = item.object(forKey: normalizedName)
            }
            if value == nil {
                // Normalize the item's own keys, then look the normalized name up in that.
                let normalizedItem = NSMutableDictionary()
                for case let key as String in item.keyEnumerator() {
                    if let normalizedKey = CTUtils.getNormalizedName(key) {
                        normalizedItem[normalizedKey] = item.object(forKey: key)
                    }
                }
                if let normalizedName = CTUtils.getNormalizedName(name) {
                    value = normalizedItem.object(forKey: normalizedName)
                }
            }
            if let value = value {
                itemValues.append(value)
            }
        }
        return itemValues.count > 0 ? CTTriggerValue(value: itemValues) : nil
    }

    private func getActualPropertyValue(_ propertyName: String) -> Any? {
        var value = getPropertyValue(propertyName)
        if value == nil {
            switch propertyName {
            case "Campaign id":                              // CLTAP_PROP_CAMPAIGN_ID
                value = getPropertyValue("wzrk_id")          // CLTAP_PROP_WZRK_ID
            case "wzrk_id":                                  // CLTAP_PROP_WZRK_ID
                value = getPropertyValue("Campaign id")      // CLTAP_PROP_CAMPAIGN_ID
            case "Variant":                                  // CLTAP_PROP_VARIANT
                value = getPropertyValue("wzrk_pivot")       // CLTAP_PROP_WZRK_PIVOT
            case "wzrk_pivot":                               // CLTAP_PROP_WZRK_PIVOT
                value = getPropertyValue("Variant")          // CLTAP_PROP_VARIANT
            default:
                if let mappedKey = Self.systemPropToKey[propertyName] {
                    value = getPropertyValue(mappedKey)
                }
            }
        }
        return value
    }

    private func getPropertyValue(_ name: String) -> Any? {
        if let value = eventProperties.object(forKey: name) {
            return value
        }
        guard let normalizedName = CTUtils.getNormalizedName(name) else { return nil }
        if let value = eventProperties.object(forKey: normalizedName) {
            return value
        }
        // Fall back to a normalized-equal comparison against each event-property key.
        for case let key as String in eventProperties.keyEnumerator() {
            if CTUtils.areEqualNormalizedName(key, andName: normalizedName) {
                return eventProperties.object(forKey: key)
            }
        }
        return nil
    }
}
