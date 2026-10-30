// CTLimitsMatcherTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTLimitsMatcher — mirrors CTLimitsMatcherTest.m.
//
// CTLimitsMatcher is still Objective-C at this point (Phase 1 runs these tests against the existing
// ObjC source). It checks a campaign's `whenLimits` (session / seconds / minutes / hours / days /
// weeks / ever / onEvery / onExactly) against the live impression + trigger counters.
//
// This is a stateful suite: it drives a real CTImpressionManager (with an injected CTClockMock) and
// CTInAppTriggerManager keyed by a fixed test campaign id, so it is a class (one instance per test,
// deinit runs after) and `.serialized`. init + deinit clear that campaign's counters for isolation.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTLimitsMatcher", .serialized)
final class CTLimitsMatcherTests {

    private let limitsMatcher = CTLimitsMatcher()
    private let impressionManager: CTImpressionManager
    private let inAppTriggerManager: CTInAppTriggerManager
    private let mockClock: CTClockMock
    private let campaignId: String

    init() {
        let helper = InAppHelper()
        campaignId = helper.campaignId()
        let clock = CTClockMock(currentDate: Date())
        mockClock = clock
        impressionManager = CTImpressionManager(accountId: helper.accountId(),
                                                deviceId: helper.deviceId(),
                                                delegateManager: helper.delegateManager,
                                                clock: clock,
                                                locale: Locale.current)
        inAppTriggerManager = helper.inAppTriggerManager
        clearCounters()
    }

    deinit {
        clearCounters()
    }

    private func clearCounters() {
        inAppTriggerManager.removeTriggers(campaignId)
        impressionManager.removeImpressions(campaignId)
    }

    private func match(_ whenLimits: [Any]) -> Bool {
        limitsMatcher.match(whenLimits: whenLimits,
                                      forCampaignId: campaignId,
                                      with: impressionManager,
                                      andTriggerManager: inAppTriggerManager)
    }

    private func incrementTrigger(_ times: Int) {
        for _ in 0..<times { inAppTriggerManager.incrementTrigger(campaignId) }
    }

    private func recordImpression(_ times: Int) {
        for _ in 0..<times { impressionManager.recordImpression(campaignId) }
    }

    // MARK: - onExactly

    @Test("onExactly below the limit does not match")
    func matchOnExactlyLessThanLimit() {
        incrementTrigger(1)
        #expect(!match([["type": "onExactly", "limit": 6]]))
    }

    @Test("onExactly at the limit matches")
    func matchOnExactly() {
        incrementTrigger(6)
        #expect(match([["type": "onExactly", "limit": 6]]))
    }

    // MARK: - onEvery

    @Test("onEvery at a multiple of the limit matches")
    func matchOnEvery() {
        incrementTrigger(12)
        #expect(match([["type": "onEvery", "limit": 6]]))
    }

    @Test("onEvery between multiples does not match")
    func matchOnEveryIntermediate() {
        incrementTrigger(2)
        #expect(!match([["type": "onEvery", "limit": 6]]))
    }

    // MARK: - ever

    @Test("ever under the lifetime limit matches")
    func matchEver() {
        #expect(match([["type": "ever", "limit": 6]]))
    }

    @Test("ever over the lifetime limit does not match")
    func matchEverLimitExceeded() {
        recordImpression(7)
        #expect(!match([["type": "ever", "limit": 6]]))
    }

    // MARK: - session

    @Test("session under the limit matches")
    func matchSession() {
        recordImpression(1)
        #expect(match([["type": "session", "limit": 6]]))
    }

    @Test("session over the limit does not match")
    func matchSessionLimitExceeded() {
        recordImpression(7)
        #expect(!match([["type": "session", "limit": 6]]))
    }

    // MARK: - seconds

    @Test("seconds under the limit matches")
    func matchSeconds() {
        recordImpression(2)
        #expect(match([["type": "seconds", "limit": 6, "frequency": 12]]))
    }

    @Test("seconds over the limit does not match")
    func matchSecondsLimitExceeded() {
        recordImpression(7)
        #expect(!match([["type": "seconds", "limit": 6, "frequency": 12]]))
    }

    // MARK: - minutes / hours / days / weeks (time-windowed)

    @Test("minutes window counts only impressions inside the frequency window")
    func matchMinutes() {
        let limits: [Any] = [["type": "minutes", "limit": 3, "frequency": 10]]
        recordImpression(2)
        #expect(match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(5 * 60)
        recordImpression(1)
        #expect(!match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(5 * 60 + 1)
        #expect(match(limits))
    }

    @Test("hours window counts only impressions inside the frequency window")
    func matchHours() {
        let limits: [Any] = [["type": "hours", "limit": 3, "frequency": 2]]
        recordImpression(2)
        #expect(match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(1 * 60 * 60)
        recordImpression(1)
        #expect(!match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(1 * 60 * 60 + 1)
        #expect(match(limits))
    }

    @Test("days window counts only impressions inside the frequency window")
    func matchDays() {
        let limits: [Any] = [["type": "days", "limit": 3, "frequency": 2]]
        recordImpression(2)
        #expect(match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(24 * 60 * 60)
        recordImpression(1)
        #expect(!match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(24 * 60 * 60 + 1)
        #expect(match(limits))
    }

    @Test("weeks window counts only impressions inside the frequency window")
    func matchWeeks() {
        let limits: [Any] = [["type": "weeks", "limit": 3, "frequency": 2]]
        recordImpression(2)
        #expect(match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(7 * 24 * 60 * 60)
        recordImpression(1)
        #expect(!match(limits))

        mockClock.currentDate = mockClock.currentDate.addingTimeInterval(7 * 24 * 60 * 60 + 1)
        #expect(match(limits))
    }

    // MARK: - multiple limits (AND-ed)

    @Test("multiple limits must all match")
    func matchMultiple() {
        let limits: [Any] = [
            ["type": "onExactly", "limit": 1],
            ["type": "days", "limit": 3, "frequency": 1],
            ["type": "session", "limit": 6]
        ]
        incrementTrigger(1)
        #expect(match(limits))

        recordImpression(2)
        #expect(match(limits))

        // Impressions per day no longer match.
        recordImpression(1)
        #expect(!match(limits))

        // Reset impressions and increment the trigger, so onExactly no longer matches.
        impressionManager.removeImpressions(campaignId)
        incrementTrigger(1)
        #expect(!match(limits))
    }

    // MARK: - empty / invalid

    @Test("an empty limit, and an empty list, match")
    func matchEmpty() {
        // An entry with no type is skipped (isEmpty); an empty list has nothing to fail.
        // (The literal-nil list is ObjC-only — Swift can't pass nil to the nonnull parameter;
        //  an empty array yields the same result.)
        #expect(match([[:]]))
        #expect(match([]))
    }

    @Test("an empty campaign id does not match")
    func matchEmptyCampaignId() {
        let matched = limitsMatcher.match(whenLimits: [["type": "session", "limit": 6]],
                                                    forCampaignId: "",
                                                    with: impressionManager,
                                                    andTriggerManager: inAppTriggerManager)
        #expect(!matched)
    }
}
