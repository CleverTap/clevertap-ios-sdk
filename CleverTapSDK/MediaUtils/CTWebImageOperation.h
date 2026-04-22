//
//  CTWebImageOperation.h
//  CleverTapSDK
//
//  Ported from SDWebImage's SDWebImageCombinedOperation.
//  Key source reference: SDWebImageManager.m:797–814 (cancel method)
//
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CTWebImageOperation — a cancellable operation token returned by UIImageView+CTWebCache
 * when an image load is started.
 *
 * Mirrors SDWebImageCombinedOperation which holds both a cache-query operation and a
 * network download operation. In our case the "cache check" is synchronous (memory cache),
 * so we only need to hold the NSURLSessionDataTask for the download.
 */
@interface CTWebImageOperation : NSObject

/// Whether this operation has been cancelled. KVO-observable. Mirrors SDWebImageCombinedOperation.cancelled.
@property (nonatomic, assign, getter=isCancelled, readonly) BOOL cancelled;

/// The underlying download task. Set by UIImageView+CTWebCache after the task is created.
@property (nonatomic, strong, nullable) NSURLSessionDataTask *dataTask;

/**
 * Cancels the operation: sets cancelled = YES, cancels the data task.
 * Mirrors SDWebImageCombinedOperation.cancel (SDWebImageManager.m:797–814).
 * Thread-safe via @synchronized.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
