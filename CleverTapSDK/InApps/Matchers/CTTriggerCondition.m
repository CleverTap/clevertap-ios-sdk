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
                        andOperator:(NSUInteger)op
                           andValue:(CTTriggerValue *)value {
    if (self = [super init]) {
        self.propertyName = propertyName;
        self.value = value;
        self.op = (CTTriggerOperator)op;
    }
    
    return self;
}

@end
