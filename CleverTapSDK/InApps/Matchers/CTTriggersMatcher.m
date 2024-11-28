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
#import "CTUtils.h"

@implementation CTTriggersMatcher

- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers event:(CTEventAdapter *)event {
    // Events in the array are OR-ed
    for (NSDictionary *triggerObject in whenTriggers) {
        CTTriggerAdapter *trigger = [[CTTriggerAdapter alloc] initWithJSON:triggerObject];
        if ([event.eventName isEqualToString:CLTAP_CHARGED_EVENT]) {
            if ([self matchCharged:trigger event:event]) {
                return YES;
            }
        } else if ([self match:trigger event:event]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)match:(CTTriggerAdapter *)trigger event:(CTEventAdapter *)event {
    BOOL eventNameMatch = [CTUtils areEqualNormalizedName:[event eventName] andName:[trigger eventName]];
    BOOL profileAttrNameMatch = [event profileAttrName] != nil && [CTUtils areEqualNormalizedName:[event profileAttrName] andName:[trigger profileAttrName]];
    if (!eventNameMatch && !profileAttrNameMatch) {
        return NO;
    }
    
    if (![self matchProperties:event trigger:trigger]) {
        return NO;
    }
    
    if (![self matchGeoRadius:event trigger:trigger]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)matchProperties:(CTEventAdapter *)event trigger:(CTTriggerAdapter *)trigger {
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

- (BOOL)matchGeoRadius:(CTEventAdapter *)event trigger:(CTTriggerAdapter *)trigger {
    NSUInteger geoRadiusCount = [trigger geoRadiusCount];
    if (geoRadiusCount == 0)
        return YES;
    
    if (CLLocationCoordinate2DIsValid([event location])) {
        // GeoRadius conditions are OR-ed
        for (NSUInteger i = 0; i < geoRadiusCount; i++) {
            CTTriggerRadius *triggerRadius = [trigger geoRadiusAtIndex:i];
            CLLocationCoordinate2D expected = CLLocationCoordinate2DMake([triggerRadius.latitude doubleValue],
                                                                         [triggerRadius.longitude doubleValue]);
            @try {
                if ([CTTriggerEvaluator evaluateDistance:triggerRadius.radius expected:expected actual:[event location]]) {
                    return YES;
                }
            }
            @catch (NSException *exception) {
                CleverTapLogStaticDebug(@"Error matching triggers for event named %@. Reason: %@", event.eventName, exception.reason);
            }
        }
    }
    return NO;
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
