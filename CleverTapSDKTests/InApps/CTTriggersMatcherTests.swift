//
//  CTTriggersMatcherTests.swift
//  CleverTapSDKTests
//
//  Swift Testing suite for CTTriggersMatcher — mirrors CTTriggersMatcherTest.m 1:1.
//  CTTriggersMatcher is still Objective-C at this point (these run against the existing ObjC source).
//
//  Notes on faithful transcription:
//  - The CLTAP_* keys/values used in the ObjC source are `#define` macros (invisible to Swift);
//    their string values are inlined here with a trailing comment naming the original macro.
//    Kept in sync with CTConstants.h:
//      CLTAP_CHARGED_EVENT              = "Charged"
//      CLTAP_SDK_VERSION               = "SDK Version"
//      CLTAP_APP_VERSION               = "Version"
//      CLTAP_OS_VERSION                = "OS Version"
//      CLTAP_PROP_CAMPAIGN_ID          = "Campaign id"
//      CLTAP_PROP_WZRK_ID              = "wzrk_id"
//      CLTAP_PROP_VARIANT              = "Variant"
//      CLTAP_PROP_WZRK_PIVOT           = "wzrk_pivot"
//      CLTAP_NOTIFICATION_PIVOT_DEFAULT = "wzrk_default"
//  - The 7 `firstTimeOnly` tests used OCMock on CTLocalDataStore. OCMock cannot be used from Swift,
//    so they use the `FakeDataStore` subclass defined below instead.

import Testing
import Foundation
import CoreLocation
@testable import CleverTapSDK

// Swift replacement for the OCMPartialMock on CTLocalDataStore used by the firstTimeOnly tests.
// `isEventLoggedFirstTime:` is declared in CTLocalDataStore.h without NS_ASSUME_NONNULL, so it is
// imported into Swift with an implicitly-unwrapped-optional parameter (`String!`).
private final class FakeDataStore: CTLocalDataStore {
    var firstTimeResult = true
    private(set) var checkedNames: [String] = []
    override func isEventLoggedFirstTime(_ eventName: String!) -> Bool {
        checkedNames.append(eventName)
        return firstTimeResult
    }
}

@Suite("CTTriggersMatcher", .serialized)
final class CTTriggersMatcherTests {

    private let dataStore: CTLocalDataStore

    init() {
        // Mirror the ObjC setUp exactly:
        let config = CleverTapInstanceConfig(accountId: "testAccount", accountToken: "testToken", accountRegion: "testRegion")
        let deviceInfo = CTDeviceInfo(config: config, andCleverTapID: "testDeviceInfo")
        let queueManager = CTDispatchQueueManager(config: config)
        dataStore = CTLocalDataStore(config: config, profileValues: [:], andDeviceInfo: deviceInfo, dispatchQueueManager: queueManager)
    }

