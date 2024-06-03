//
//  CTInAppEvaluationManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CTBatchSentDelegate.h"
#import "CTAttachToBatchHeaderDelegate.h"

@class CTMultiDelegateManager;
@class CTImpressionManager;
@class CTInAppDisplayManager;
@class CTInAppStore;
@class CTInAppTriggerManager;

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppEvaluationManager : NSObject <CTBatchSentDelegate, CTAttachToBatchHeaderDelegate>

@property (nonatomic, assign) CLLocationCoordinate2D location;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                   delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
              inAppDisplayManager:(CTInAppDisplayManager *)inAppDisplayManager
                       inAppStore:(CTInAppStore *)inAppStore
              inAppTriggerManager:(CTInAppTriggerManager *)inAppTriggerManager;

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties;
- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items;
- (void)evaluateOnUserAttributeChange:(NSDictionary<NSString *, NSDictionary *> *)properties;
- (void)evaluateOnAppLaunchedClientSide;
- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs;

@end

NS_ASSUME_NONNULL_END
