//
//  UIView+CTWebCacheOperation.m
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

#import "UIView+CTWebCacheOperation.h"
#import "CTWebImageOperation.h"
#import <objc/runtime.h>

// Associated object key for the operation dictionary — mirrors SDWebImage's usage.
static char kCTOperationDictionaryKey;

// The dictionary type: NSMapTable with strong keys, WEAK values.
// SDWebImage uses the same approach (UIView+WebCacheOperation.m:21–25):
//   NSMapTable *operationDictionary = [NSMapTable strongToWeakObjectsMapTable];
typedef NSMapTable<NSString *, id> CTSDOperationsDictionary;

@implementation UIView (CTWebCacheOperation)

// ---------------------------------------------------------------------------
// ct_operationDictionary — lazy accessor, mirrors sd_operationDictionary
// (UIView+WebCacheOperation.m:19–36)
// ---------------------------------------------------------------------------

- (CTSDOperationsDictionary *)ct_operationDictionary {
    @synchronized (self) {
        CTSDOperationsDictionary *operations =
            objc_getAssociatedObject(self, &kCTOperationDictionaryKey);
        if (operations) {
            return operations;
        }
        // NSMapTable with strong keys and WEAK values — same as SDWebImage
        operations = [NSMapTable strongToWeakObjectsMapTable];
        objc_setAssociatedObject(self, &kCTOperationDictionaryKey, operations,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operations;
    }
}

// ---------------------------------------------------------------------------
// ct_setImageLoadOperation:forKey: — mirrors sd_setImageLoadOperation:forKey:
// (UIView+WebCacheOperation.m:38–53)
// ---------------------------------------------------------------------------

- (void)ct_setImageLoadOperation:(nullable id)operation forKey:(nullable NSString *)key {
    if (!key) return;

    // Cancel the existing operation for this key first
    [self ct_cancelImageLoadOperationWithKey:key];

    if (operation) {
        CTSDOperationsDictionary *operationDictionary = [self ct_operationDictionary];
        @synchronized (self) {
            [operationDictionary setObject:operation forKey:key];
        }
    }
}

// ---------------------------------------------------------------------------
// ct_cancelImageLoadOperationWithKey: — mirrors sd_cancelImageLoadOperationWithKey:
// (UIView+WebCacheOperation.m:54–73)
// ---------------------------------------------------------------------------

- (void)ct_cancelImageLoadOperationWithKey:(nullable NSString *)key {
    if (!key) return;

    CTSDOperationsDictionary *operationDictionary = [self ct_operationDictionary];
    id operation;
    @synchronized (self) {
        operation = [operationDictionary objectForKey:key];
    }

    if (operation) {
        // Call cancel if the object responds to it — mirrors SDWebImage's check
        // (SDWebImageManager+SDWebImageOperation conformance check)
        if ([operation respondsToSelector:@selector(cancel)]) {
            [operation cancel];
        }
        @synchronized (self) {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

// ---------------------------------------------------------------------------
// ct_removeImageLoadOperationWithKey: — mirrors sd_removeImageLoadOperationWithKey:
// (UIView+WebCacheOperation.m:75–85) — removes without cancelling
// ---------------------------------------------------------------------------

- (void)ct_removeImageLoadOperationWithKey:(nullable NSString *)key {
    if (!key) return;

    CTSDOperationsDictionary *operationDictionary = [self ct_operationDictionary];
    @synchronized (self) {
        [operationDictionary removeObjectForKey:key];
    }
}

@end
