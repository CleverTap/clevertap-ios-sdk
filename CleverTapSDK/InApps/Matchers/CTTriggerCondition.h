//
//  TriggerCondition.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTriggerValue.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CTTriggerOperator){
    CTTriggerOperatorGreaterThan = 0,
    CTTriggerOperatorEquals = 1,
    CTTriggerOperatorLessThan = 2,
    CTTriggerOperatorContains = 3,
    CTTriggerOperatorBetween = 4,
    CTTriggerOperatorNotEquals = 15,
    CTTriggerOperatorSet = 26, // Exists
    CTTriggerOperatorNotSet = 27, // Not exists
    CTTriggerOperatorNotContains = 28,
};

@interface CTTriggerCondition : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithProperyName:(NSString *)propertyName
                        andOperator:(NSUInteger)op
                           andValue:(CTTriggerValue *)value NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) NSString *propertyName;
@property (nonatomic, readonly) CTTriggerValue *value;
@property (nonatomic, readonly) CTTriggerOperator op;

@end

NS_ASSUME_NONNULL_END
