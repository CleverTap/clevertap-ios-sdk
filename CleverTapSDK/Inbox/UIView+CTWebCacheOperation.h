//
//  UIView+CTWebCacheOperation.h
//  CleverTapSDK
//
//  Exact port of SDWebImage's UIView+WebCacheOperation (UIView+WebCacheOperation.h/.m).
//  Stores and tracks the current image-load operation on a UIView using an associated
//  NSMapTable so that in-flight operations can be cancelled (e.g. on cell reuse).
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * UIView category that manages image-load operations per key.
 * Mirrors UIView+WebCacheOperation from SDWebImage exactly.
 *
 * The operation dictionary is stored as an associated object using a
 * NSMapTable with strong keys and WEAK values — same as SDWebImage — so
 * that completed/released operations are automatically removed.
 */
@interface UIView (CTWebCacheOperation)

/**
 * Sets an image load operation for the given key, cancelling any existing operation
 * already registered under that key.
 * Mirrors -[UIView sd_setImageLoadOperation:forKey:] (UIView+WebCacheOperation.m:38–53)
 */
- (void)ct_setImageLoadOperation:(nullable id)operation forKey:(nullable NSString *)key;

/**
 * Cancels and removes the operation registered for the given key.
 * Mirrors -[UIView sd_cancelImageLoadOperationWithKey:] (UIView+WebCacheOperation.m:54–73)
 */
- (void)ct_cancelImageLoadOperationWithKey:(nullable NSString *)key;

/**
 * Removes the operation registered for the given key without cancelling it.
 * Mirrors -[UIView sd_removeImageLoadOperationWithKey:] (UIView+WebCacheOperation.m:75–85)
 */
- (void)ct_removeImageLoadOperationWithKey:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END
