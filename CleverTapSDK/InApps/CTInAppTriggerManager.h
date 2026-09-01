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
 The word that identifies this store inside its preference keys, for example @c triggers.
 Two managers with the same value share storage, so each channel needs its own.

 Called @c storageNamespace rather than @c namespace because @c namespace is a reserved word in
 Objective-C++ and would break any consumer compiling this header from a @c .mm file.
 */
@property (nonatomic, copy, readonly) NSString *storageNamespace;

- (instancetype)init NS_UNAVAILABLE;

/// Uses the in-app namespace. Kept so existing call sites and stored keys are unaffected.
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
