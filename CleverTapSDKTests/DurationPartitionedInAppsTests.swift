//
//  DurationPartitionedInAppsTests.swift
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import XCTest
@testable import CleverTapSDK

class DurationPartitionedInAppsTests: XCTestCase {

    // MARK: - UnknownAndInAction

    func testUnknownAndInAction_hasUnknownDurationInApps_trueWhenNonEmpty() {
        let inApp: NSDictionary = ["key": "value"]
        let partition = UnknownAndInAction(unknownDurationInApps: [inApp], inActionInApps: [])
        XCTAssertTrue(partition.hasUnknownDurationInApps())
    }

    func testUnknownAndInAction_hasUnknownDurationInApps_falseWhenEmpty() {
        let partition = UnknownAndInAction(unknownDurationInApps: [], inActionInApps: [])
        XCTAssertFalse(partition.hasUnknownDurationInApps())
    }

    func testUnknownAndInAction_hasInActionInApps_trueWhenNonEmpty() {
        let inApp: NSDictionary = ["inactionDuration": 60]
        let partition = UnknownAndInAction(unknownDurationInApps: [], inActionInApps: [inApp])
        XCTAssertTrue(partition.hasInActionInApps())
    }

    func testUnknownAndInAction_hasInActionInApps_falseWhenEmpty() {
        let partition = UnknownAndInAction(unknownDurationInApps: [], inActionInApps: [])
        XCTAssertFalse(partition.hasInActionInApps())
    }

    func testUnknownAndInAction_empty_returnsBothArraysEmpty() {
        let partition = UnknownAndInAction.empty()
        XCTAssertEqual(partition.unknownDurationInApps.count, 0)
        XCTAssertEqual(partition.inActionInApps.count, 0)
        XCTAssertFalse(partition.hasUnknownDurationInApps())
        XCTAssertFalse(partition.hasInActionInApps())
    }
}
