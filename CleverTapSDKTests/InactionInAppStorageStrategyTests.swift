//
//  InactionInAppStorageStrategyTests.swift
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import XCTest
@testable import CleverTapSDK

class InactionInAppStorageStrategyTests: XCTestCase {

    var strategy: InactionInAppStorageStrategy!

    override func setUp() {
        super.setUp()
        strategy = InactionInAppStorageStrategy()
    }

    override func tearDown() {
        strategy = nil
        super.tearDown()
    }

    func testGetCacheSize_initiallyZero() {
        XCTAssertEqual(strategy.getCacheSize(), 0)
    }

    func testPrepareForScheduling_returnsTrue() {
        let inApps: [[String: Any]] = [["ti": "abc", "type": "interstitial"]]
        let result = strategy.prepareForScheduling(inApps: inApps)
        XCTAssertTrue(result)
    }

    func testPrepareForScheduling_withValidInApps_cachesThem() {
        let inApps: [[String: Any]] = [
            ["ti": "id1", "type": "interstitial"],
            ["ti": "id2", "type": "cover"]
        ]
        _ = strategy.prepareForScheduling(inApps: inApps)
        XCTAssertEqual(strategy.getCacheSize(), 2)
    }

    func testPrepareForScheduling_withEmptyIdInApp_notCached() {
        let inApps: [[String: Any]] = [
            ["type": "interstitial"],          // missing "ti" key
            ["ti": "", "type": "cover"]         // empty "ti"
        ]
        _ = strategy.prepareForScheduling(inApps: inApps)
        XCTAssertEqual(strategy.getCacheSize(), 0)
    }

    func testRetrieveAfterTimer_hit_returnsInApp() {
        let inApp: [String: Any] = ["ti": "myId", "type": "interstitial"]
        _ = strategy.prepareForScheduling(inApps: [inApp])
        let retrieved = strategy.retrieveAfterTimer(id: "myId")
        XCTAssertNotNil(retrieved)
    }

    func testRetrieveAfterTimer_miss_returnsNil() {
        let retrieved = strategy.retrieveAfterTimer(id: "nonexistent")
        XCTAssertNil(retrieved)
    }

    func testClearAll_emptiesCache() {
        let inApps: [[String: Any]] = [
            ["ti": "id1", "type": "interstitial"],
            ["ti": "id2", "type": "cover"]
        ]
        _ = strategy.prepareForScheduling(inApps: inApps)
        XCTAssertEqual(strategy.getCacheSize(), 2)

        strategy.clearAll()
        // Wait for the barrier async to complete
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(strategy.getCacheSize(), 0)
    }
}
