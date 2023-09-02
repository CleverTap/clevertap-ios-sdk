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
    CTTriggerOperatorContains,
    CTTriggerOperatorNotContains,
    CTTriggerOperatorLessThan,
    CTTriggerOperatorGreaterThan,
    CTTriggerOperatorBetween,
    CTTriggerOperatorEquals,
    CTTriggerOperatorNotEquals,
    CTTriggerOperatorSet, // Exists
    CTTriggerOperatorNotSet, // Not exists
};

@interface CTTriggerCondition : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithProperyName:(NSString *)propertyName
                        andOperator:(NSString *)op
                           andValue:(CTTriggerValue *)value NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) NSString *propertyName;
@property (nonatomic, readonly) CTTriggerValue *value;
@property (nonatomic, readonly) CTTriggerOperator op;

@end

NS_ASSUME_NONNULL_END
