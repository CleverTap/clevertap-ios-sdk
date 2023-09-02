//
//  CTTriggersMatcher.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTTriggersMatcher : NSObject

- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName eventProperties:(NSDictionary *)eventProperties;

- (BOOL)matchChargedEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName details:(NSDictionary *)details items:(NSArray<NSDictionary *> *)items;

@end

NS_ASSUME_NONNULL_END
