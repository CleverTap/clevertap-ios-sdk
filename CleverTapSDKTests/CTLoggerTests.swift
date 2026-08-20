//
//  CTLoggerTests.swift
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import XCTest
@testable import CleverTapSDK

class CTLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset debug level to a known state before each test
        CTLogger.setDebugLevel(0)
    }

    override func tearDown() {
        CTLogger.setDebugLevel(0)
        super.tearDown()
    }

    func testSetAndGetDebugLevel() {
        CTLogger.setDebugLevel(3)
        XCTAssertEqual(CTLogger.getDebugLevel(), 3)
    }

    func testGetDebugLevel_defaultIsZero() {
        XCTAssertEqual(CTLogger.getDebugLevel(), 0)
    }

    func testLogWithLevel_infoTypeAtLevelZero_doesNotCrash() {
        // info type is allowed at level >= 0; should not crash
        CTLogger.logWithLevel(0, type: CTLogType.info.rawValue, message: "info test message")
    }

    func testLogWithLevel_debugTypeAtLevelZero_doesNotCrash() {
        // debug type requires level > 0; with level 0 it should return early without crashing
        CTLogger.logWithLevel(0, type: CTLogType.debug.rawValue, message: "debug suppressed message")
    }

    func testLogWithLevel_debugTypeAtLevelOne_doesNotCrash() {
        // debug type with level > 0 should log without crashing
        CTLogger.logWithLevel(1, type: CTLogType.debug.rawValue, message: "debug active message")
    }

    func testLogWithLevel_invalidType_doesNotCrash() {
        // Type value 99 is not a valid CTLogType; guard let should return early
        CTLogger.logWithLevel(1, type: 99, message: "invalid type message")
    }

    func testLogInternalError_doesNotCrash() {
        let exception = NSException(name: NSExceptionName("TestException"),
                                    reason: "Test reason",
                                    userInfo: nil)
        CTLogger.logInternalError(exception)
    }

    func testLogInternalError_withActiveDebugLevel_doesNotCrash() {
        CTLogger.setDebugLevel(1)
        let exception = NSException(name: NSExceptionName("TestException"),
                                    reason: "Testing logInternalError at debug level",
                                    userInfo: nil)
        CTLogger.logInternalError(exception)
    }
}
