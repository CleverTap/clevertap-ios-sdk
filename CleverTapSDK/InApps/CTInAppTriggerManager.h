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

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager;

- (NSUInteger)getTriggers:(NSString *)campaignId;
- (void)incrementTrigger:(NSString *)campaignId;
- (void)removeTriggers:(NSString *)campaignId;

@end

NS_ASSUME_NONNULL_END
