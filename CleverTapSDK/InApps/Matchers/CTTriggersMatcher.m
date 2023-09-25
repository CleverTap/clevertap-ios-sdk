//
//  CTTriggersMatcher.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggersMatcher.h"
#import "CTTriggerAdapter.h"
#import "CTTriggerValue.h"
#import "CTConstants.h"
#import "CTTriggerEvaluator.h"

@implementation CTTriggersMatcher

- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers event:(CTEventAdapter *)event {
    // Events in the array are OR-ed
    for (NSDictionary *triggerObject in whenTriggers) {
        CTTriggerAdapter *trigger = [[CTTriggerAdapter alloc] initWithJSON:triggerObject];
        if ([event.eventName isEqualToString:@"Charged"]) {
            if ([self matchCharged:trigger event:event]) {
                return YES;
            }
        } else if ([self match:trigger event:event]) {
            return YES;
        }
    }
    return NO;
}

// TODO: remove this method?
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

// TODO: remove this method?
- (BOOL)matchChargedEventWhenTriggers:(NSArray *)whenTriggers details:(NSDictionary *)details items:(NSArray<NSDictionary *> *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:@"Charged" eventProperties:details andItems:items];

    // Events in the array are OR-ed
    for (NSDictionary *triggerObject in whenTriggers) {
        CTTriggerAdapter *trigger = [[CTTriggerAdapter alloc] initWithJSON:triggerObject];
        if ([self matchCharged:trigger event:event]) {
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
        BOOL matched;
        @try {
            matched = [CTTriggerEvaluator evaluate:condition.op
                                 expected:condition.value actual:eventValue];
        }
        @catch (NSException *exception) {
            CleverTapLogStaticDebug(@"Error matching triggers for event named %@. Reason: %@", event.eventName, exception.reason);
        }
        if (!matched) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)matchCharged:(CTTriggerAdapter *)trigger event:(CTEventAdapter *)event {
    BOOL eventPropertiesMatched = [self match:trigger event:event];
    if (!eventPropertiesMatched) {
        return NO;
    }
    
    // Property conditions for items are AND-ed (chargedEvent only)
    NSUInteger itemsCount = [trigger itemsCount];
    if (itemsCount > 0) {
        for (NSUInteger i = 0; i < itemsCount; i++) {
            CTTriggerCondition *itemCondition = [trigger itemAtIndex:i];
            CTTriggerValue *eventValues = [event itemValueNamed:itemCondition.propertyName];
            BOOL matched = [CTTriggerEvaluator evaluate:itemCondition.op
                                 expected:itemCondition.value actual:eventValues];
            if (!matched) {
                return NO;
            }
        }
    }
    
    return YES;
}

@end
