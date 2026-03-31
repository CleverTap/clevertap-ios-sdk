//
//  CTTriggerConditionTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTTriggerCondition.h"
#import "CTTriggerValue.h"

@interface CTTriggerConditionTest : XCTestCase
@end

@implementation CTTriggerConditionTest

- (void)test_init_setsAllProperties {
    CTTriggerValue *value = [[CTTriggerValue alloc] initWithValue:@"shoes"];
    CTTriggerCondition *cond = [[CTTriggerCondition alloc]
                                initWithProperyName:@"category"
                                        andOperator:CTTriggerOperatorEquals
                                           andValue:value];
    XCTAssertEqualObjects(cond.propertyName, @"category");
    XCTAssertEqual(cond.op, CTTriggerOperatorEquals);
    XCTAssertEqual(cond.value, value);
}

- (void)test_init_castsOperatorToEnum_equals {
    CTTriggerValue *value = [[CTTriggerValue alloc] initWithValue:@0];
    CTTriggerCondition *cond = [[CTTriggerCondition alloc]
                                initWithProperyName:@"price"
                                        andOperator:1  // raw NSUInteger for Equals
                                           andValue:value];
    XCTAssertEqual(cond.op, CTTriggerOperatorEquals);
}

- (void)test_init_castsOperatorToEnum_greaterThan {
    CTTriggerValue *value = [[CTTriggerValue alloc] initWithValue:@100];
    CTTriggerCondition *cond = [[CTTriggerCondition alloc]
                                initWithProperyName:@"amount"
                                        andOperator:0  // raw NSUInteger for GreaterThan
                                           andValue:value];
    XCTAssertEqual(cond.op, CTTriggerOperatorGreaterThan);
}

- (void)test_init_castsOperatorToEnum_notContains {
    CTTriggerValue *value = [[CTTriggerValue alloc] initWithValue:@"red"];
    CTTriggerCondition *cond = [[CTTriggerCondition alloc]
                                initWithProperyName:@"color"
                                        andOperator:28  // NotContains
                                           andValue:value];
    XCTAssertEqual(cond.op, CTTriggerOperatorNotContains);
}

@end
