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
#import "CTInAppStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppEvaluationManager : NSObject <CTBatchSentDelegate, CTAttachToBatchHeaderDelegate>

@property (nonatomic, assign) CLLocationCoordinate2D location;

- (instancetype)initWithAccountId:(NSString *)accountId
                       deviceInfo:(CTDeviceInfo *)deviceInfo
                   delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
              inAppDisplayManager:(CTInAppDisplayManager *)inAppDisplayManager
                       inAppStore:(CTInAppStore *)inAppStore;

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties;
- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items;
- (void)evaluateOnAppLaunchedClientSide;
- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs;

@end

NS_ASSUME_NONNULL_END
