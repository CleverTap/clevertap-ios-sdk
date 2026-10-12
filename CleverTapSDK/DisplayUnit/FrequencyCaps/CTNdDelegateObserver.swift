//
//  CTNdDelegateObserver.swift
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation

#if canImport(CleverTapSDK.Private)
@_implementationOnly import CleverTapSDK.Private
#endif

/// Receives the CTMultiDelegateManager callbacks on behalf of a Native Display class.
///
/// An owner keeps one instance, sets only the closures it needs, then calls `register(with:)`.
///
/// # Why this class exists
///
/// The Native Display classes are written in Swift. Objective-C has to see them, so they are marked
/// `@objc`. Swift then writes their interface into the generated CleverTapSDK-Swift.h. A protocol
/// conformance is written with that interface.
///
/// That is the problem. The generated header sits in the framework's Headers directory.
/// `CTSwitchUserDelegate.h`, `CTAttachToBatchHeaderDelegate.h`, `CTBatchSentDelegate.h` and
/// `CTQueueType.h` sit in PrivateHeaders. They belong to the `Private` submodule. Objective-C needs
/// the full declaration to read a conformance list or a parameter type. A forward declaration is not
/// enough. So the generated header names types it cannot see, and it fails to compile.
/// `CTConstants.h` imports the generated header. Almost every file in the SDK imports
/// `CTConstants.h`. One bad conformance therefore breaks the whole target.
///
/// # Why the conformance sits on a separate private class
///
/// Swift writes a class into the generated header when the class is visible to Objective-C. An
/// `internal` class that conforms to an Objective-C protocol counts as visible. A `private` class
/// does not. So the conformance lives on `CTNdDelegateObserverForwarder` below, which is private to
/// this file. This class holds no conformance at all. It does not even inherit from NSObject, so
/// Objective-C never sees it either.
///
/// That split is what lets one observer be shared. A conforming class cannot be shared across files,
/// because sharing needs `internal`, and `internal` puts it in the generated header.
///
/// # Ownership
///
/// The owner must hold this object with a strong reference. `CTMultiDelegateManager` keeps its
/// delegates in a weak hash table, so nothing there keeps the forwarder alive. Every closure must
/// capture the owner as `unowned`. That is what stops the owner and this object from keeping each
/// other alive.
final class CTNdDelegateObserver {

    // MARK: - Callbacks

    /// The user changed. The argument is the new device id.
    var deviceIdDidChangeHandler: ((String) -> Void)?

    /// The user is about to change.
    var deviceIdWillChangeHandler: (() -> Void)?

    /// The SDK is building a batch header. Return the keys to add to it. Return an empty dictionary
    /// to add nothing.
    var batchHeaderHandler: ((CTQueueType) -> [String: Any])?

    /// A batch was sent. The arguments are the batch, whether it succeeded, and the queue it used.
    var batchSentHandler: (([Any], Bool, CTQueueType) -> Void)?

    /// A batch that held the App Launched event was sent.
    var appLaunchedHandler: ((Bool) -> Void)?

    // MARK: - Registration

    /// Receives the Objective-C callbacks and passes them to this object.
    private lazy var forwarder = CTNdDelegateObserverForwarder(observer: self)

    /// Joins the delegate lists this observer has closures for.
    ///
    /// Set the closures before calling this. A list with no closure is skipped. That keeps the owner
    /// out of lists it does not use.
    ///
    /// `addSwitchUserDelegate:` and `addBatchSentDelegate:` both arrive in Swift as `add(_:)`. The
    /// forwarder conforms to both protocols, so a plain call cannot pick one. The casts below say
    /// which one to use. `addAttachToHeaderDelegate:` arrives as `addAttach(to:)` and needs no cast.
    func register(with delegateManager: CTMultiDelegateManager) {
        if deviceIdDidChangeHandler != nil || deviceIdWillChangeHandler != nil {
            delegateManager.add(forwarder as any CTSwitchUserDelegate)
        }
        if batchHeaderHandler != nil {
            delegateManager.addAttach(to: forwarder)
        }
        if batchSentHandler != nil || appLaunchedHandler != nil {
            delegateManager.add(forwarder as any CTBatchSentDelegate)
        }
    }
}

/// Carries the Objective-C protocol conformances for CTNdDelegateObserver.
///
/// This class is private to this file on purpose. See the comment on CTNdDelegateObserver for what
/// goes wrong when a class with these conformances is visible outside it.
///
/// CTNdDelegateObserver owns this object. The reference back to it is unowned, so the two do not
/// keep each other alive.
private final class CTNdDelegateObserverForwarder: NSObject,
                                                   CTSwitchUserDelegate,
                                                   CTAttachToBatchHeaderDelegate,
                                                   CTBatchSentDelegate {

    private unowned let observer: CTNdDelegateObserver

    init(observer: CTNdDelegateObserver) {
        self.observer = observer
        super.init()
    }

    // MARK: - CTSwitchUserDelegate

    func deviceIdDidChange(_ newDeviceId: String) {
        observer.deviceIdDidChangeHandler?(newDeviceId)
    }

    func deviceIdWillChange() {
        observer.deviceIdWillChangeHandler?()
    }

    // MARK: - CTAttachToBatchHeaderDelegate

    // This one is required by the protocol, unlike the other four. The manager merges the result
    // into the header. An empty dictionary adds nothing.
    func onBatchHeaderCreation(for queueType: CTQueueType) -> [String: Any] {
        return observer.batchHeaderHandler?(queueType) ?? [:]
    }

    // MARK: - CTBatchSentDelegate

    func onBatchSent(_ batchWithHeader: [Any], withSuccess success: Bool, with queueType: CTQueueType) {
        observer.batchSentHandler?(batchWithHeader, success, queueType)
    }

    func onAppLaunched(withSuccess success: Bool) {
        observer.appLaunchedHandler?(success)
    }
}
