//
//  CTInAppStore.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSwitchUserDelegate.h"

@class CleverTapInstanceConfig;
@class CTMultiDelegateManager;

@interface CTInAppStore : NSObject <CTSwitchUserDelegate>

@property (nonatomic, strong, nullable) NSString *mode;

- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig * _Nonnull)config
                        delegateManager:(CTMultiDelegateManager * _Nonnull)delegateManager
                               deviceId:(NSString * _Nonnull)deviceId;

- (NSArray * _Nonnull)clientSideInApps;
- (void)storeClientSideInApps:(NSArray * _Nullable)clientSideInApps;

- (NSArray * _Nonnull)serverSideInApps;
- (void)storeServerSideInApps:(NSArray * _Nullable)serverSideInApps;

- (void)clearInApps;
- (NSArray * _Nonnull)inAppsQueue;
- (void)storeInApps:(NSArray * _Nullable)inApps;
- (void)enqueueInApps:(NSArray * _Nullable)inAppNotifs;
- (void)insertInFrontInApp:(NSDictionary * _Nullable)inAppNotif;
- (NSDictionary * _Nullable)peekInApp;
- (NSDictionary * _Nullable)dequeueInApp;

@end
