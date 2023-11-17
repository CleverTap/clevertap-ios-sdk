//
//  CTTriggersMatcher+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 17.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTriggersMatcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTTriggersMatcher(Tests)
- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName eventProperties:(NSDictionary *)eventProperties;
- (BOOL)matchChargedEventWhenTriggers:(NSArray *)whenTriggers details:(NSDictionary *)details items:(NSArray<NSDictionary *> *)items;
@end

NS_ASSUME_NONNULL_END
