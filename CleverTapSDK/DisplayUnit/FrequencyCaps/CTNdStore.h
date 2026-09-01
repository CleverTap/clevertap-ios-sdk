//
//  CTNdStore.h
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CleverTapInstanceConfig;
@class CTMultiDelegateManager;

/**
 Holds the @c adUnit_notifs_ss rule bundle and nothing else.

 The bundle is rules, not content, so unlike @c CTInAppStore nothing here is encrypted. There is
 also no queue, no TTL, and no client-side variant, because Native Display is server-side only.

 The server sends the complete current set every time, so an empty array means "clear it", not
 "no change".
 */
@interface CTNdStore : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId NS_DESIGNATED_INITIALIZER;

/// The saved rule bundle, or an empty array if there is none. Never nil.
- (NSArray *)serverSideNativeDisplays;

/// Replaces the saved bundle. A nil argument is ignored; pass an empty array to clear.
- (void)storeServerSideNativeDisplays:(nullable NSArray *)serverSideNativeDisplays;

- (void)removeServerSideNativeDisplays;

@end

NS_ASSUME_NONNULL_END
