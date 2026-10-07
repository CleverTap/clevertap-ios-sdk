//
//  CTInAppTriggerManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSwitchUserDelegate.h"
NS_ASSUME_NONNULL_BEGIN
@class CTMultiDelegateManager;

/*!
 Read-only access to a campaign's trigger count.

 Exists so limit matching can be pointed at something other than the live, persisted counter. A
 speculative evaluation must not write a trigger count, but it still has to evaluate limits
 against the count the real path *would* see — the real path increments before checking limits,
 so `onEvery` / `onExactly` compare against N+1.
 */
@protocol CTTriggerCounting <NSObject>

- (NSUInteger)getTriggers:(NSString *)campaignId;

@end

@interface CTInAppTriggerManager : NSObject <CTSwitchUserDelegate, CTTriggerCounting>

/**
 The word used to identify this store inside its preference keys, for example @c triggers.
 Two managers with the same word share storage, so each channel needs its own.
 Named as it is for the reason given on @c CTImpressionManager @c storageNamespace.
 */
@property (nonatomic, copy, readonly) NSString *storageNamespace;

- (instancetype)init NS_UNAVAILABLE;

/// Uses the in-app storage name. Kept so existing call sites and saved keys do not change.
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager;

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                 storageNamespace:(NSString *)storageNamespace NS_DESIGNATED_INITIALIZER;

- (NSUInteger)getTriggers:(NSString *)campaignId;
- (void)incrementTrigger:(NSString *)campaignId;
- (void)removeTriggers:(NSString *)campaignId;

@end

NS_ASSUME_NONNULL_END
