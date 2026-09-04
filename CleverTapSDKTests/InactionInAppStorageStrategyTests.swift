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

    // retrieveAfterTimer is a dequeue: InAppScheduler calls it and throws the
    // result away on the error and discarded paths purely to drop the entry.
    func testRetrieveAfterTimer_hit_removesFromCache() {
        let inApp: [String: Any] = ["ti": "myId", "type": "interstitial"]
        _ = strategy.prepareForScheduling(inApps: [inApp])
        XCTAssertEqual(strategy.getCacheSize(), 1)

        XCTAssertNotNil(strategy.retrieveAfterTimer(id: "myId"))
        XCTAssertEqual(strategy.getCacheSize(), 0)
        XCTAssertNil(strategy.retrieveAfterTimer(id: "myId"))
    }

    func testRetrieveAfterTimer_hit_leavesOtherEntriesInPlace() {
        let inApps: [[String: Any]] = [
            ["ti": "id1", "type": "interstitial"],
            ["ti": "id2", "type": "cover"]
        ]
        _ = strategy.prepareForScheduling(inApps: inApps)

        XCTAssertNotNil(strategy.retrieveAfterTimer(id: "id1"))
        XCTAssertEqual(strategy.getCacheSize(), 1)
        XCTAssertNotNil(strategy.retrieveAfterTimer(id: "id2"))
        XCTAssertEqual(strategy.getCacheSize(), 0)
    }

    func testRetrieveAfterTimer_miss_leavesCacheUntouched() {
        _ = strategy.prepareForScheduling(inApps: [["ti": "id1", "type": "interstitial"]])

        XCTAssertNil(strategy.retrieveAfterTimer(id: "nonexistent"))
        XCTAssertEqual(strategy.getCacheSize(), 1)
    }

    // Writes used to bypass cacheQueue entirely, so a concurrent read could hit
    // the dictionary mid-mutation. Mutating a Swift Dictionary while another
    // thread reads it can crash rather than just return stale data.
    func testConcurrentPrepareAndRetrieve_doesNotCrash() {
        DispatchQueue.concurrentPerform(iterations: 200) { i in
            if i % 2 == 0 {
                _ = self.strategy.prepareForScheduling(inApps: [["ti": "id\(i)", "type": "interstitial"]])
            } else {
                _ = self.strategy.retrieveAfterTimer(id: "id\(i - 1)")
                _ = self.strategy.getCacheSize()
            }
        }
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
