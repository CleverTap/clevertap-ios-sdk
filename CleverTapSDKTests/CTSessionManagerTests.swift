// CTSessionManagerTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTSessionManager.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// Design notes:
// - Struct-based suite: Swift Testing creates a fresh instance before every
//   @Test function, so init() acts as setUp for each test.
// - .serialized prevents parallel execution within the suite — all tests share
//   the same CTSessionManager/CleverTap singleton's CTPreferences storage.
// - The CleverTap instance (needed for pushInstallReferrerSource tests) is held
//   in a static property so CTPushPrimerManager — and its UNUserNotificationCenter
//   .getNotificationSettings call — is initialised exactly once per test run,
//   not before every test. This avoids concurrent UNCenter calls that would
//   cause the XCTest push-permission tests to time out.

import Testing
@testable import CleverTapSDK

@Suite("CTSessionManager", .serialized)
struct CTSessionManagerSwiftTests {

    // Created once for the entire test run. CTPushPrimerManager.init fires here,
    // its async getNotificationSettings call completes well before the XCTest
    // notification-permission tests execute.
    private static let sharedInstance: CleverTap = {
        let cfg = CleverTapInstanceConfig(accountId: "testSwiftSM", accountToken: "testSwiftSM")
        return CleverTap.instance(with: cfg)
    }()
    private static let sharedConfig = CleverTapInstanceConfig(
        accountId: "testSwiftSM", accountToken: "testSwiftSM"
    )

    let instance: CleverTap
    let config: CleverTapInstanceConfig
    let sessionManager: CTSessionManager

    init() {
        instance = Self.sharedInstance
        config = Self.sharedConfig
        sessionManager = instance.sessionManager
        // Reset any state persisted by a previous test, then start a clean session.
        sessionManager.resetSession()
        sessionManager.minSessionSeconds = Int(CLTAP_SESSION_LENGTH_MINS) * 60
        sessionManager.createSessionIfNeeded()
    }

    // MARK: - Basic session state

    @Test("Session ID is positive after createSession")
    func sessionIdIsPositive() {
        #expect(sessionManager.sessionId > 0)
    }

    @Test("Last session time is stored in preferences after createSession")
    func sessionTimeStoredAfterCreate() {
        let ts = CTPreferences.getIntForKey(
            CTPreferences.storageKey(withSuffix: kLastSessionTime, config: config),
            withResetValue: 0
        )
        #expect(ts > 0)
    }

    @Test("firstRequestInSession is true immediately after createSession")
    func firstRequestInSessionIsTrue() {
        #expect(sessionManager.firstRequestInSession)
    }

    // MARK: - Source / Medium / Campaign

    @Test("source, medium, campaign are set via pushInstallReferrerSource")
    func sourceMediumCampaignSetViaInstallReferrer() {
        CTPreferences.removeObject(
            forKey: CTPreferences.storageKey(withSuffix: "install_referrer_status", config: config)
        )
        instance.pushInstallReferrerSource("source", medium: "medium", campaign: "campaign")
        #expect(sessionManager.source == "source")
        #expect(sessionManager.medium == "medium")
        #expect(sessionManager.campaign == "campaign")
    }

    @Test("source cannot be overridden once set in the same session")
    func sourceIsSetOnceViaInstallReferrer() {
        CTPreferences.removeObject(
            forKey: CTPreferences.storageKey(withSuffix: "install_referrer_status", config: config)
        )
        instance.pushInstallReferrerSource("first", medium: "m", campaign: "c")
        instance.pushInstallReferrerSource("second", medium: "m2", campaign: "c2")
        #expect(sessionManager.source == "first")
    }

    // MARK: - resetSession

    @Test("resetSession sets sessionId to zero")
    func resetSessionClearsId() {
        #expect(sessionManager.sessionId > 0)
        sessionManager.resetSession()
        #expect(sessionManager.sessionId == 0)
    }

    @Test("resetSession sets screenCount back to 1")
    func resetSessionSetsScreenCountToOne() {
        sessionManager.screenCount = 5
        sessionManager.resetSession()
        #expect(sessionManager.screenCount == 1)
    }

    @Test("resetSession clears source, medium and campaign")
    func resetSessionClearsUTMFields() {
        CTPreferences.removeObject(
            forKey: CTPreferences.storageKey(withSuffix: "install_referrer_status", config: config)
        )
        instance.pushInstallReferrerSource("source", medium: "medium", campaign: "campaign")
        sessionManager.resetSession()
        #expect(sessionManager.source == nil)
        #expect(sessionManager.medium == nil)
        #expect(sessionManager.campaign == nil)
    }

    @Test("resetSession clears wzrkParams")
    func resetSessionClearsWzrkParams() {
        sessionManager.wzrkParams = ["key": "value"]
        sessionManager.resetSession()
        #expect(sessionManager.wzrkParams == nil)
    }

    @Test("resetSession sets appLaunchProcessed to false")
    func resetSessionClearsAppLaunchProcessed() {
        sessionManager.appLaunchProcessed = true
        sessionManager.resetSession()
        #expect(sessionManager.appLaunchProcessed == false)
    }

