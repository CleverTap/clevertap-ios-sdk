//
//  CTTriggerEvaluator.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 10/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggerEvaluator.h"
#import "CTUtils.h"

@implementation CTTriggerEvaluator

+ (BOOL)evaluate:(CTTriggerOperator)op expected:(CTTriggerValue *)expected actual:(CTTriggerValue * __nullable)actual {
    
    if (actual == nil) {
        if (op == CTTriggerOperatorNotSet) {
            return YES;
        } else {
            return NO;
        }
    }
    switch (op) {
        case CTTriggerOperatorSet:
            return YES;
        case CTTriggerOperatorLessThan:
            return [[expected numberValue] compare:[actual numberValue]] == NSOrderedDescending;
        case CTTriggerOperatorGreaterThan:
            return [[expected numberValue] compare:[actual numberValue]] == NSOrderedAscending;
        case CTTriggerOperatorEquals:
            return [CTTriggerEvaluator expected:expected equalsActual:actual];
        case CTTriggerOperatorNotEquals:
            return ![CTTriggerEvaluator expected:expected equalsActual:actual];
        case CTTriggerOperatorBetween:
            return [CTTriggerEvaluator actual:actual isInRangeOfExpected:expected];
        case CTTriggerOperatorContains:
            return [CTTriggerEvaluator actual:actual containsExpected:expected];
        case CTTriggerOperatorNotContains:
            return ![CTTriggerEvaluator actual:actual containsExpected:expected];
        default:
            return NO; // TODO: Implement all cases as per the backed evaluation and remove this line
    }
}

+ (BOOL)expected:(CTTriggerValue *)expected equalsActual:(CTTriggerValue * __nullable)actual {
    if ([expected stringValue] && [actual isArray]) {
        for (id actualValue in [actual arrayValue]) {
            if ([actualValue isKindOfClass:[NSString class]] && [actualValue isEqualToString:[expected stringValue]]) {
                return YES;
            }
        }
    }
    if ([expected numberValue] && [actual isArray]) {
        for (id actualValue in [actual arrayValue]) {
            if ([actualValue isKindOfClass:[NSNumber class]] && [[expected numberValue] compare:actualValue] == NSOrderedSame) {
                return YES;
            }
        }
    }
    if ([expected stringValue] && [actual stringValue]) {
        return [[expected stringValue] isEqualToString:[actual stringValue]];
    }
    if ([expected numberValue]) {
        NSNumber *actualNumber = [actual numberValue];
        if (!actualNumber) {
            actualNumber = [NSNumber numberWithDouble:[[actual stringValue] doubleValue]];
        }
        return [[expected numberValue] compare:actualNumber] == NSOrderedSame;
    }
    if ([expected isArray] && [actual isArray]) {
        // USING SETS SINCE THE ORDER OF ITEMS MIGHT BE DIFFERENT
        NSCountedSet *expectedSet = [NSCountedSet setWithArray:[expected arrayValue]];
        NSCountedSet *actualSet = [NSCountedSet setWithArray:[actual arrayValue]];
        return [expectedSet isEqualToSet:actualSet];
    }
    return NO;
}

+ (BOOL)actual:(CTTriggerValue *)actual containsExpected:(CTTriggerValue * __nullable)expected {
    if ([expected stringValue] && [actual stringValue]) {
        return [[actual stringValue] containsString:[expected stringValue]];
    }
    if ([expected isArray] && [actual stringValue]) {
        for (NSString *expectedString in [expected arrayValue]) {
            if ([[actual stringValue] containsString:expectedString]) {
                return YES;
            }
        }
    }
    if ([expected isArray] && [actual isArray]) {
        for (NSString *expectedString in [expected arrayValue]) {
            for (NSString *actualString in [actual arrayValue]) {
                if ([actualString containsString:expectedString]) {
                    return YES;
                }
            }
        }
    }
    if ([expected stringValue] && [actual isArray]) {
        for (NSString *actualString in [actual arrayValue]) {
            if ([actualString containsString:[expected stringValue]]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)actual:(CTTriggerValue *)actual isInRangeOfExpected:(CTTriggerValue * __nullable)expected {
    if ([expected arrayValue] && [expected arrayValue].count >= 2 && ![actual isArray]) {
        NSArray *triggerRange = [expected arrayValue];
        double valueFrom = [triggerRange[0] doubleValue];
        double valueTo = [triggerRange[1] doubleValue];
        return (valueFrom <= [[actual value] doubleValue] <= valueTo);
    }
    return NO;
}

+ (BOOL)evaluateDistance:(NSNumber *)radius expected:(CLLocationCoordinate2D)expected actual:(CLLocationCoordinate2D)actual {
    double distance = [CTUtils haversineDistance:expected coordinateB:actual];
    return distance <= [radius doubleValue];
}

@end
