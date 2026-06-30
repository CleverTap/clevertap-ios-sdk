//
//  CTWebImageOperation.swift
//  CleverTapSDK
//
//  Ported from SDWebImage's SDWebImageCombinedOperation.
//  Key source reference: SDWebImageManager.m:797–814 (cancel method)
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

import Foundation

/// CTWebImageOperation — a cancellable operation token returned by UIImageView+CTWebCache
/// when an image load is started.
///
/// Mirrors SDWebImageCombinedOperation which holds both a cache-query operation and a
/// network download operation. In our case the "cache check" is synchronous (memory cache),
/// so we only need to hold the NSURLSessionDataTask for the download.
@objc(CTWebImageOperation)
@objcMembers
final class CTWebImageOperation: NSObject {

    private let lock = NSLock()
    private var _cancelled = false

    // ---------------------------------------------------------------------------
    // isCancelled — custom getter wraps the ivar read in @synchronized so that
    // reads from the NSURLSession completion queue (a background thread) always
    // observe the most recent value written by cancel (potentially called from
    // a different thread). Mirrors the thread-safety intent of SDWebImageCombinedOperation.
    // ---------------------------------------------------------------------------

    /// Whether this operation has been cancelled. KVO-observable. Mirrors SDWebImageCombinedOperation.cancelled.
    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _cancelled
    }

    /// The underlying download task. Set by UIImageView+CTWebCache after the task is created.
    var dataTask: URLSessionDataTask?

    // ---------------------------------------------------------------------------
    // cancel — mirrors SDWebImageCombinedOperation.cancel (SDWebImageManager.m:797–814)
    // ---------------------------------------------------------------------------

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        if _cancelled {
            return
        }
        _cancelled = true

        // Cancel the network download task — mirrors SDWebImageCombinedOperation cancelling
        // its loaderOperation (SDWebImageManager.m:806–810)
        if let dataTask = dataTask {
            dataTask.cancel()
            self.dataTask = nil
        }
    }
}