    @Test("resetSession sets encryptionInTransitFailed to false")
    func resetSessionClearsEncryptionFailed() {
        sessionManager.encryptionInTransitFailed = true
        sessionManager.resetSession()
        #expect(sessionManager.encryptionInTransitFailed == false)
    }

    // MARK: - wzrkParams set-once guard

    @Test("wzrkParams can only be set once per session")
    func wzrkParamsIsSetOnce() {
        sessionManager.wzrkParams = ["key": "first"]
        sessionManager.wzrkParams = ["key": "second"]
        #expect(sessionManager.wzrkParams?["key"] as? String == "first")
    }

    // MARK: - createSessionIfNeeded

    @Test("createSessionIfNeeded keeps the existing session when already in one")
    func createSessionIfNeededKeepsActiveSession() {
        let existingId = sessionManager.sessionId
        #expect(existingId > 0)
        sessionManager.createSessionIfNeeded()
        #expect(sessionManager.sessionId == existingId)
    }

    @Test("createSessionIfNeeded starts a new session when not in one")
    func createSessionIfNeededStartsSession() {
        sessionManager.resetSession()
        #expect(sessionManager.sessionId == 0)
        sessionManager.createSessionIfNeeded()
        #expect(sessionManager.sessionId > 0)
    }

    // MARK: - updateSessionTime

    @Test("updateSessionTime is a no-op when not in a session")
    func updateSessionTimeNoOpOutsideSession() {
        sessionManager.resetSession()
        #expect(sessionManager.sessionId == 0)
        // resetSession clears kLastSessionTime to 0; an out-of-session update must not write it.
        let lastSessionTimeKey = CTPreferences.storageKey(withSuffix: kLastSessionTime, config: config)
        sessionManager.updateSessionTime(12345)
        #expect(sessionManager.sessionId == 0)
        #expect(CTPreferences.getIntForKey(lastSessionTimeKey, withResetValue: -1) == 0,
                "updateSessionTime must not persist a timestamp while outside a session")
    }

    // MARK: - firstSession flag

    @Test("firstSession is false on a subsequent session")
    func firstSessionFalseOnSubsequentSession() {
        sessionManager.resetSession()
        sessionManager.createSessionIfNeeded()
        #expect(sessionManager.firstSession == false)
    }

    // MARK: - lastSessionLengthSeconds

    @Test("lastSessionLengthSeconds is zero when there is no prior session")
    func lastSessionLengthSecondsZeroWithNoPriorSession() {
        // Shared preferences may still hold a completed session from an earlier test,
        // which resetSession() would otherwise turn into a non-zero length. Clear the
        // persisted session id/time (both suffixed and default-instance fallback keys)
        // so the "no prior session" condition is deterministic.
        CTPreferences.removeObject(forKey: CTPreferences.storageKey(withSuffix: kSessionId, config: config))
        CTPreferences.removeObject(forKey: CTPreferences.storageKey(withSuffix: kLastSessionTime, config: config))
        CTPreferences.removeObject(forKey: kSessionId)
        CTPreferences.removeObject(forKey: kLastSessionPing)
        sessionManager.resetSession()
        #expect(sessionManager.lastSessionLengthSeconds == 0)
    }

    // MARK: - minSessionSeconds default

    @Test("minSessionSeconds defaults to CLTAP_SESSION_LENGTH_MINS × 60")
    func minSessionSecondsHasCorrectDefault() {
        // Use a fresh manager so the default set by the initializer is verified,
        // not the value the fixture's init() reassigns onto the shared instance.
        let freshConfig = CleverTapInstanceConfig(accountId: "testFreshSM", accountToken: "testFreshSM")
        let freshManager = CTSessionManager(
            config: freshConfig,
            validationConfig: CTValidationConfig.defaultConfig(withCountryCode: nil)
        )
        #expect(freshManager.minSessionSeconds == 20 * 60) // CLTAP_SESSION_LENGTH_MINS * 60
    }

    // MARK: - updateSessionStateOnLaunch

    @Test("updateSessionStateOnLaunch creates a session when not in one")
    func updateOnLaunchCreatesSessionWhenNone() {
        sessionManager.resetSession()
        #expect(sessionManager.sessionId == 0)
        sessionManager.updateSessionStateOnLaunch()
        #expect(sessionManager.sessionId > 0)
    }

    @Test("updateSessionStateOnLaunch keeps the active session when it has not timed out")
    func updateOnLaunchKeepsActiveSession() {
        let originalId = sessionManager.sessionId
        #expect(originalId > 0)
        sessionManager.minSessionSeconds = 3600
        sessionManager.updateSessionStateOnLaunch()
        #expect(sessionManager.sessionId == originalId)
    }

    @Test("updateSessionStateOnLaunch creates a new session when the current one has timed out")
    func updateOnLaunchRecreatesTimedOutSession() {
        #expect(sessionManager.sessionId > 0)
        // minSessionSeconds = -1 means any elapsed time satisfies the ">" check
        sessionManager.minSessionSeconds = -1
        sessionManager.firstRequestInSession = false
        sessionManager.updateSessionStateOnLaunch()
        // createSession() sets firstRequestInSession = true — confirms new session was created
        #expect(sessionManager.firstRequestInSession == true)
        #expect(sessionManager.sessionId > 0)
    }
}
