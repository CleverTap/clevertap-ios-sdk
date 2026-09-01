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

@interface CTInAppTriggerManager : NSObject <CTSwitchUserDelegate>

/**
 The word used to identify this store inside its preference keys, for example @c triggers.
 Two managers with the same word share storage, so each channel needs its own.

 It is called @c storageNamespace and not @c namespace because @c namespace is a reserved word in
 Objective-C++, and would break anyone compiling this header from a @c .mm file.
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
