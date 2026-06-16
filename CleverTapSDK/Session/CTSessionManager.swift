// CTSessionManager.swift
// CleverTapSDK
//
// Swift replacement for CTSessionManager.m.
// All members are exposed to Objective-C via @objcMembers so existing ObjC
// callers (CleverTap.m) continue to work unchanged.

import Foundation

@objcMembers
public final class CTSessionManager: NSObject {

    // MARK: - Private stored state

    private let config: CleverTapInstanceConfig
    private let validationConfig: CTValidationConfig

#if !CLEVERTAP_NO_INAPP_SUPPORT
    private var impressionManager: CTImpressionManager?
    private var inAppStore: CTInAppStore?
#endif

    // Lock used for properties that were `atomic` in ObjC or require set-once semantics.
    private let lock = NSLock()

    // Backing variables for properties with custom getter/setter logic.
    private var _sessionId: Int = 0
    private var _source: String?
    private var _medium: String?
    private var _campaign: String?
    private var _wzrkParams: [AnyHashable: Any]?
    private var _firstRequestInSession: Bool = false

    // MARK: - Internal properties (no ObjC callers — accessible via @testable import in Swift tests)

    /// Minimum number of seconds before a session is considered expired.
    var minSessionSeconds: Int = Int(CLTAP_SESSION_LENGTH_MINS) * 60

    // MARK: - Public properties

    /// Current session identifier (Unix timestamp of session start).
    /// Writing persists the value to CTPreferences.
    public var sessionId: Int {
        get {
            lock.lock(); defer { lock.unlock() }
            return _sessionId
        }
        set {
            lock.lock()
            _sessionId = newValue
            lock.unlock()
            CTPreferences.put(newValue,
                                 forKey: CTPreferences.storageKey(withSuffix: kSessionId, config: config))
        }
    }

    public var screenCount: Int32 = 0
    public var firstSession: Bool = false
    public var lastSessionLengthSeconds: Int32 = 0
    public var appLaunchProcessed: Bool = false
    public var encryptionInTransitFailed: Bool = false

    /// Set-once per session — subsequent writes are silently ignored.
    public var source: String? {
        get { lock.lock(); defer { lock.unlock() }; return _source }
        set {
            lock.lock()
            if _source == nil { _source = newValue }
            lock.unlock()
        }
    }

    /// Set-once per session — subsequent writes are silently ignored.
    public var medium: String? {
        get { lock.lock(); defer { lock.unlock() }; return _medium }
        set {
            lock.lock()
            if _medium == nil { _medium = newValue }
            lock.unlock()
        }
    }

    /// Set-once per session — subsequent writes are silently ignored.
    public var campaign: String? {
        get { lock.lock(); defer { lock.unlock() }; return _campaign }
        set {
            lock.lock()
            if _campaign == nil { _campaign = newValue }
            lock.unlock()
        }
    }

    /// Set-once per session — subsequent writes are silently ignored.
    public var wzrkParams: [AnyHashable: Any]? {
        get { lock.lock(); defer { lock.unlock() }; return _wzrkParams }
        set {
            lock.lock()
            if _wzrkParams == nil { _wzrkParams = newValue }
            lock.unlock()
        }
    }

    public var firstRequestInSession: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _firstRequestInSession }
        set { lock.lock(); _firstRequestInSession = newValue; lock.unlock() }
    }

    // MARK: - Initialisers

#if !CLEVERTAP_NO_INAPP_SUPPORT
    @objc(initWithConfig:impressionManager:inAppStore:validationConfig:)
    public init(config: CleverTapInstanceConfig,
         impressionManager: CTImpressionManager,
         inAppStore: CTInAppStore,
         validationConfig: CTValidationConfig) {
        self.config = config
        self.impressionManager = impressionManager
        self.inAppStore = inAppStore
        self.validationConfig = validationConfig
        super.init()
        self.minSessionSeconds = Int(CLTAP_SESSION_LENGTH_MINS) * 60
    }
