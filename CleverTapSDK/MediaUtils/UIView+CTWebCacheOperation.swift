//
//  UIView+CTWebCacheOperation.swift
//  CleverTapSDK
//
//  Exact port of SDWebImage's UIView+WebCacheOperation.
//  Key source references:
//    - ct_operationDictionary (lazy init) → UIView+WebCacheOperation.m:19–36
//    - ct_setImageLoadOperation:forKey:   → UIView+WebCacheOperation.m:38–53
//    - ct_cancelImageLoadOperationWithKey:→ UIView+WebCacheOperation.m:54–73
//    - ct_removeImageLoadOperationWithKey:→ UIView+WebCacheOperation.m:75–85
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

import UIKit
import ObjectiveC

// The dictionary type: NSMapTable with strong keys, WEAK values.
// SDWebImage uses the same approach (UIView+WebCacheOperation.m:21–25):
//   NSMapTable *operationDictionary = [NSMapTable strongToWeakObjectsMapTable];
private typealias CTSDOperationsDictionary = NSMapTable<NSString, AnyObject>

extension UIView {

    // Associated object key for the operation dictionary — mirrors SDWebImage's usage.
    private static var kCTOperationDictionaryKey: UInt8 = 0

    // ---------------------------------------------------------------------------
    // ct_operationDictionary — lazy accessor, mirrors sd_operationDictionary
    // (UIView+WebCacheOperation.m:19–36)
    // ---------------------------------------------------------------------------

    private func ct_operationDictionary() -> CTSDOperationsDictionary {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        if let operations = objc_getAssociatedObject(self, &UIView.kCTOperationDictionaryKey) as? CTSDOperationsDictionary {
            return operations
        }
        // NSMapTable with strong keys and WEAK values — same as SDWebImage
        let operations = CTSDOperationsDictionary.strongToWeakObjects()
        objc_setAssociatedObject(self, &UIView.kCTOperationDictionaryKey, operations,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return operations
    }

    // ---------------------------------------------------------------------------
    // ct_setImageLoadOperation:forKey: — mirrors sd_setImageLoadOperation:forKey:
    // (UIView+WebCacheOperation.m:38–53)
    // ---------------------------------------------------------------------------

    @objc(ct_setImageLoadOperation:forKey:)
    func ct_setImageLoadOperation(_ operation: Any?, forKey key: String?) {
        guard let key = key else { return }

        // Cancel the existing operation for this key first
        ct_cancelImageLoadOperation(withKey: key)

        if let operation = operation {
            let operationDictionary = ct_operationDictionary()
            objc_sync_enter(self); defer { objc_sync_exit(self) }
            operationDictionary.setObject(operation as AnyObject, forKey: key as NSString)
        }
    }

    // ---------------------------------------------------------------------------
    // ct_cancelImageLoadOperationWithKey: — mirrors sd_cancelImageLoadOperationWithKey:
    // (UIView+WebCacheOperation.m:54–73)
    // ---------------------------------------------------------------------------

    @objc(ct_cancelImageLoadOperationWithKey:)
    func ct_cancelImageLoadOperation(withKey key: String?) {
        guard let key = key else { return }

        let operationDictionary = ct_operationDictionary()
        var operation: AnyObject?
        do {
            objc_sync_enter(self); defer { objc_sync_exit(self) }
            operation = operationDictionary.object(forKey: key as NSString)
        }

        if let operation = operation {
            // Call cancel if the object responds to it — mirrors SDWebImage's check
            // (SDWebImageManager+SDWebImageOperation conformance check)
            if operation.responds(to: NSSelectorFromString("cancel")) {
                _ = operation.perform(NSSelectorFromString("cancel"))
            }
            objc_sync_enter(self); defer { objc_sync_exit(self) }
            operationDictionary.removeObject(forKey: key as NSString)
        }
    }

    // ---------------------------------------------------------------------------
    // ct_removeImageLoadOperationWithKey: — mirrors sd_removeImageLoadOperationWithKey:
    // (UIView+WebCacheOperation.m:75–85) — removes without cancelling
    // ---------------------------------------------------------------------------

    @objc(ct_removeImageLoadOperationWithKey:)
    func ct_removeImageLoadOperation(withKey key: String?) {
        guard let key = key else { return }

        let operationDictionary = ct_operationDictionary()
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        operationDictionary.removeObject(forKey: key as NSString)
    }
}
