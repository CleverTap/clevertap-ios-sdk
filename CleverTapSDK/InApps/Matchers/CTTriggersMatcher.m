//
//  CTTriggersMatcher.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggersMatcher.h"
#import "CTEventAdapter.h"
#import "CTTriggerAdapter.h"
#import "CTTriggerValue.h"

@implementation CTTriggersMatcher

- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName eventProperties:(NSDictionary *)eventProperties {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName eventProperties:eventProperties];

    // Events in the array are OR-ed
    for (NSDictionary *triggerObject in whenTriggers) {
        CTTriggerAdapter *trigger = [[CTTriggerAdapter alloc] initWithJSON:triggerObject];
        if ([self match:trigger event:event]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)matchChargedEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName details:(NSDictionary *)details items:(NSArray<NSDictionary *> *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName eventProperties:details andItems:items];

    // Events in the array are OR-ed
    for (NSDictionary *triggerObject in whenTriggers) {
        CTTriggerAdapter *trigger = [[CTTriggerAdapter alloc] initWithJSON:triggerObject];
        if ([self match:trigger event:event]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)match:(CTTriggerAdapter *)trigger event:(CTEventAdapter *)event {
    if (![[event eventName] isEqualToString:[trigger eventName]]) {
        return NO;
    }

    // Property conditions are AND-ed
    NSUInteger propCount = [trigger propertyCount];
    for (NSUInteger i = 0; i < propCount; i++) {
        CTTriggerCondition *condition = [trigger propertyAtIndex:i];
        
        CTTriggerValue *eventValue = [event propertyValueNamed:condition.propertyName];
        BOOL matched = [self evaluate:condition.op
                             expected:condition.value actual:eventValue];
        if (!matched) {
            return NO;
        }
    }

    // Property conditions for items are AND-ed (chargedEvent only)
    NSUInteger itemsCount = [trigger itemsCount];
    if (itemsCount > 0) {
        for (NSUInteger i = 0; i < itemsCount; i++) {
            CTTriggerCondition *itemCondition = [trigger itemAtIndex:i];
            CTTriggerValue *eventValues = [event itemValueNamed:itemCondition.propertyName];
            BOOL matched = [self evaluate:itemCondition.op
                                 expected:itemCondition.value actual:eventValues];
            if (!matched) {
                return NO;
            }
        }
    }

    return YES;
}

- (BOOL)evaluate:(CTTriggerOperator)op expected:(CTTriggerValue *)expected actual:(CTTriggerValue * __nullable)actual {
    if (actual == nil) {
        if (op == CTTriggerOperatorNotSet) {
            return YES;
        } else {
            return NO;
        }
    }

    switch (op) {
        case CTTriggerOperatorLessThan:
            return [[expected numberValue] compare:[actual numberValue]] == NSOrderedDescending;
        default:
            return NO; // TODO: Implement all cases as per the backed evaluation and remove this line
    }
}

@end
