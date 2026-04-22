//
//  CTTriggerEvaluatorTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTTriggerEvaluator.h"
#import "CTTriggerValue.h"
#import "CTTriggerCondition.h"

/// Helper to build CTTriggerValue concisely
static inline CTTriggerValue *TV(id val) {
    return [[CTTriggerValue alloc] initWithValue:val];
}

@interface CTTriggerEvaluatorTest : XCTestCase
@end

@implementation CTTriggerEvaluatorTest

#pragma mark - Set / NotSet / nil actual

- (void)test_evaluate_set_nonNilActual_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorSet
                                      expected:TV(@"x")
                                        actual:TV(@"anything")]);
}

- (void)test_evaluate_notSet_nilActual_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorNotSet
                                      expected:TV(@"x")
                                        actual:nil]);
}

- (void)test_evaluate_notSet_nonNilActual_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorNotSet
                                       expected:TV(@"x")
                                         actual:TV(@"something")]);
}

- (void)test_evaluate_equals_nilActual_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                       expected:TV(@"hello")
                                         actual:nil]);
}

- (void)test_evaluate_lessThan_nilActual_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorLessThan
                                       expected:TV(@10)
                                         actual:nil]);
}

#pragma mark - Equals (strings)

- (void)test_evaluate_equals_matchingStrings_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                      expected:TV(@"shoes")
                                        actual:TV(@"shoes")]);
}

- (void)test_evaluate_equals_mismatchedStrings_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                       expected:TV(@"shoes")
                                         actual:TV(@"hats")]);
}

- (void)test_evaluate_equals_caseInsensitive_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                      expected:TV(@"Hello")
                                        actual:TV(@"hello")]);
}

- (void)test_evaluate_equals_whitespaceIgnored_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                      expected:TV(@" Hello ")
                                        actual:TV(@"hello")]);
}

#pragma mark - Equals (numbers)

- (void)test_evaluate_equals_matchingNumbers_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                      expected:TV(@42)
                                        actual:TV(@42)]);
}

- (void)test_evaluate_equals_differentNumbers_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                       expected:TV(@42)
                                         actual:TV(@43)]);
}

- (void)test_evaluate_equals_stringNumberCoercion_returnsYes {
    // expected="42" (string), actual=42 (number) → coerced match
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                      expected:TV(@"42")
                                        actual:TV(@42)]);
}

- (void)test_evaluate_equals_numberStringCoercion_returnsYes {
    // expected=42 (number), actual="42" (string) → coerced match
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                      expected:TV(@42)
                                        actual:TV(@"42")]);
}

#pragma mark - NotEquals

- (void)test_evaluate_notEquals_different_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorNotEquals
                                      expected:TV(@"shoes")
                                        actual:TV(@"hats")]);
}

- (void)test_evaluate_notEquals_same_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorNotEquals
                                       expected:TV(@"shoes")
                                         actual:TV(@"shoes")]);
}

#pragma mark - LessThan

- (void)test_evaluate_lessThan_actualLower_returnsYes {
    // expected=10, actual=5 → 5 < 10 → YES
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorLessThan
                                      expected:TV(@10)
                                        actual:TV(@5)]);
}

- (void)test_evaluate_lessThan_actualHigher_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorLessThan
                                       expected:TV(@10)
                                         actual:TV(@15)]);
}

- (void)test_evaluate_lessThan_equal_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorLessThan
                                       expected:TV(@10)
                                         actual:TV(@10)]);
}

#pragma mark - GreaterThan

- (void)test_evaluate_greaterThan_actualHigher_returnsYes {
    // expected=10, actual=15 → 15 > 10 → YES
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorGreaterThan
                                      expected:TV(@10)
                                        actual:TV(@15)]);
}

- (void)test_evaluate_greaterThan_actualLower_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorGreaterThan
                                       expected:TV(@10)
                                         actual:TV(@5)]);
}

#pragma mark - Between

- (void)test_evaluate_between_inRange_returnsYes {
    // expected=[@10,@20], actual=15 → YES
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorBetween
                                      expected:TV(@[@10, @20])
                                        actual:TV(@15)]);
}

- (void)test_evaluate_between_outOfRange_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorBetween
                                       expected:TV(@[@10, @20])
                                         actual:TV(@25)]);
}

- (void)test_evaluate_between_atLowerBoundary_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorBetween
                                      expected:TV(@[@10, @20])
                                        actual:TV(@10)]);
}

- (void)test_evaluate_between_atUpperBoundary_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorBetween
                                      expected:TV(@[@10, @20])
                                        actual:TV(@20)]);
}

#pragma mark - Contains / NotContains

- (void)test_evaluate_contains_substring_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorContains
                                      expected:TV(@"world")
                                        actual:TV(@"hello world")]);
}

- (void)test_evaluate_contains_noSubstring_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorContains
                                       expected:TV(@"bar")
                                         actual:TV(@"foo")]);
}

- (void)test_evaluate_contains_caseInsensitive_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorContains
                                      expected:TV(@"WORLD")
                                        actual:TV(@"hello world")]);
}

- (void)test_evaluate_notContains_substringPresent_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorNotContains
                                       expected:TV(@"world")
                                         actual:TV(@"hello world")]);
}

- (void)test_evaluate_notContains_substringAbsent_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorNotContains
                                      expected:TV(@"xyz")
                                        actual:TV(@"hello world")]);
}

#pragma mark - Array actual (iterates each element)

- (void)test_evaluate_equals_arrayActual_matchesOne_returnsYes {
    // actual is an array — evaluator iterates each element
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                      expected:TV(@3)
                                        actual:TV(@[@1, @3, @5])]);
}

- (void)test_evaluate_equals_arrayActual_noMatch_returnsNo {
    XCTAssertFalse([CTTriggerEvaluator evaluate:CTTriggerOperatorEquals
                                       expected:TV(@9)
                                         actual:TV(@[@1, @2, @4])]);
}

- (void)test_evaluate_contains_arrayActual_matchesOne_returnsYes {
    XCTAssertTrue([CTTriggerEvaluator evaluate:CTTriggerOperatorContains
                                      expected:TV(@"oo")
                                        actual:TV(@[@"bar", @"foo", @"baz"])]);
}

#pragma mark - evaluateDistance

- (void)test_evaluateDistance_withinRadius_returnsYes {
    // Two points ~0 km apart
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(12.9716, 77.5946);
    XCTAssertTrue([CTTriggerEvaluator evaluateDistance:@1000
                                              expected:coord
                                                actual:coord]);
}

- (void)test_evaluateDistance_outsideRadius_returnsNo {
    CLLocationCoordinate2D bangalore = CLLocationCoordinate2DMake(12.9716, 77.5946);
    CLLocationCoordinate2D mumbai    = CLLocationCoordinate2DMake(19.0760, 72.8777);
    // ~840 km apart — radius 100 m should fail
    XCTAssertFalse([CTTriggerEvaluator evaluateDistance:@100
                                               expected:bangalore
                                                 actual:mumbai]);
}

@end