#endif

    @objc(initWithConfig:validationConfig:)
    public init(config: CleverTapInstanceConfig, validationConfig: CTValidationConfig) {
        self.config = config
        self.validationConfig = validationConfig
        super.init()
        self.minSessionSeconds = Int(CLTAP_SESSION_LENGTH_MINS) * 60
    }

    // MARK: - Public API

    public func createSessionIfNeeded() {
        guard !CTUIUtils.runningInsideAppExtension(), !inCurrentSession() else { return }
        resetSession()
        createSession()
    }

    public func updateSessionStateOnLaunch() {
        guard inCurrentSession() else {
            resetSession()
            createSession()
            return
        }
        CTLogger.logWithLevel(Int32(config.logLevel.rawValue),
                              type: CTLogType.debug.rawValue,
                              message: "\(self): have current session: \(sessionId)")
        let now = Int(Date().timeIntervalSince1970)
        guard isSessionTimedOut(now) else {
            updateSessionTime(now)
            return
        }
        CTLogger.logWithLevel(Int32(config.logLevel.rawValue),
                              type: CTLogType.debug.rawValue,
                              message: "\(self): Session timeout reached")
        resetSession()
        createSession()
    }

    public func updateSessionTime(_ ts: Int) {
        guard inCurrentSession() else { return }
        CTLogger.logWithLevel(Int32(config.logLevel.rawValue),
                              type: CTLogType.debug.rawValue,
                              message: "\(self): updating session time: \(ts)")
        CTPreferences.put(ts,
                             forKey: CTPreferences.storageKey(withSuffix: kLastSessionTime, config: config))
    }

    public func resetSession() {
        guard !CTUIUtils.runningInsideAppExtension() else { return }
        appLaunchProcessed = false
        encryptionInTransitFailed = false

        let lastSessionID: Int
        let lastSessionEnd: Int

        if config.isDefaultInstance {
            lastSessionID = CTPreferences.getIntForKey(
                CTPreferences.storageKey(withSuffix: kSessionId, config: config),
                withResetValue: CTPreferences.getIntForKey(kSessionId, withResetValue: 0))
            lastSessionEnd = CTPreferences.getIntForKey(
                CTPreferences.storageKey(withSuffix: kLastSessionTime, config: config),
                withResetValue: CTPreferences.getIntForKey(kLastSessionPing, withResetValue: 0))
        } else {
            lastSessionID = CTPreferences.getIntForKey(
                CTPreferences.storageKey(withSuffix: kSessionId, config: config),
                withResetValue: 0)
            lastSessionEnd = CTPreferences.getIntForKey(
                CTPreferences.storageKey(withSuffix: kLastSessionTime, config: config),
                withResetValue: 0)
        }

        lastSessionLengthSeconds = (lastSessionID > 0 && lastSessionEnd > 0)
            ? Int32(lastSessionEnd - lastSessionID)
            : 0

        sessionId = 0
        updateSessionTime(0)
        CTPreferences.removeObject(forKey: kSessionId)
        CTPreferences.removeObject(forKey: CTPreferences.storageKey(withSuffix: kSessionId, config: config))
        screenCount = 1
        clearSource()
        clearMedium()
        clearCampaign()
        clearWzrkParams()

#if !CLEVERTAP_NO_INAPP_SUPPORT
        if !CTUIUtils.runningInsideAppExtension() {
            impressionManager?.resetSession()
        }
#endif
    }

    // MARK: - Private helpers

    private func inCurrentSession() -> Bool {
        return sessionId > 0
    }

    private func isSessionTimedOut(_ currentTS: Int) -> Bool {
        let last = lastSessionTime()
        return last > 0 && (currentTS - last > minSessionSeconds)
    }

    private func lastSessionTime() -> Int {
        return CTPreferences.getIntForKey(
            CTPreferences.storageKey(withSuffix: kLastSessionTime, config: config),
            withResetValue: 0)
    }

    private func createFirstRequestInSession() {
        firstRequestInSession = true
        validationConfig.discardedEventNames = nil
    }

    private func createSession() {
        sessionId = Int(Date().timeIntervalSince1970)
        updateSessionTime(sessionId)
        createFirstRequestInSession()

        if config.isDefaultInstance {
            firstSession = CTPreferences.getIntForKey(
                CTPreferences.storageKey(withSuffix: "firstTime", config: config),
                withResetValue: CTPreferences.getIntForKey("firstTime", withResetValue: 0)) == 0
        } else {
            firstSession = CTPreferences.getIntForKey(
                CTPreferences.storageKey(withSuffix: "firstTime", config: config),
                withResetValue: 0) == 0
        }
        CTPreferences.put(1, forKey: CTPreferences.storageKey(withSuffix: "firstTime", config: config))

        CTLogger.logWithLevel(Int32(config.logLevel.rawValue),
                              type: CTLogType.debug.rawValue,
                              message: "\(self): session created with ID: \(sessionId)")
        CTLogger.logWithLevel(Int32(config.logLevel.rawValue),
                              type: CTLogType.debug.rawValue,
                              message: "\(self): previous session length: \(lastSessionLengthSeconds) seconds")

#if !CLEVERTAP_NO_INAPP_SUPPORT
        if !CTUIUtils.runningInsideAppExtension() {
            inAppStore?.clearInApps()
        }
#endif
    }

    private func clearSource()     { lock.lock(); _source = nil;     lock.unlock() }
    private func clearMedium()     { lock.lock(); _medium = nil;     lock.unlock() }
    private func clearCampaign()   { lock.lock(); _campaign = nil;   lock.unlock() }
    private func clearWzrkParams() { lock.lock(); _wzrkParams = nil; lock.unlock() }
}
