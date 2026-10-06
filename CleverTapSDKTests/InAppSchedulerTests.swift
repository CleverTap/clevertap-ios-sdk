//
//  InAppSchedulerTests.swift
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import XCTest
@testable import CleverTapSDK

// MARK: - Stubs

private final class StubStorageStrategy: NSObject, InAppSchedulingStrategy {
    var prepareResult = true
    var prepareCallCount = 0
    var receivedInApps: [[String: Any]] = []
    var onPrepare: (() -> Void)?

    func prepareForScheduling(inApps: [[String: Any]]) -> Bool {
        prepareCallCount += 1
        receivedInApps = inApps
        onPrepare?()
        return prepareResult
    }

    func retrieveAfterTimer(id: String) -> [String: Any]? { return nil }

    func clearAll() {}
}

private final class StubDataExtractor: NSObject, InAppDataExtractor {
    func extractDelay(inApp: [String: Any]) -> TimeInterval {
        return (inApp[InAppDelayConstants.INAPP_DELAY_AFTER_TRIGGER] as? NSNumber)?.doubleValue ?? 0
    }

    func createSuccessResult(id: String, data: [String: Any]) -> Any { return "success:\(id)" }
    func createErrorResult(id: String, message: String) -> Any { return "error:\(id):\(message)" }
    func createDiscardedResult(id: String) -> Any { return "discarded:\(id)" }
}

// MARK: - Tests

class InAppSchedulerTests: XCTestCase {

    private var timerManager: InAppTimerManager!
    private var storage: StubStorageStrategy!
    private var extractor: StubDataExtractor!
    private var scheduler: CTInAppScheduler!

    override func setUp() {
        super.setUp()
        timerManager = InAppTimerManager(tagSuffix: "Test")
        storage = StubStorageStrategy()
        extractor = StubDataExtractor()
        scheduler = CTInAppScheduler(timerManager: timerManager,
                                     storageStrategy: storage,
                                     dataExtractor: extractor)
    }

    override func tearDown() {
        timerManager.cancelAllTimers()
        super.tearDown()
    }

    private func inApp(id: Any, delay: Any) -> [String: Any] {
        return [InAppDelayConstants.INAPP_ID_IN_PAYLOAD: id,
                InAppDelayConstants.INAPP_DELAY_AFTER_TRIGGER: delay]
    }

    // MARK: - Preparation failure path

    // Ids are stringified rather than cast, so a numeric ti must still produce a
    // callback. A String-only cast here would emit nothing at all.
    func testSchedule_preparationFails_emitsOneErrorPerSchedulableInApp_withNumericIds() {
        storage.prepareResult = false
        let expectation = self.expectation(description: "callbacks")
        expectation.expectedFulfillmentCount = 2

        var results: [String] = []
        let lock = NSLock()
        scheduler.schedule(inApps: [inApp(id: NSNumber(value: 10), delay: 30),
                                    inApp(id: NSNumber(value: 20), delay: 60)]) { result in
            lock.lock()
            results.append(result as? String ?? "nil")
            lock.unlock()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains("error:10:Preparation failed"), "got \(results)")
        XCTAssertTrue(results.contains("error:20:Preparation failed"), "got \(results)")
    }

    // MARK: - Only schedulable in-apps reach the storage strategy

    func testSchedule_prepareReceivesOnlyInAppsThatWillGetATimer() {
        let expectation = self.expectation(description: "prepare called")
        storage.onPrepare = { expectation.fulfill() }

        scheduler.schedule(inApps: [inApp(id: NSNumber(value: 10), delay: 30),
                                    inApp(id: NSNumber(value: 20), delay: 0),
                                    inApp(id: NSNumber(value: 30), delay: -5),
                                    inApp(id: "", delay: 30)]) { _ in }

        waitForExpectations(timeout: 2)
        // Only id 10 has a positive delay and a usable id. Storing the others
        // would leave entries nothing ever retrieves.
        XCTAssertEqual(storage.receivedInApps.count, 1)
        let storedId = storage.receivedInApps.first?[InAppDelayConstants.INAPP_ID_IN_PAYLOAD] as? NSNumber
        XCTAssertEqual(storedId, NSNumber(value: 10))
    }

    func testSchedule_noSchedulableInApps_doesNotCallPrepare() {
        scheduler.schedule(inApps: [inApp(id: NSNumber(value: 10), delay: 0),
                                    inApp(id: NSNumber(value: 20), delay: -1)]) { _ in }

        // No expectation to wait on, so drain the scheduler's queue via a
        // separate call whose completion we can observe.
        let drained = self.expectation(description: "queue drained")
        storage.onPrepare = { drained.fulfill() }
        scheduler.schedule(inApps: [inApp(id: NSNumber(value: 99), delay: 30)]) { _ in }
        waitForExpectations(timeout: 2)

        // Exactly one prepare, from the second call only.
        XCTAssertEqual(storage.prepareCallCount, 1)
        XCTAssertEqual(storage.receivedInApps.count, 1)
    }

    // MARK: - Already scheduled in-apps are filtered

    func testSchedule_alreadyScheduledId_isNotPreparedAgain() {
        // Occupy the id with a long-running timer.
        timerManager.scheduleTimer(id: "10", delay: 60) { _ in }

        let expectation = self.expectation(description: "prepare called")
        storage.onPrepare = { expectation.fulfill() }

        scheduler.schedule(inApps: [inApp(id: NSNumber(value: 10), delay: 30),
                                    inApp(id: NSNumber(value: 20), delay: 30)]) { _ in }

        waitForExpectations(timeout: 2)
        XCTAssertEqual(storage.receivedInApps.count, 1)
        let storedId = storage.receivedInApps.first?[InAppDelayConstants.INAPP_ID_IN_PAYLOAD] as? NSNumber
        XCTAssertEqual(storedId, NSNumber(value: 20), "the already-scheduled id 10 should be filtered out")
    }

    // MARK: - Timer completion

    // MARK: - Cancel all scheduling

    // On a user switch the schedulers are told to cancel everything, so a timer
    // set up for the previous user can't fire for the next one.
    func testCancelAllScheduling_cancelsActiveTimers() {
        timerManager.scheduleTimer(id: "10", delay: 60) { _ in }
        timerManager.scheduleTimer(id: "20", delay: 60) { _ in }
        XCTAssertEqual(timerManager.getActiveTimerCount(), 2)

        let cancelled = expectation(description: "cancelled")
        scheduler.cancelAllScheduling { cancelled.fulfill() }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(timerManager.getActiveTimerCount(), 0)
    }

    func testSchedule_timerFires_invokesCallbackWithErrorWhenDataMissing() {
        // retrieveAfterTimer returns nil in the stub, so the success path reports
        // "Data not found" rather than silently dropping the callback.
        let expectation = self.expectation(description: "timer fired")
        var result: String?
        scheduler.schedule(inApps: [inApp(id: NSNumber(value: 10), delay: 0.2)]) { value in
            result = value as? String
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3)
        XCTAssertEqual(result, "error:10:Data not found")
    }
}
