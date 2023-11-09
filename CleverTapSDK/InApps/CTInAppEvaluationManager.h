//
//  CTInAppEvaluationManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTBatchSentDelegate.h"
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTDeviceInfo.h"
#import "CTMultiDelegateManager.h"
#import "CTImpressionManager.h"
#import "CTInAppDisplayManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppEvaluationManager : NSObject <CTBatchSentDelegate, CTAttachToBatchHeaderDelegate>

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                    deviceInfo:(CTDeviceInfo *)deviceInfo
               delegateManager:(CTMultiDelegateManager *)delegateManager
             impressionManager:(CTImpressionManager *)impressionManager
           inAppDisplayManager:(CTInAppDisplayManager *) inAppDisplayManager;

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties;
- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items;
- (void)evaluateOnAppLaunchedClientSide;
- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs;

@end

NS_ASSUME_NONNULL_END
