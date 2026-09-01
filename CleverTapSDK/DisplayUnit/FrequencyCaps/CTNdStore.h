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
 Saves the frequency rules the server sends for Native Display campaigns. On the wire that list is
 called @c adUnit_notifs_ss. This class saves it and nothing else.

 The entries hold only the rules, never the text or images the user sees, so unlike @c CTInAppStore
 nothing here is encrypted. There is also no queue, no expiry time and no client side version,
 because Native Display is server side only.

 The server always sends the full current list, not just what changed. So an empty array means there
 are no rules any more, not that nothing changed.
 */
@interface CTNdStore : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId NS_DESIGNATED_INITIALIZER;

/// The saved rules, or an empty array if there are none. Never nil.
- (NSArray *)serverSideNativeDisplays;

/// Replaces the saved rules. A nil argument does nothing; pass an empty array to clear them.
- (void)storeServerSideNativeDisplays:(nullable NSArray *)serverSideNativeDisplays;

- (void)removeServerSideNativeDisplays;

@end

NS_ASSUME_NONNULL_END
