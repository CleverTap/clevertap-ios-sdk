//
//  InAppDurationPartitionerTests.swift
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import XCTest
@testable import CleverTapSDK

class InAppDurationPartitionerTests: XCTestCase {

    // MARK: - partitionImmediateDelayedInApps

    func testPartitionImmediateDelayed_nilInput_returnsEmpty() {
        let result = InAppDurationPartitioner.partitionImmediateDelayedInApps(nil)
        XCTAssertEqual(result.immediateInApps.count, 0)
        XCTAssertEqual(result.delayedInApps.count, 0)
    }

    func testPartitionImmediateDelayed_noDelay_allImmediate() {
        let inApp: NSDictionary = ["ti": 1, "type": "interstitial"]
        let result = InAppDurationPartitioner.partitionImmediateDelayedInApps([inApp])
        XCTAssertEqual(result.immediateInApps.count, 1)
        XCTAssertEqual(result.delayedInApps.count, 0)
    }

    func testPartitionImmediateDelayed_validDelay_goesToDelayed() {
        let inApp: NSDictionary = ["ti": 2, "delayAfterTrigger": 30]
        let result = InAppDurationPartitioner.partitionImmediateDelayedInApps([inApp])
        XCTAssertEqual(result.delayedInApps.count, 1)
        XCTAssertEqual(result.immediateInApps.count, 0)
    }

    func testPartitionImmediateDelayed_zeroDelay_goesToImmediate() {
        let inApp: NSDictionary = ["ti": 3, "delayAfterTrigger": 0]
        let result = InAppDurationPartitioner.partitionImmediateDelayedInApps([inApp])
        XCTAssertEqual(result.immediateInApps.count, 1)
        XCTAssertEqual(result.delayedInApps.count, 0)
    }

    func testPartitionImmediateDelayed_maxDelay_goesToDelayed() {
        let inApp: NSDictionary = ["ti": 4, "delayAfterTrigger": 1200]
        let result = InAppDurationPartitioner.partitionImmediateDelayedInApps([inApp])
        XCTAssertEqual(result.delayedInApps.count, 1)
        XCTAssertEqual(result.immediateInApps.count, 0)
    }

    func testPartitionImmediateDelayed_overMaxDelay_goesToImmediate() {
        let inApp: NSDictionary = ["ti": 5, "delayAfterTrigger": 1201]
        let result = InAppDurationPartitioner.partitionImmediateDelayedInApps([inApp])
        XCTAssertEqual(result.immediateInApps.count, 1)
        XCTAssertEqual(result.delayedInApps.count, 0)
    }

    // MARK: - partitionServerSideMetaInApps

    func testPartitionServerSideMeta_nilInput_returnsEmpty() {
        let result = InAppDurationPartitioner.partitionServerSideMetaInApps(nil)
        XCTAssertEqual(result.unknownDurationInApps.count, 0)
        XCTAssertEqual(result.inActionInApps.count, 0)
    }

    func testPartitionServerSideMeta_validInAction_goesToInAction() {
        let inApp: NSDictionary = ["ti": 6, "inactionDuration": 60]
        let result = InAppDurationPartitioner.partitionServerSideMetaInApps([inApp])
        XCTAssertEqual(result.inActionInApps.count, 1)
        XCTAssertEqual(result.unknownDurationInApps.count, 0)
    }

    func testPartitionServerSideMeta_noInAction_goesToUnknown() {
        let inApp: NSDictionary = ["ti": 7, "type": "interstitial"]
        let result = InAppDurationPartitioner.partitionServerSideMetaInApps([inApp])
        XCTAssertEqual(result.unknownDurationInApps.count, 1)
        XCTAssertEqual(result.inActionInApps.count, 0)
    }

    func testPartitionServerSideMeta_zeroInAction_goesToUnknown() {
        let inApp: NSDictionary = ["ti": 8, "inactionDuration": 0]
        let result = InAppDurationPartitioner.partitionServerSideMetaInApps([inApp])
        XCTAssertEqual(result.unknownDurationInApps.count, 1)
        XCTAssertEqual(result.inActionInApps.count, 0)
    }
}
