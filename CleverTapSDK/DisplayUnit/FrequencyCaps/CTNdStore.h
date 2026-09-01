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
 Saves the @c adUnit_notifs_ss list that the server sends, and nothing else.

 These entries hold only the frequency rules for each campaign, never the text or images the user
 sees, so unlike @c CTInAppStore nothing here is encrypted. There is also no queue, no expiry time,
 and no client side version, because Native Display is server side only.

 The server always sends the full current list rather than the changes since last time, so an empty
 array means "there are no rules any more", not "nothing changed".
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
