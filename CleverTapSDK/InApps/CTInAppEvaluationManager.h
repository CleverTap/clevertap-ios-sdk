//
//  CTInAppEvaluationManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppEvaluationManager : NSObject

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties;
- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items;
- (void)evaluateOnAppLaunchedClientSide;
- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs;

@end

NS_ASSUME_NONNULL_END
