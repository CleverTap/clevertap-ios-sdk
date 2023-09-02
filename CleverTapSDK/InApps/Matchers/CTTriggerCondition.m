//
//  TriggerCondition.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggerCondition.h"

@interface CTTriggerCondition()

@property (nonatomic, strong) NSString *propertyName;
@property (nonatomic, strong) CTTriggerValue *value;
@property (nonatomic) CTTriggerOperator op;

@end

@implementation CTTriggerCondition

- (instancetype)initWithProperyName:(NSString *)propertyName
                        andOperator:(NSString *)op
                           andValue:(CTTriggerValue *)value {
    if (self = [super init]) {
        self.propertyName = propertyName;
        self.value = value;
        self.op = [self operatorFromString:op];
    }
    
    return self;
}

- (CTTriggerOperator)operatorFromString: (NSString *)operator {
    if ([operator isEqualToString:@"contains"]) {
        return CTTriggerOperatorContains;
    } else if ([operator isEqualToString:@"not_contains"]) {
        return CTTriggerOperatorNotContains;
    } else if ([operator isEqualToString:@"less_than"]) {
        return CTTriggerOperatorLessThan;
    } else if ([operator isEqualToString:@"greater_than"]) {
        return CTTriggerOperatorGreaterThan;
    } else if ([operator isEqualToString:@"between"]) {
        return CTTriggerOperatorBetween;
    } else if ([operator isEqualToString:@"equals"]) {
        return CTTriggerOperatorEquals;
    } else if ([operator isEqualToString:@"not_equals"]) {
        return CTTriggerOperatorNotEquals;
    } else if ([operator isEqualToString:@"set"]) {
        return CTTriggerOperatorSet;
    } else if ([operator isEqualToString:@"not_set"]) {
        return CTTriggerOperatorNotSet;
    }
    
    return CTTriggerOperatorEquals;
}

@end
