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
            return NO; // TODO: Implement all cases as per the backed evaluation and remove this line
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

+ (BOOL)isEqualsStringOrNumber:(id)a with:(id)b {
    if ([a isKindOfClass:[NSString class]]) {
        if ([b isKindOfClass:[NSString class]]) {
            return [a isEqualToString:b];
        } else if ([b isKindOfClass:[NSNumber class]]) {
            NSNumber *aNumber = [CTUtils numberFromString:a];
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

+ (BOOL)expected:(CTTriggerValue *)expected isLessThan:(CTTriggerValue * __nullable)actual {
    if ([expected numberValue]) {
        NSNumber *actualNumber = [self numberFromTriggerValue:actual];
        if (actualNumber) {
            return [[expected numberValue] compare:actualNumber] == NSOrderedDescending;
        }
    }
    return NO;
}

+ (BOOL)expected:(CTTriggerValue *)expected isGreaterThan:(CTTriggerValue * __nullable)actual {
    if ([expected numberValue]) {
        NSNumber *actualNumber = [self numberFromTriggerValue:actual];
        if (actualNumber) {
            return [[expected numberValue] compare:actualNumber] == NSOrderedAscending;
        }
    }
    return NO;
}

+ (BOOL)expected:(CTTriggerValue *)expected equalsActual:(CTTriggerValue * __nullable)actual {
    if (![expected isArray] && ![actual isArray]) {
        return [self isEqualsStringOrNumber:[expected value] with:[actual value]];
    }
    
    if ([expected stringValue] && [actual isArray]) {
        for (id actualValue in [actual arrayValue]) {
            if ([self isEqualsStringOrNumber:[expected value] with:actualValue]) {
                return YES;
            }
        }
    }
    
    if ([expected numberValue] && [actual isArray]) {
        for (id actualValue in [actual arrayValue]) {
            if ([self isEqualsStringOrNumber:[expected value] with:actualValue]) {
                return YES;
            }
        }
    }

    if ([expected isArray] && [actual isArray]) {
        for (id expectedValue in [expected arrayValue]) {
            for (id actualValue in [actual arrayValue]) {
                if ([self isEqualsStringOrNumber:expectedValue with:actualValue]) {
                    return YES;
                }
            }
        }
    }
    
    if ([expected isArray] && ![actual isArray]) {
        for (id expectedValue in [expected arrayValue]) {
            if ([self isEqualsStringOrNumber:expectedValue with:[actual value]]) {
                return YES;
            }
        }
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
        NSNumber *actualNumber = [self numberFromTriggerValue:actual];
        if (actualNumber) {
            return (valueFrom <= [actualNumber doubleValue] <= valueTo);
        }
    }
    return NO;
}

+ (BOOL)evaluateDistance:(NSNumber *)radius expected:(CLLocationCoordinate2D)expected actual:(CLLocationCoordinate2D)actual {
    double distance = [CTUtils haversineDistance:expected coordinateB:actual];
    return distance <= [radius doubleValue];
}

@end
