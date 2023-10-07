//
//  CTInAppEvaluationManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTBatchSentDelegate.h"
#import "CTAttachToHeaderDelegate.h"
#import "CleverTap.h"
#import "CTDeviceInfo.h"
#import "CTImpressionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppEvaluationManager : NSObject <CTBatchSentDelegate, CTAttachToHeaderDelegate>

//- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCleverTap:(CleverTap *)instance
                       deviceInfo:(CTDeviceInfo *)deviceInfo
                impressionManager:(CTImpressionManager *)impressionManager;

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties;
- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items;
- (void)evaluateOnAppLaunchedClientSide;
- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs;

- (BOOL)evaluateInAppFrequencyLimits:(CTInAppNotification *)inApp;

@end

NS_ASSUME_NONNULL_END
