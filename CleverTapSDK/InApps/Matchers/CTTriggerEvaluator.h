//
//  CTTriggerEvaluator.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 10/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTriggerValue.h"
#import "CTTriggerCondition.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTTriggerEvaluator : NSObject

+ (BOOL)evaluate:(CTTriggerOperator)op expected:(CTTriggerValue *)expected actual:(CTTriggerValue * __nullable)actual;

@end

NS_ASSUME_NONNULL_END
