//
//  CTInAppStore.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"
#import "CTAES.h"
#import "CTSwitchUserDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppStore : NSObject <CTSwitchUserDelegate>

@property (nonatomic, strong, nullable) NSString *mode;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceId:(NSString *)deviceId;

- (NSArray *)clientSideInApps;
- (NSArray *)serverSideInApps;
- (void)storeClientSideInApps:(NSArray *)clientSideInApps;
- (void)storeServerSideInApps:(NSArray *)serverSideInApps;

// TODO: add nullability
- (void)clearInApps;
- (void)storeInApps:(NSArray *)inApps;
- (NSArray *)inAppsQueue;
- (void)enqueueInApps:(NSArray *)inAppNotifs;
- (NSDictionary *)peekInApp;
- (NSDictionary *)dequeInApp;

@end

NS_ASSUME_NONNULL_END
