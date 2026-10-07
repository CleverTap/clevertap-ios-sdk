//
//  CTNdStore.swift
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//
//  Swift replacement for CTNdStore.h and CTNdStore.m.
//

import Foundation

// Internal ObjC types (CTPreferences, CTConstants, CTMultiDelegateManager, etc.) are exposed via the
// SDK's public header umbrella (see CleverTap-iOS-SDK.podspec). The pod ships no custom module map,
// because CocoaPods rejects those for Swift static libraries. So the umbrella is how this file sees
// those types. It works the same way under CocoaPods static (Flutter and React Native), CocoaPods
// dynamic, SPM and manual integration. Swift inside the module sees umbrella ObjC types
// automatically, so no explicit import is needed.
//
// The canImport guard is only for the direct Xcode framework target. That target still uses
// CleverTapSDK/ios.modulemap with its `explicit module Private` submodule.
#if canImport(CleverTapSDK.Private)
@_implementationOnly import CleverTapSDK.Private
#endif

/// Saves the frequency rules the server sends for Native Display campaigns. On the wire that list is
/// called `adUnit_notifs_ss`. This class saves it and nothing else.
///
/// The entries hold only the rules. They never hold the text or images the user sees. Nothing here
/// is encrypted, unlike `CTInAppStore`. There is also no queue, no expiry time and no client side
/// version. Native Display is server side only.
///
/// The server always sends the full current list, not just what changed. An empty array means there
/// are no rules any more. It does not mean nothing changed.
///
/// The class is internal on purpose. `@objc` is what puts it in the generated header, so
/// Objective-C inside the SDK still sees it. Clients that write `import CleverTapSDK` do not.
@objcMembers
final class CTNdStore: NSObject {

    private let config: CleverTapInstanceConfig
    private let accountId: String
    private var deviceId: String

    /// Nil means the rules were never read from storage, or the user changed. The next read loads
    /// them from storage. An empty array is a real value. It means the server sent no rules.
    private var cachedServerSideNativeDisplays: [Any]?

    /// Guards every read and write below. The Objective-C version used `@synchronized (self)`, which
    /// is recursive, so the recursive lock is the exact match.
    private let lock = NSRecursiveLock()

    /// Receives the user switch callback on this store's behalf. See CTNdDelegateObserver for why the
    /// store does not receive it directly. CTMultiDelegateManager keeps a weak reference to its
    /// delegates, so the store has to be the one that owns this object.
    private let delegateObserver = CTNdDelegateObserver()

    @objc(initWithConfig:delegateManager:deviceId:)
    init(config: CleverTapInstanceConfig,
         delegateManager: CTMultiDelegateManager,
         deviceId: String) {
        self.config = config
        self.accountId = config.accountId
        self.deviceId = deviceId
        super.init()

        // The store owns the observer. So the capture below is unowned. That stops the two from
        // keeping each other alive.
        delegateObserver.deviceIdDidChangeHandler = { [unowned self] newDeviceId in
            self.deviceIdDidChange(newDeviceId)
        }
        delegateObserver.register(with: delegateManager)
    }

    // MARK: - Server-Side Native Displays

    /// The saved rules, or an empty array if there are none. Never nil.
    func serverSideNativeDisplays() -> [Any] {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedServerSideNativeDisplays {
            return cached
        }

        let saved = CTPreferences.getObjectForKey(storageKey(withSuffix: Self.serverSideKeySuffix))
        let loaded = saved as? [Any] ?? []
        cachedServerSideNativeDisplays = loaded
        return loaded
    }

    /// Replaces the saved rules. A nil argument does nothing. Pass an empty array to clear them.
    func storeServerSideNativeDisplays(_ serverSideNativeDisplays: [Any]?) {
        guard let serverSideNativeDisplays else { return }

        lock.lock()
        defer { lock.unlock() }

        cachedServerSideNativeDisplays = serverSideNativeDisplays
        CTPreferences.put(serverSideNativeDisplays,
                          forKey: storageKey(withSuffix: Self.serverSideKeySuffix))
    }

    func removeServerSideNativeDisplays() {
        lock.lock()
        defer { lock.unlock() }

        cachedServerSideNativeDisplays = []
        CTPreferences.removeObject(forKey: storageKey(withSuffix: Self.serverSideKeySuffix))
    }

    // MARK: - Storage Key

    private static let serverSideKeySuffix = CLTAP_PREFS_ND_KEY_SS

    // Same key order as CTInAppStore. That order is accountId:deviceId:suffix. CTInAppFCManager uses
    // a different order. Each class copies the one it is based on.
    private func storageKey(withSuffix suffix: String) -> String {
        return "\(accountId):\(deviceId):\(suffix)"
    }

    // MARK: - User switch

    private func deviceIdDidChange(_ newDeviceId: String) {
        lock.lock()
        defer { lock.unlock() }

        deviceId = newDeviceId
        // Set to nil so the next read loads the new user's rules from storage.
        cachedServerSideNativeDisplays = nil
    }
}
