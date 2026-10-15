// CTNdStoreTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTNdStore.
//
// It covers the user switch. CTNdStore does not receive that callback itself. It owns a small
// observer object, and the observer forwards the call. See the comment on
// CTNdStoreUserSwitchObserver in CTNdStore.swift. The tests below go through
// CTMultiDelegateManager, so they cover the registration and the forwarding together.
// CTMultiDelegateManager holds its delegates weakly, so a test that called the store directly would
// not catch a broken registration.

import Testing
@testable import CleverTapSDK

@Suite("CTNdStore", .serialized)
struct CTNdStoreTests {

    private let config: CleverTapInstanceConfig
    private let delegateManager: CTMultiDelegateManager
    private let firstDeviceId = "ndStoreDeviceId"
    private let store: CTNdStore

    init() {
        // A new account id per test. Preferences are one flat list of keys, and every key starts
        // with the account id. That keeps one test's rules out of the next test's.
        let accountId = "ndStoreTestAccount_\(UUID().uuidString)"
        config = CleverTapInstanceConfig(accountId: accountId, accountToken: "ndStoreTestToken")
        delegateManager = CTMultiDelegateManager()
        store = CTNdStore(config: config,
                          delegateManager: delegateManager,
                          deviceId: firstDeviceId)
    }

    @Test("Rules are empty before anything is stored")
    func emptyBeforeAnythingStored() {
        #expect(store.serverSideNativeDisplays().isEmpty)
    }

    @Test("Stored rules are read back")
    func storedRulesAreReadBack() {
        store.storeServerSideNativeDisplays([["ti": "1"], ["ti": "2"]])
        #expect(store.serverSideNativeDisplays().count == 2)
    }

    @Test("A nil argument leaves the stored rules alone")
    func nilArgumentIsIgnored() {
        store.storeServerSideNativeDisplays([["ti": "1"]])
        store.storeServerSideNativeDisplays(nil)
        #expect(store.serverSideNativeDisplays().count == 1)
    }

    @Test("An empty array clears the stored rules")
    func emptyArrayClearsRules() {
        store.storeServerSideNativeDisplays([["ti": "1"]])
        store.storeServerSideNativeDisplays([])
        #expect(store.serverSideNativeDisplays().isEmpty)
    }

    @Test("removeServerSideNativeDisplays clears the stored rules")
    func removeClearsRules() {
        store.storeServerSideNativeDisplays([["ti": "1"]])
        store.removeServerSideNativeDisplays()
        #expect(store.serverSideNativeDisplays().isEmpty)
    }

    // A trigger that tests whether an event property is set carries no value for it. The server
    // sends a JSON null there, which is read into memory as NSNull. NSUserDefaults rejects NSNull
    // and raises. The whole list was then lost, not just the one rule.
    @Test("A rule holding a null is stored and read back")
    func ruleHoldingNullIsStoredAndReadBack() {
        let ruleWithNull: [AnyHashable: Any] = [
            "ti": "1",
            "whenTriggers": [[
                "eventName": "App Launched",
                "eventProperties": [[
                    "operator": 26,
                    "propertyName": "CT SDK Version",
                    "propertyValue": NSNull()
                ]]
            ]]
        ]
        store.storeServerSideNativeDisplays([ruleWithNull])

        // Two switches, so the next read comes from storage and not from the in-memory copy.
        delegateManager.notifyDelegatesDeviceIdDidChange("\(firstDeviceId)_2")
        delegateManager.notifyDelegatesDeviceIdDidChange(firstDeviceId)

        let loaded = store.serverSideNativeDisplays()
        #expect(loaded.count == 1)

        let trigger = (loaded.first as? [AnyHashable: Any])?["whenTriggers"] as? [[AnyHashable: Any]]
        let properties = trigger?.first?["eventProperties"] as? [[AnyHashable: Any]]
        #expect(properties?.first?["propertyValue"] is NSNull)
    }

    @Test("A user switch hides the previous user's rules")
    func userSwitchHidesPreviousRules() {
        store.storeServerSideNativeDisplays([["ti": "1"]])

        delegateManager.notifyDelegatesDeviceIdDidChange("\(firstDeviceId)_2")

        #expect(store.serverSideNativeDisplays().isEmpty)
    }

    @Test("Each user keeps its own rules across switches")
    func eachUserKeepsItsOwnRules() {
        let secondDeviceId = "\(firstDeviceId)_2"

        store.storeServerSideNativeDisplays([["ti": "1"], ["ti": "2"]])

        delegateManager.notifyDelegatesDeviceIdDidChange(secondDeviceId)
        store.storeServerSideNativeDisplays([["ti": "3"]])
        #expect(store.serverSideNativeDisplays().count == 1)

        delegateManager.notifyDelegatesDeviceIdDidChange(firstDeviceId)
        #expect(store.serverSideNativeDisplays().count == 2)

        delegateManager.notifyDelegatesDeviceIdDidChange(secondDeviceId)
        #expect(store.serverSideNativeDisplays().count == 1)
    }
}
