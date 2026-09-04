//
//  InAppSelectionStrategyTests.swift
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import XCTest
@testable import CleverTapSDK

class InAppSelectionStrategyTests: XCTestCase {

    let strategy = DelayedInAppSelectionStrategy.shared

    // MARK: - shouldUpdateTTL

    func testDelayed_shouldUpdateTTL_returnsFalse() {
        XCTAssertFalse(strategy.shouldUpdateTTL())
    }

    // MARK: - selectInApps

    func testDelayed_selectInApps_emptyInput_returnsEmpty() {
        let result = strategy.selectInApps([], suppressionHandler: { _ in false })
        XCTAssertTrue(result.isEmpty)
    }

    func testDelayed_selectInApps_singleUnsuppressed_returnsIt() {
        let inApp: NSDictionary = ["ti": NSNumber(value: 1), "delayAfterTrigger": 30]
        let result = strategy.selectInApps([inApp], suppressionHandler: { _ in false })
        XCTAssertEqual(result.count, 1)
    }

    func testDelayed_selectInApps_allSuppressed_returnsEmpty() {
        let inApp: NSDictionary = ["ti": NSNumber(value: 2), "delayAfterTrigger": 30]
        let result = strategy.selectInApps([inApp], suppressionHandler: { _ in true })
        XCTAssertTrue(result.isEmpty)
    }

    func testDelayed_selectInApps_multipleWithSameId_picksFirstUnsuppressed() {
        // Two in-apps with same "ti"; first is suppressed, second is not
        let inApp1: NSDictionary = ["ti": NSNumber(value: 3), "delayAfterTrigger": 30, "variant": "A"]
        let inApp2: NSDictionary = ["ti": NSNumber(value: 3), "delayAfterTrigger": 30, "variant": "B"]
        var callCount = 0
        let result = strategy.selectInApps([inApp1, inApp2], suppressionHandler: { _ in
            callCount += 1
            return callCount == 1  // suppress only the first call
        })
        // One in-app should be selected (the non-suppressed one from this group)
        XCTAssertEqual(result.count, 1)
    }

    func testDelayed_selectInApps_inAppMissingTiKey_skipped() {
        // In-app without "ti" key should be skipped (guard let fails)
        let inApp: NSDictionary = ["delayAfterTrigger": 30, "type": "interstitial"]
        let result = strategy.selectInApps([inApp], suppressionHandler: { _ in false })
        XCTAssertTrue(result.isEmpty)
    }

    func testDelayed_selectInApps_multipleDistinctIds_selectsOnePerGroup() {
        let inApp1: NSDictionary = ["ti": NSNumber(value: 10), "delayAfterTrigger": 30]
        let inApp2: NSDictionary = ["ti": NSNumber(value: 20), "delayAfterTrigger": 60]
        let result = strategy.selectInApps([inApp1, inApp2], suppressionHandler: { _ in false })
        XCTAssertEqual(result.count, 2)
    }

    // Grouping is by delay, not by id: in-apps sharing a delay compete for one slot.
    func testDelayed_selectInApps_sameDelay_selectsOnlyOne() {
        let inApp1: NSDictionary = ["ti": NSNumber(value: 10), "delayAfterTrigger": 30]
        let inApp2: NSDictionary = ["ti": NSNumber(value: 20), "delayAfterTrigger": 30]
        let inApp3: NSDictionary = ["ti": NSNumber(value: 30), "delayAfterTrigger": 60]
        let result = strategy.selectInApps([inApp1, inApp2, inApp3], suppressionHandler: { _ in false })
        // One for delay 30, one for delay 60.
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first(where: { ($0["delayAfterTrigger"] as? NSNumber)?.intValue == 30 })?["ti"] as? NSNumber,
                       NSNumber(value: 10), "The first in-app in the delay group should win")
    }

    // suppressionHandler records suppression as a side effect, so it must be
    // invoked exactly once per in-app it is asked about.
    func testDelayed_selectInApps_invokesSuppressionHandlerOncePerInApp() {
        let inApp1: NSDictionary = ["ti": NSNumber(value: 10), "delayAfterTrigger": 30]
        let inApp2: NSDictionary = ["ti": NSNumber(value: 20), "delayAfterTrigger": 60]
        var callCounts: [Int: Int] = [:]
        _ = strategy.selectInApps([inApp1, inApp2], suppressionHandler: { inApp in
            let id = (inApp["ti"] as? NSNumber)?.intValue ?? -1
            callCounts[id, default: 0] += 1
            return false
        })
        XCTAssertEqual(callCounts[10], 1)
        XCTAssertEqual(callCounts[20], 1)
    }
}
