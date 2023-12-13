//
//  CTTriggerEvaluator.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 10/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggerEvaluator.h"
#import "CTUtils.h"
#import "CTConstants.h"

@implementation CTTriggerEvaluator

+ (BOOL)evaluate:(CTTriggerOperator)op expected:(CTTriggerValue *)expected actual:(CTTriggerValue * __nullable)actual {
    if ([actual isArray]) {
        for (id val in [actual arrayValue]) {
            CTTriggerValue *actualElementValue = [[CTTriggerValue alloc] initWithValue:val];
            if ([self evaluate:op expected:expected basicActual:actualElementValue]) {
                return YES;
            }
        }
        return NO;
    }
    
    return [self evaluate:op expected:expected basicActual:actual];
}

+ (BOOL)evaluate:(CTTriggerOperator)op expected:(CTTriggerValue *)expected basicActual:(CTTriggerValue * __nullable)actual {
    if (actual == nil) {
        if (op == CTTriggerOperatorNotSet) {
            return YES;
        } else {
            return NO;
        }
    }
    
    // actual is not nil
    switch (op) {
        case CTTriggerOperatorSet:
            return YES;
        case CTTriggerOperatorLessThan:
            return [CTTriggerEvaluator expected:expected isLessThan:actual];
        case CTTriggerOperatorGreaterThan:
            return [CTTriggerEvaluator expected:expected isGreaterThan:actual];
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
            return NO;
    }
}

+ (NSNumber * __nullable)numberFromTriggerValue:(CTTriggerValue *)triggerValue {
    if ([triggerValue numberValue]) {
        return [triggerValue numberValue];
    }
    
    NSNumber *number = [CTUtils numberFromString:[triggerValue value]];
    if (number) {
        return number;
    }
    
    return nil;
}

+ (BOOL)equalsStringOrNumber:(id)a with:(id)b {
    if ([a isKindOfClass:[NSString class]]) {
        NSString *aClean = [self cleanString:a];
        if ([b isKindOfClass:[NSString class]]) {
            return [aClean isEqualToString:[self cleanString:b]];
        } else if ([b isKindOfClass:[NSNumber class]]) {
            NSNumber *aNumber = [CTUtils numberFromString:a];
            if ([aClean isEqualToString:CLTAP_TRIGGER_BOOL_STRING_YES]) {
                aNumber = @(YES);
            } else if ([aClean isEqualToString:CLTAP_TRIGGER_BOOL_STRING_NO]) {
                aNumber = @(NO);
            }
            if (aNumber && [aNumber compare:b] == NSOrderedSame) {
                return YES;
            }
        }
    }
    if ([a isKindOfClass:[NSNumber class]]) {
        NSNumber *bNumber = nil;
        if ([b isKindOfClass:[NSNumber class]]) {
            bNumber = b;
        } else if ([b isKindOfClass:[NSString class]]) {
            bNumber = [CTUtils numberFromString:b];
        }
        if (bNumber && [a compare:bNumber] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)cleanString:(NSString *)string {
    NSCharacterSet *whitespaceAndNewline = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [[string lowercaseString] stringByTrimmingCharactersInSet:whitespaceAndNewline];
}

+ (BOOL)expected:(CTTriggerValue *)expected isLessThan:(CTTriggerValue * __nullable)actual {
    return [self expected:expected compareTo:actual withComparisonResult:NSOrderedDescending];
}

+ (BOOL)expected:(CTTriggerValue *)expected isGreaterThan:(CTTriggerValue * __nullable)actual {
    return [self expected:expected compareTo:actual withComparisonResult:NSOrderedAscending];
}

+ (BOOL)expected:(CTTriggerValue *)expected compareTo:(CTTriggerValue * __nullable)actual withComparisonResult:(NSComparisonResult)comparison {
    NSNumber *expectedNumber = [expected numberValue];
    if ([expected isArray] && [[expected arrayValue] count] == 1 && [[expected arrayValue][0] isKindOfClass:[NSNumber class]]) {
        expectedNumber = [expected arrayValue][0];
    }
    if (expectedNumber) {
        NSNumber *actualNumber = [self numberFromTriggerValue:actual];
        if (actualNumber) {
            return [expectedNumber compare:actualNumber] == comparison;
        }
    }
    return NO;
}

+ (BOOL)expected:(CTTriggerValue *)expected equalsActual:(CTTriggerValue * __nullable)actual {
    if (![expected isArray] && ![actual isArray]) {
        return [self equalsStringOrNumber:[expected value] with:[actual value]];
    }
    if ([expected isArray] && ![actual isArray]) {
        for (id expectedValue in [expected arrayValue]) {
            if ([self equalsStringOrNumber:expectedValue with:[actual value]]) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (BOOL)actual:(CTTriggerValue *)actual containsExpected:(CTTriggerValue * __nullable)expected {
    NSString *actualValue = [actual stringValue];
    NSString *expectedValue = [expected stringValue];
    
    if ([actual numberValue]) {
        actualValue = [[actual numberValue] stringValue];
    }
    if ([expected numberValue]) {
        expectedValue = [[expected numberValue] stringValue];
    }
    
    if (actualValue && expectedValue) {
        return [[self cleanString:actualValue] containsString:[self cleanString:expectedValue]];
    }
    if ([expected isArray] && actualValue) {
        for (id expectedElement in [expected arrayValue]) {
            NSString *expectedString;
            if ([expectedElement isKindOfClass:[NSString class]]) {
                expectedString = expectedElement;
            } else if ([expectedElement isKindOfClass:[NSNumber class]]) {
                expectedString = [expectedElement stringValue];
            }
            if (expectedString && [[self cleanString:actualValue] containsString:[self cleanString:expectedString]]) {
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
        NSNumber *actualNumber = [self numberFromTriggerValue:actual];
        if (actualNumber) {
            // this comparison can return <nil> instead of false, check both sides using &&
            return (valueFrom <= [actualNumber doubleValue]) && ([actualNumber doubleValue] <= valueTo);
        }
    }
    return NO;
}

+ (BOOL)evaluateDistance:(NSNumber *)radius expected:(CLLocationCoordinate2D)expected actual:(CLLocationCoordinate2D)actual {
    double distance = [CTUtils haversineDistance:expected coordinateB:actual];
    return distance <= [radius doubleValue];
}

@end