    // Convenience helpers mirroring CTTriggersMatcher+Tests (build the event, call the real matcher method):
    private func match(_ matcher: CTTriggersMatcher, _ whenTriggers: [Any], eventName: String, properties: [AnyHashable: Any]) -> Bool {
        let event = CTEventAdapter(eventName: eventName, eventProperties: properties as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
        return matcher.matchEvent(whenTriggers: whenTriggers, event: event)
    }
    private func matchCharged(_ matcher: CTTriggersMatcher, _ whenTriggers: [Any], details: [AnyHashable: Any], items: [Any]) -> Bool {
        let event = CTEventAdapter(eventName: "Charged", eventProperties: details as NSDictionary, location: kCLLocationCoordinate2DInvalid, andItems: items)
        return matcher.matchEvent(whenTriggers: whenTriggers, event: event)
    }

    // Builds a fresh FakeDataStore with the same initializer args as `dataStore` in init().
    private func makeFakeDataStore() -> FakeDataStore {
        let config = CleverTapInstanceConfig(accountId: "testAccount", accountToken: "testToken", accountRegion: "testRegion")
        let deviceInfo = CTDeviceInfo(config: config, andCleverTapID: "testDeviceInfo")
        let queueManager = CTDispatchQueueManager(config: config)
        return FakeDataStore(config: config, profileValues: [:], andDeviceInfo: deviceInfo, dispatchQueueManager: queueManager)
    }

    // MARK: - Event

    @Test("Match event with all operators")
    func matchEventAllOperators() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 0, "propertyValue": 150],
                    ["propertyName": "prop2", "operator": 1, "propertyValue": "Equals"],
                    ["propertyName": "prop3", "operator": 2, "propertyValue": 150],
                    ["propertyName": "prop4", "operator": 3, "propertyValue": "Contains"],
                    ["propertyName": "prop5", "operator": 4, "propertyValue": [1, 3]],
                    ["propertyName": "prop6", "operator": 15, "propertyValue": "NotEquals"],
                    ["propertyName": "prop7", "operator": 26],
                    ["propertyName": "prop8", "operator": 27],
                    ["propertyName": "prop9", "operator": 28, "propertyValue": "NotContains"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 160,
            "prop2": "Equals",
            "prop3": 140,
            "prop4": "Contains CleverTap",
            "prop5": 2,
            "prop6": "NotEquals!",
            "prop7": "is set",
            "prop9": "No Contains"
        ]))
    }

    @Test("Match event without trigger props")
    func matchEventWithoutTriggerProps() {
        let whenTriggers: [Any] = [
            ["eventName": "event1"]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: ["prop1": "clevertap"]))
        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    @Test("Match event with empty trigger props")
    func matchEventWithEmptyTriggerProps() {
        let whenTriggers: [Any] = [
            ["eventName": "event1", "eventProperties": []]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: ["prop1": "clevertap"]))
        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    @Test("Match event without props does not match when trigger expects a prop")
    func matchEventWithoutProps() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": "test"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    @Test("Match event with normalized name")
    func matchEventWithNormalizedName() {
        let whenTriggers: [Any] = [
            ["eventName": "event1", "eventProperties": []]
        ]

        let matcher = CTTriggersMatcher()
        #expect(match(matcher, whenTriggers, eventName: "Event 1", properties: ["prop1": "clevertap"]))
    }

    // MARK: - Profile Event

    @Test("Match profile event")
    func matchProfileEvent() {
        let whenTriggers: [Any] = [
            [
                "eventName": "profile1 changed",
                "profileAttrName": "profile1",
                "eventProperties": [
                    ["propertyName": "newValue", "operator": 0, "propertyValue": 150],
                    ["propertyName": "oldValue", "operator": 1, "propertyValue": "Equals"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher()

        let eventProperties: [AnyHashable: Any] = [
            "newValue": 160,
            "oldValue": "Equals"
        ]

        var eventAdapter = CTEventAdapter(eventName: "profile1_changed", profileAttrName: "profile1", eventProperties: eventProperties as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
        #expect(matcher.matchEvent(whenTriggers: whenTriggers, event: eventAdapter))

        eventAdapter = CTEventAdapter(eventName: "profile 1_changed", profileAttrName: "profile 1", eventProperties: eventProperties as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
        #expect(matcher.matchEvent(whenTriggers: whenTriggers, event: eventAdapter))

        eventAdapter = CTEventAdapter(eventName: "Profile 1_changed", profileAttrName: "Profile 1", eventProperties: eventProperties as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
        #expect(matcher.matchEvent(whenTriggers: whenTriggers, event: eventAdapter))

        eventAdapter = CTEventAdapter(eventName: "profile  1_changed", profileAttrName: "profile  1", eventProperties: eventProperties as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
        #expect(matcher.matchEvent(whenTriggers: whenTriggers, event: eventAdapter))

        eventAdapter = CTEventAdapter(eventName: "Profile_1_changed", profileAttrName: "Profile_1", eventProperties: eventProperties as NSDictionary, andLocation: kCLLocationCoordinate2DInvalid)
        #expect(!matcher.matchEvent(whenTriggers: whenTriggers, event: eventAdapter))
    }

    // MARK: - Charged Event

    @Test("Match charged event")
    func matchChargedEvent() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ],
                "itemProperties": [
                    ["propertyName": "product_name", "operator": 1, "propertyValue": "product 1"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matchCharged(matcher, whenTriggers, details: [
            "prop1": 150
        ], items: [
            ["product_name": "product 1", "price": 5.99],
            ["product_name": "product 2", "price": 5.50]
        ]))
    }

    @Test("Charged without items")
    func chargedWithoutItems() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ],
                "itemProperties": []
            ]
        ]

        let whenTriggersNoItems: [Any] = [
            [
                "eventName": "Charged",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matchCharged(matcher, whenTriggers, details: [
            "prop1": 150
        ], items: [
            ["product_name": "product 1", "price": 5.99],
            ["product_name": "product 2", "price": 5.50]
        ]))

        #expect(matchCharged(matcher, whenTriggersNoItems, details: [
            "prop1": 150
        ], items: [
            ["product_name": "product 1", "price": 5.99],
            ["product_name": "product 2", "price": 5.50]
        ]))

        #expect(matchCharged(matcher, whenTriggers, details: [
            "prop1": 150
        ], items: []))

        #expect(matchCharged(matcher, whenTriggersNoItems, details: [
            "prop1": 150
        ], items: []))
    }

    @Test("Match charged event item array equals")
    func matchChargedEventItemArrayEquals() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ],
                "itemProperties": [
                    ["propertyName": "product_name", "operator": 1, "propertyValue": ["product 1", "product 2"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matchCharged(matcher, whenTriggers, details: [
            "prop1": 150
        ], items: [
            ["product_name": "product 1", "price": 5.99],
            ["product_name": "product 2", "price": 5.50]
        ]))
    }

    @Test("Match charged event item array equals normalized")
    func matchChargedEventItemArrayEqualsNormalized() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ],
                "itemProperties": [
                    ["propertyName": "product name", "operator": 1, "propertyValue": ["product 1"]],
                    ["propertyName": "price", "operator": 1, "propertyValue": [5.99]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher()

        #expect(matchCharged(matcher, whenTriggers, details: [
            "Prop 1": 150
        ], items: [
            ["ProductName": "product 1", "Price": 5.99]
        ]))
    }

    @Test("Match charged event item array contains")
    func matchChargedEventItemArrayContains() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ],
                "itemProperties": [
                    ["propertyName": "product_name", "operator": 3, "propertyValue": ["product 1", "product 2"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matchCharged(matcher, whenTriggers, details: [
            "prop1": 150
        ], items: [
            ["product_name": "product 1", "price": 5.99],
            ["product_name": "product 2", "price": 5.50]
        ]))
    }

    @Test("Match charged event item array contains normalized")
    func matchChargedEventItemArrayContainsNormalized() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "eventProperties": [],
                "itemProperties": [
                    ["propertyName": "product name", "operator": 3, "propertyValue": ["product 1", "product 2"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher()

        #expect(matchCharged(matcher, whenTriggers, details: [:], items: [
            ["Product Name": "product 1", "price": 5.50]
        ]))
    }

    // MARK: - Equals

    @Test("Match equals primitives")
    func matchEqualsPrimitives() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150],
                    ["propertyName": "prop2", "operator": 1, "propertyValue": 200],
                    ["propertyName": "prop3", "operator": 1, "propertyValue": 150],
                    ["propertyName": "prop4", "operator": 1, "propertyValue": "CleverTap"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150,
            "prop2": 200,
            "prop3": "150",
            "prop4": "CleverTap"
        ]))
    }

    @Test("Match equals boolean")
    func matchEqualsBoolean() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": "true"],
                    ["propertyName": "prop2", "operator": 1, "propertyValue": "false"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": true,
            "prop2": false
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": true,
            "prop2": false
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 1,
            "prop2": 0
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": false,
            "prop2": true
        ]))
    }

    @Test("Match equals boolean string")
    func matchEqualsBooleanString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": "true"],
                    ["propertyName": "prop2", "operator": 1, "propertyValue": "false"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "true",
            "prop2": "false"
        ]))
    }

    @Test("Match equals boolean case insensitive")
    func matchEqualsBooleanCaseInsensitive() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": "True"],
                    ["propertyName": "prop2", "operator": 1, "propertyValue": "False"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": true,
            "prop2": false
        ]))
    }

    @Test("Match equals numbers")
    func matchEqualsNumbers() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150],
                    ["propertyName": "prop2", "operator": 1, "propertyValue": "200"],
                    ["propertyName": "prop3", "operator": 1, "propertyValue": [150, "200", 0.55]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150,
            "prop2": 200,
            "prop3": 200
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "150",
            "prop2": 200,
            "prop3": "150"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "150.00",
            "prop2": 200.00,
            "prop3": "0.55"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "150.00",
            "prop2": 200,
            "prop3": "0.56"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150,
            "prop2": "200",
            "prop3": "55"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "test",
            "prop2": "test",
            "prop3": "test"
        ]))
    }

    @Test("Match equals numbers charged")
    func matchEqualsNumbersCharged() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "itemProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150],
                    ["propertyName": "prop2", "operator": 1, "propertyValue": "200"],
                    ["propertyName": "prop3", "operator": 1, "propertyValue": [150, "200", 0.55]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matchCharged(matcher, whenTriggers, details: [:], items: [
            [
                "prop1": "150",
                "prop2": 200,
                "prop3": "150"
            ]
        ]))

        #expect(matchCharged(matcher, whenTriggers, details: [:], items: [
            [
                "prop1": 1,
                "prop2": 2,
                "prop3": 3
            ],
            [
                "prop1": 150,
                "prop2": 200,
                "prop3": 0.55
            ]
        ]))

        #expect(!matchCharged(matcher, whenTriggers, details: [:], items: [
            [
                "prop1": 1,
                "prop2": 2,
                "prop3": 3
            ]
        ]))
    }

    @Test("Match equals double")
    func matchEqualsDouble() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150.95]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150.950
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "150.950"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "150.96"
        ]))
    }

    @Test("Match equals expected string with actual array")
    func matchEqualsExtectedStringWithActualArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": "test"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["test", "test2"]
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["test1", "test2"]
        ]))
    }

    @Test("Match equals expected array with actual string")
    func matchEqualsExtectedArrayWithActualString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": ["test", "test1"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["test"]
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["test1"]
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["test2"]
        ]))
    }

    @Test("Match equals expected number with actual array")
    func matchEqualsExtectedNumberWithActualArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["test", 150]
        ]))
    }

    @Test("Match equals expected string with actual string")
    func matchEqualsExtectedStringWithActualString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": "test"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "test"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "Test"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "TEST"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 12
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": NSNull()
        ]))
    }

    @Test("Match equals property name with normalization")
    func matchEqualsPropertyNameWithNormalization() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": "test"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher()

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop 1": "test"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "Prop  1": "test"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "E vent1", properties: [
            "Prop  1": "test"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "Prop.1": "test"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "Prop  1": "test1",
            "Prop1": "test"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "Prop1": "test1",
            "prop 1": "test2",
            "prop1": "test"
        ]))
    }

    @Test("Match equals expected number with actual string")
    func matchEqualsExtectedNumberWithActualString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "test"
        ]))
    }

    @Test("Match equals expected double with actual double")
    func matchEqualsExtectedDoubleWithActualDouble() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150.99]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150.99
        ]))
    }

    @Test("Match equals expected double with actual double string")
    func matchEqualsExtectedDoubleWithActualDoubleString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150.99]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "150.99"
        ]))
    }

    @Test("Match equals expected array with actual array")
    func matchEqualsExtectedArrayWithActualArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": ["test", "test2", "test3"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["test2", "test3", "test"]
        ]))
    }

    @Test("Match equals expected array with actual array number")
    func matchEqualsExtectedArrayWithActualArrayNumber() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": [1, 2, 3]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": [3, 1, 2]
        ]))
    }

    // MARK: - Set

    @Test("Match set")
    func matchSet() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 26]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150
        ]))
    }

    @Test("Match set charged")
    func matchSetCharged() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "itemProperties": [
                    ["propertyName": "item1", "operator": 26]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matchCharged(matcher, whenTriggers, details: [:], items: [
            ["item2": 1],
            ["item1": 1]
        ]))

        #expect(!matchCharged(matcher, whenTriggers, details: [:], items: [
            ["item2": 1]
        ]))
    }

    // MARK: - Not Set

    @Test("Match not set")
    func matchNotSet() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 27]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop2": 150
        ]))
    }

    @Test("Match not set charged")
    func matchNotSetCharged() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "itemProperties": [
                    ["propertyName": "item1", "operator": 27]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(!matchCharged(matcher, whenTriggers, details: [:], items: [
            ["item2": 1],
            ["item1": 1]
        ]))

        #expect(matchCharged(matcher, whenTriggers, details: [:], items: [
            ["item2": 1]
        ]))
    }

    // MARK: - Not Equals

    @Test("Match not equals")
    func matchNotEquals() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 15, "propertyValue": 150]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 240
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150
        ]))
    }

    @Test("Match not equals arrays")
    func matchNotEqualsArrays() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 15, "propertyValue": [150, 240]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": [241]
        ]))

        // If any Not Equals any
        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": [150, 100]
        ]))
    }

    // MARK: - Less Than

    @Test("Match less than")
    func matchLessThan() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 2, "propertyValue": 240]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    @Test("Match less than with string")
    func matchLessThanWithString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 2, "propertyValue": 240]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "-120"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "asd"
        ]))
    }

    @Test("Match less than with arrays")
    func matchLessThanWithArrays() {
        var whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 2, "propertyValue": [240]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "-120"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": [250, -1]
        ]))

        whenTriggers = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 2, "propertyValue": [240, 500]]
                ]
            ]
        ]

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "-120"
        ]))
    }

    // MARK: - Greater Than

    @Test("Match greater than")
    func matchGreaterThan() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 0, "propertyValue": 150]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 240
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    @Test("Match greater than with string")
    func matchGreaterThanWithString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 0, "propertyValue": 150]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "240"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "asd"
        ]))
    }

    @Test("Match greater than with arrays")
    func matchGreaterThanWithArrays() {
        var whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 0, "propertyValue": [240]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 600
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": [250, -1, 600]
        ]))

        whenTriggers = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 0, "propertyValue": [240, 500]]
                ]
            ]
        ]

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 600
        ]))
    }

    // MARK: - Between

    @Test("Match between")
    func matchBetween() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 4, "propertyValue": [100, 240]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 100
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 240
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "150"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 1
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 250
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "a150"
        ]))
    }

    @Test("Match between charged")
    func matchBetweenCharged() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "itemProperties": [
                    ["propertyName": "item1", "operator": 4, "propertyValue": [100, 240]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matchCharged(matcher, whenTriggers, details: [:], items: [
            ["item1": 1],
            ["item1": 101]
        ]))

        #expect(!matchCharged(matcher, whenTriggers, details: [:], items: [
            ["item1": 300],
            ["item1": 400]
        ]))
    }

    @Test("Match between array more than 2")
    func matchBetweenArrayMoreThan2() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 4, "propertyValue": [100, 240, 330, "test"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150
        ]))
    }

    @Test("Match between empty array")
    func matchBetweenEmptyArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 4, "propertyValue": []]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 150
        ]))
    }

    // MARK: - Contains

    @Test("Match contains string")
    func matchContainsString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 3, "propertyValue": "clever"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "clevertap"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "cle"
        ]))
    }

    @Test("Match contains string bool")
    func matchContainsStringBool() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 3, "propertyValue": "true"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "this is true"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "this is false"
        ]))
    }

    @Test("Match contains number")
    func matchContainsNumber() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 3, "propertyValue": 1234]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "1234567"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 1234567
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 123
        ]))
    }

    @Test("Match contains array")
    func matchContainsArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 3, "propertyValue": ["clever", "test"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "clevertap"
        ]))
    }

    @Test("Match contains array number")
    func matchContainsArrayNumber() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 3, "propertyValue": [1234, "45678"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "123456"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": 456789
        ]))
    }

    @Test("Match contains array empty")
    func matchContainsArrayEmpty() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 3, "propertyValue": []]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "clevertap"
        ]))
    }

    @Test("Match contains string with property array")
    func matchContainsStringWithPropertyArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 3, "propertyValue": "clever"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["clevertap", "test"]
        ]))
    }

    // MARK: - Not Contains

    @Test("Match not contains array")
    func matchNotContainsArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 28, "propertyValue": ["testing", "test"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "clevertap"
        ]))

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "te"
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "test"
        ]))
    }

    @Test("Match not contains array from trigger array")
    func matchNotContainsArrayFromTriggerArray() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 28, "propertyValue": ["testing", "test"]]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": ["clevertap", "yes"]
        ]))
    }

    @Test("Match not contains string")
    func matchNotContainsString() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 28, "propertyValue": "test"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "prop1": "clevertap"
        ]))
    }

    // MARK: - System and Notification properties

    @Test("Match system properties")
    func matchSystemProperties() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "CT SDK Version", "operator": 1, "propertyValue": 60000]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "SDK Version": 60000   // CLTAP_SDK_VERSION
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    @Test("Match system properties current and legacy")
    func matchSystemPropertiesCurrentAndLegacy() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "CT SDK Version", "operator": 1, "propertyValue": 60000],
                    ["propertyName": "ct_sdk_version", "operator": 1, "propertyValue": 60000],
                    ["propertyName": "CT App Version", "operator": 1, "propertyValue": "6.0.0"],
                    ["propertyName": "ct_app_version", "operator": 1, "propertyValue": "6.0.0"],
                    ["propertyName": "ct_os_version", "operator": 1, "propertyValue": "17.1.1"],
                    ["propertyName": "CT OS Version", "operator": 1, "propertyValue": "17.1.1"]
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)
        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [
            "SDK Version": 60000,    // CLTAP_SDK_VERSION
            "Version": "6.0.0",      // CLTAP_APP_VERSION
            "OS Version": "17.1.1"   // CLTAP_OS_VERSION
        ]))
    }

    @Test("Match notification properties")
    func matchNotificationProperties() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Notification Viewed",
                "eventProperties": [
                    ["propertyName": "Campaign id", "operator": 3, "propertyValue": 1701172437],   // CLTAP_PROP_CAMPAIGN_ID
                    ["propertyName": "wzrk_id", "operator": 3, "propertyValue": 1701172437],         // CLTAP_PROP_WZRK_ID
                    ["propertyName": "Variant", "operator": 1, "propertyValue": "wzrk_default"],     // CLTAP_PROP_VARIANT / CLTAP_NOTIFICATION_PIVOT_DEFAULT
                    ["propertyName": "wzrk_pivot", "operator": 1, "propertyValue": "wzrk_default"]    // CLTAP_PROP_WZRK_PIVOT / CLTAP_NOTIFICATION_PIVOT_DEFAULT
                ]
            ]
        ]

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(match(matcher, whenTriggers, eventName: "Notification Viewed", properties: [
            "wzrk_id": "1701172437_20231128",   // CLTAP_PROP_WZRK_ID
            "wzrk_pivot": "wzrk_default"         // CLTAP_PROP_WZRK_PIVOT / CLTAP_NOTIFICATION_PIVOT_DEFAULT
        ]))

        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    // MARK: - GeoRadius

    @Test("Match event with geo radius")
    func matchEventWithGeoRadius() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "geoRadius": [
                    ["lat": 19.07609, "lng": 72.877426, "rad": 2]
                ]
            ]
        ]

        // Distance ~1.1km
        let location1km = CLLocationCoordinate2D(latitude: 19.08609, longitude: 72.877426)

        var event = CTEventAdapter(eventName: "event1", eventProperties: [:] as NSDictionary, andLocation: location1km)

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(matcher.matchEvent(whenTriggers: whenTriggers, event: event))

        // Distance ~2.2km
        let location2km = CLLocationCoordinate2D(latitude: 19.09609, longitude: 72.877426)
        event = CTEventAdapter(eventName: "event1", eventProperties: [:] as NSDictionary, andLocation: location2km)
        #expect(!matcher.matchEvent(whenTriggers: whenTriggers, event: event))
    }

    @Test("Match event with geo radius but not params")
    func matchEventWithGeoRadiusButNotParams() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ],
                "geoRadius": [
                    ["lat": 19.07609, "lng": 72.877426, "rad": 2]
                ]
            ]
        ]

        // Distance ~1.1km
        let location1km = CLLocationCoordinate2D(latitude: 19.08609, longitude: 72.877426)

        let event = CTEventAdapter(eventName: "event1", eventProperties: ["prop1": 151] as NSDictionary, andLocation: location1km)

        let matcher = CTTriggersMatcher(dataStore: dataStore)

        #expect(!matcher.matchEvent(whenTriggers: whenTriggers, event: event))
    }

    // MARK: - FirstTimeOnly

    @Test("Match event with firstTimeOnly")
    func matchEventWithFirstTimeOnly() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "firstTimeOnly": true
            ]
        ]

        let fake = makeFakeDataStore()
        fake.firstTimeResult = true
        let matcher = CTTriggersMatcher(dataStore: fake)

        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [:]))
        #expect(fake.checkedNames.contains("event1"))
    }

    @Test("Match charged event with firstTimeOnly")
    func matchChargedEventWithFirstTimeOnly() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "firstTimeOnly": true,
                "eventProperties": [
                    ["propertyName": "prop1", "operator": 1, "propertyValue": 150]
                ],
                "itemProperties": [
                    ["propertyName": "product_name", "operator": 1, "propertyValue": "product 1"]
                ]
            ]
        ]

        let fake = makeFakeDataStore()
        fake.firstTimeResult = true
        let matcher = CTTriggersMatcher(dataStore: fake)

        #expect(matchCharged(matcher, whenTriggers, details: [
            "prop1": 150
        ], items: [
            ["product_name": "product 1", "price": 5.99],
            ["product_name": "product 2", "price": 5.50]
        ]))
        #expect(fake.checkedNames.contains("Charged"))
    }

    @Test("Match event firstTimeOnly with geo radius")
    func matchEventFirstTimeOnlyWithGeoRadius() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "firstTimeOnly": true,
                "geoRadius": [
                    ["lat": 19.07609, "lng": 72.877426, "rad": 2]
                ]
            ]
        ]

        // Distance ~1.1km
        let location1km = CLLocationCoordinate2D(latitude: 19.08609, longitude: 72.877426)

        let event = CTEventAdapter(eventName: "event1", eventProperties: [:] as NSDictionary, andLocation: location1km)

        let fake = makeFakeDataStore()
        fake.firstTimeResult = true
        let matcher = CTTriggersMatcher(dataStore: fake)

        #expect(matcher.matchEvent(whenTriggers: whenTriggers, event: event))
    }

    @Test("Match event with firstTimeOnly, not first time")
    func matchEvent_withFirstTimeOnly_notFirstTime() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "firstTimeOnly": true
            ]
        ]

        let fake = makeFakeDataStore()
        fake.firstTimeResult = false
        let matcher = CTTriggersMatcher(dataStore: fake)

        // Event should not match when firstTimeOnly is YES but event is not first-time
        #expect(!match(matcher, whenTriggers, eventName: "event1", properties: [:]))
    }

    @Test("Match charged event with firstTimeOnly, not first time")
    func matchChargedEvent_withFirstTimeOnly_notFirstTime() {
        let whenTriggers: [Any] = [
            [
                "eventName": "Charged",
                "firstTimeOnly": true
            ]
        ]

        let fake = makeFakeDataStore()
        fake.firstTimeResult = false
        let matcher = CTTriggersMatcher(dataStore: fake)

        // Charged event should not match when firstTimeOnly is YES but event is not first-time
        #expect(!matchCharged(matcher, whenTriggers, details: [:], items: []))
    }

    @Test("Match event without firstTimeOnly does not call data store")
    func matchEvent_withoutFirstTimeOnly_doesNotCallDataStore() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1"
            ]
        ]

        let fake = makeFakeDataStore()
        let matcher = CTTriggersMatcher(dataStore: fake)

        // Event without firstTimeOnly should match without consulting the data store
        #expect(match(matcher, whenTriggers, eventName: "event1", properties: [:]))
        #expect(fake.checkedNames.isEmpty)
    }

    @Test("Match event with firstTimeOnly, event name mismatch does not call data store")
    func matchEvent_withFirstTimeOnly_eventNameMismatch_doesNotCallDataStore() {
        let whenTriggers: [Any] = [
            [
                "eventName": "event1",
                "firstTimeOnly": true
            ]
        ]

        let fake = makeFakeDataStore()
        let matcher = CTTriggersMatcher(dataStore: fake)

        // Event name mismatch should fail before checking firstTimeOnly
        #expect(!match(matcher, whenTriggers, eventName: "event2", properties: [:]))
        #expect(fake.checkedNames.isEmpty)
    }
}
