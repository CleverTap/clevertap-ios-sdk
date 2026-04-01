//
//  InAppDataExtractorTests.swift
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import XCTest
@testable import CleverTapSDK

// MARK: - DelayedInAppDataExtractor

class DelayedInAppDataExtractorTests: XCTestCase {

    var extractor: DelayedInAppDataExtractor!

    override func setUp() {
        super.setUp()
        extractor = DelayedInAppDataExtractor()
    }

    override func tearDown() {
        extractor = nil
        super.tearDown()
    }

    // MARK: - extractDelay

    func test_extractDelay_withIntValue_returnsTimeInterval() {
        let inApp: [String: Any] = [InAppDelayConstants.INAPP_DELAY_AFTER_TRIGGER: 30]
        XCTAssertEqual(extractor.extractDelay(inApp: inApp), 30)
    }

    func test_extractDelay_missingKey_returnsZero() {
        let inApp: [String: Any] = ["type": "interstitial"]
        XCTAssertEqual(extractor.extractDelay(inApp: inApp), 0)
    }

    func test_extractDelay_emptyDict_returnsZero() {
        XCTAssertEqual(extractor.extractDelay(inApp: [:]), 0)
    }

    func test_extractDelay_maxDelay_returnsCorrectValue() {
        let inApp: [String: Any] = [InAppDelayConstants.INAPP_DELAY_AFTER_TRIGGER: 1200]
        XCTAssertEqual(extractor.extractDelay(inApp: inApp), 1200)
    }

    // MARK: - createSuccessResult

    func test_createSuccessResult_returnsDelayedInAppResult() {
        let data: [String: Any] = ["key": "value"]
        let result = extractor.createSuccessResult(id: "id1", data: data)
        XCTAssertTrue(result is CTDelayedInAppResult)
    }

    func test_createSuccessResult_typeIsSuccess() {
        let result = extractor.createSuccessResult(id: "id1", data: ["k": "v"]) as! CTDelayedInAppResult
        XCTAssertEqual(result.type, .success)
    }

    func test_createSuccessResult_setsResultId() {
        let result = extractor.createSuccessResult(id: "myId", data: [:]) as! CTDelayedInAppResult
        XCTAssertEqual(result.resultId, "myId")
    }

    func test_createSuccessResult_setsData() {
        let data: [String: Any] = ["answer": 42]
        let result = extractor.createSuccessResult(id: "id1", data: data) as! CTDelayedInAppResult
        XCTAssertEqual(result.data?["answer"] as? Int, 42)
    }

    // MARK: - createErrorResult

    func test_createErrorResult_returnsDelayedInAppResult() {
        let result = extractor.createErrorResult(id: "id2", message: "something failed")
        XCTAssertTrue(result is CTDelayedInAppResult)
    }

    func test_createErrorResult_typeIsError() {
        let result = extractor.createErrorResult(id: "id2", message: "oops") as! CTDelayedInAppResult
        XCTAssertEqual(result.type, .error)
    }

    func test_createErrorResult_setsResultId() {
        let result = extractor.createErrorResult(id: "errId", message: "msg") as! CTDelayedInAppResult
        XCTAssertEqual(result.resultId, "errId")
    }

    func test_createErrorResult_hasNonNilException() {
        let result = extractor.createErrorResult(id: "id2", message: "fail") as! CTDelayedInAppResult
        XCTAssertNotNil(result.exception)
    }

    func test_createErrorResult_exceptionDomainIsDelayedInAppError() {
        let result = extractor.createErrorResult(id: "id2", message: "fail") as! CTDelayedInAppResult
        let nsError = result.exception as? NSError
        XCTAssertEqual(nsError?.domain, "DelayedInAppError")
    }

    // MARK: - createDiscardedResult

    func test_createDiscardedResult_returnsDelayedInAppResult() {
        let result = extractor.createDiscardedResult(id: "id3")
        XCTAssertTrue(result is CTDelayedInAppResult)
    }

    func test_createDiscardedResult_typeIsDiscarded() {
        let result = extractor.createDiscardedResult(id: "id3") as! CTDelayedInAppResult
        XCTAssertEqual(result.type, .discarded)
    }

    func test_createDiscardedResult_setsResultId() {
        let result = extractor.createDiscardedResult(id: "discardedId") as! CTDelayedInAppResult
        XCTAssertEqual(result.resultId, "discardedId")
    }

    func test_createDiscardedResult_messageIsNotNil() {
        let result = extractor.createDiscardedResult(id: "id3") as! CTDelayedInAppResult
        XCTAssertNotNil(result.message)
    }
}

// MARK: - InActionDataExtractor

class InActionDataExtractorTests: XCTestCase {

    var extractor: InActionDataExtractor!

    override func setUp() {
        super.setUp()
        extractor = InActionDataExtractor()
    }

    override func tearDown() {
        extractor = nil
        super.tearDown()
    }

    // MARK: - extractDelay

    func test_extractDelay_intValue_returnsTimeInterval() {
        let inApp: [String: Any] = ["inactionDuration": 60]
        XCTAssertEqual(extractor.extractDelay(inApp: inApp), 60)
    }

    func test_extractDelay_doubleValue_returnsTimeInterval() {
        let inApp: [String: Any] = ["inactionDuration": Double(45.0)]
        XCTAssertEqual(extractor.extractDelay(inApp: inApp), 45)
    }

    func test_extractDelay_missingKey_returnsZero() {
        XCTAssertEqual(extractor.extractDelay(inApp: [:]), 0)
    }

    // MARK: - createSuccessResult

    func test_createSuccessResult_returnsInActionResult() {
        let result = extractor.createSuccessResult(id: "a1", data: ["k": "v"])
        XCTAssertTrue(result is CTInActionResult)
    }

    func test_createSuccessResult_typeIsReadyToFetch() {
        let result = extractor.createSuccessResult(id: "a1", data: [:]) as! CTInActionResult
        XCTAssertEqual(result.type, .readyToFetch)
    }

    func test_createSuccessResult_setsId() {
        let result = extractor.createSuccessResult(id: "myInAction", data: [:]) as! CTInActionResult
        XCTAssertEqual(result.inActionId, "myInAction")
    }

    // MARK: - createErrorResult

    func test_createErrorResult_returnsInActionResult() {
        let result = extractor.createErrorResult(id: "a2", message: "fail")
        XCTAssertTrue(result is CTInActionResult)
    }

    func test_createErrorResult_typeIsError() {
        let result = extractor.createErrorResult(id: "a2", message: "fail") as! CTInActionResult
        XCTAssertEqual(result.type, .error)
    }

    func test_createErrorResult_setsId() {
        let result = extractor.createErrorResult(id: "errId", message: "oops") as! CTInActionResult
        XCTAssertEqual(result.inActionId, "errId")
    }

    // MARK: - createDiscardedResult

    func test_createDiscardedResult_returnsInActionResult() {
        let result = extractor.createDiscardedResult(id: "a3")
        XCTAssertTrue(result is CTInActionResult)
    }

    func test_createDiscardedResult_typeIsDiscarded() {
        let result = extractor.createDiscardedResult(id: "a3") as! CTInActionResult
        XCTAssertEqual(result.type, .discarded)
    }

    func test_createDiscardedResult_setsId() {
        let result = extractor.createDiscardedResult(id: "dId") as! CTInActionResult
        XCTAssertEqual(result.inActionId, "dId")
    }
}
