//
//  CTProfileChangeTrackerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTProfileChangeTracker.h"
#import "CTConstants.h"

@interface CTProfileChangeTrackerTest : XCTestCase
@property (nonatomic, strong) CTProfileChangeTracker *tracker;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *changes;
@end

@implementation CTProfileChangeTrackerTest

- (void)setUp {
    self.tracker = [[CTProfileChangeTracker alloc] init];
    self.changes = [NSMutableDictionary dictionary];
}

#pragma mark - CTProfileChangeTracker: recordChange

- (void)test_recordChange_storesOldAndNewValueAtPath {
    [self.tracker recordChange:@"name" oldValue:@"Alice" newValue:@"Bob" changes:self.changes];
    XCTAssertEqualObjects(self.changes[@"name"][@"oldValue"], @"Alice");
    XCTAssertEqualObjects(self.changes[@"name"][@"newValue"], @"Bob");
}

- (void)test_recordChange_withDatePrefixOldValue_processesDate {
    [self.tracker recordChange:@"dob" oldValue:@"$D_1000" newValue:@"$D_2000" changes:self.changes];
    XCTAssertEqualObjects(self.changes[@"dob"][@"oldValue"], @1000LL);
    XCTAssertEqualObjects(self.changes[@"dob"][@"newValue"], @2000LL);
}

- (void)test_recordChange_overwritesExistingChange {
    [self.tracker recordChange:@"key" oldValue:@"A" newValue:@"B" changes:self.changes];
    [self.tracker recordChange:@"key" oldValue:@"B" newValue:@"C" changes:self.changes];
    XCTAssertEqualObjects(self.changes[@"key"][@"oldValue"], @"B");
    XCTAssertEqualObjects(self.changes[@"key"][@"newValue"], @"C");
}

#pragma mark - CTProfileChangeTracker: recordAllLeafValues

- (void)test_recordAllLeafValues_flatDict_recordsAllKeysAtRootPath {
    NSDictionary *obj = @{@"name": @"Alice", @"age": @30};
    [self.tracker recordAllLeafValues:obj path:@"" changes:self.changes];
    XCTAssertEqualObjects(self.changes[@"name"][@"newValue"], @"Alice");
    XCTAssertEqualObjects(self.changes[@"age"][@"newValue"], @30);
    XCTAssertEqualObjects(self.changes[@"name"][@"oldValue"], [NSNull null]);
}

- (void)test_recordAllLeafValues_nestedDict_buildsDottedPath {
    NSDictionary *obj = @{@"user": @{@"name": @"Bob"}};
    [self.tracker recordAllLeafValues:obj path:@"" changes:self.changes];
    XCTAssertNotNil(self.changes[@"user.name"]);
    XCTAssertEqualObjects(self.changes[@"user.name"][@"newValue"], @"Bob");
}

- (void)test_recordAllLeafValues_withNonEmptyBasePath_prependsPath {
    NSDictionary *obj = @{@"name": @"Carol"};
    [self.tracker recordAllLeafValues:obj path:@"profile" changes:self.changes];
    XCTAssertNotNil(self.changes[@"profile.name"]);
    XCTAssertEqualObjects(self.changes[@"profile.name"][@"newValue"], @"Carol");
}

#pragma mark - CTProfileOperationUtils: isDeleteMarker

- (void)test_isDeleteMarker_withDeleteString_returnsYes {
    XCTAssertTrue([CTProfileOperationUtils isDeleteMarker:kCLTAP_DELETE_MARKER]);
}

- (void)test_isDeleteMarker_withNonDeleteString_returnsNo {
    XCTAssertFalse([CTProfileOperationUtils isDeleteMarker:@"hello"]);
}

- (void)test_isDeleteMarker_withNSNumber_returnsNo {
    XCTAssertFalse([CTProfileOperationUtils isDeleteMarker:@42]);
}

- (void)test_isDeleteMarker_withNil_returnsNo {
    XCTAssertFalse([CTProfileOperationUtils isDeleteMarker:nil]);
}

#pragma mark - CTProfileOperationUtils: processDatePrefixes

- (void)test_processDatePrefixes_withDateString_returnsLongLong {
    id result = [CTProfileOperationUtils processDatePrefixes:@"$D_1609459200"];
    XCTAssertEqualObjects(result, @1609459200LL);
}

- (void)test_processDatePrefixes_withRegularString_returnsUnchanged {
    id result = [CTProfileOperationUtils processDatePrefixes:@"hello"];
    XCTAssertEqualObjects(result, @"hello");
}

- (void)test_processDatePrefixes_withNumber_returnsNumber {
    id result = [CTProfileOperationUtils processDatePrefixes:@42];
    XCTAssertEqualObjects(result, @42);
}

- (void)test_processDatePrefixes_withArray_processesEachElement {
    NSString *dateStr = @"$D_1000";
    NSArray *input = @[dateStr, @"plain", @42];
    NSArray *result = [CTProfileOperationUtils processDatePrefixes:input];
    XCTAssertEqualObjects(result[0], @1000LL);
    XCTAssertEqualObjects(result[1], @"plain");
    XCTAssertEqualObjects(result[2], @42);
}

- (void)test_processDatePrefixes_withDict_processesValues {
    NSDictionary *input = @{@"dob": @"$D_2000", @"name": @"Alice"};
    NSDictionary *result = [CTProfileOperationUtils processDatePrefixes:input];
    XCTAssertEqualObjects(result[@"dob"], @2000LL);
    XCTAssertEqualObjects(result[@"name"], @"Alice");
}

#pragma mark - CTArrayMergeUtils

- (void)test_hasDeleteMarkerElements_withDeleteMarker_returnsYes {
    NSArray *arr = @[kCLTAP_DELETE_MARKER];
    XCTAssertTrue([CTArrayMergeUtils hasDeleteMarkerElements:arr]);
}

- (void)test_hasDeleteMarkerElements_withDeleteMarkerAmongOthers_returnsYes {
    NSArray *arr = @[@"a", kCLTAP_DELETE_MARKER, @"b"];
    XCTAssertTrue([CTArrayMergeUtils hasDeleteMarkerElements:arr]);
}

- (void)test_hasDeleteMarkerElements_withNoDeleteMarker_returnsNo {
    NSArray *arr = @[@"a", @"b"];
    XCTAssertFalse([CTArrayMergeUtils hasDeleteMarkerElements:arr]);
}

- (void)test_hasDeleteMarkerElements_withEmptyArray_returnsNo {
    NSArray *arr = @[];
    XCTAssertFalse([CTArrayMergeUtils hasDeleteMarkerElements:arr]);
}

- (void)test_hasJsonObjectElements_withDictElement_returnsYes {
    NSArray *arr = @[@{@"k": @"v"}];
    XCTAssertTrue([CTArrayMergeUtils hasJsonObjectElements:arr]);
}

- (void)test_hasJsonObjectElements_withStringOnly_returnsNo {
    NSArray *arr = @[@"hello", @42];
    XCTAssertFalse([CTArrayMergeUtils hasJsonObjectElements:arr]);
}

- (void)test_shouldMergeArrayElements_withDictElement_returnsYes {
    NSArray *arr = @[@{@"k": @"v"}];
    XCTAssertTrue([CTArrayMergeUtils shouldMergeArrayElements:arr]);
}

- (void)test_shouldMergeArrayElements_withNumberElement_returnsYes {
    NSArray *arr = @[@42];
    XCTAssertTrue([CTArrayMergeUtils shouldMergeArrayElements:arr]);
}

- (void)test_shouldMergeArrayElements_withStringOnly_returnsNo {
    NSArray *arr = @[@"hello"];
    XCTAssertFalse([CTArrayMergeUtils shouldMergeArrayElements:arr]);
}

- (void)test_arrayContainsString_withMatchingString_returnsYes {
    NSArray *arr = @[@"a", @"b", @"c"];
    XCTAssertTrue([CTArrayMergeUtils arrayContainsString:arr string:@"b"]);
}

- (void)test_arrayContainsString_withNoMatch_returnsNo {
    NSArray *arr = @[@"a", @"b"];
    XCTAssertFalse([CTArrayMergeUtils arrayContainsString:arr string:@"z"]);
}

- (void)test_copyArray_returnsEqualButDistinctObject {
    NSArray *original = @[@"x", @"y"];
    NSArray *copy = [CTArrayMergeUtils copyArray:original];
    XCTAssertEqualObjects(copy, original);
    XCTAssertFalse(copy == original);
}

#pragma mark - CTNumberOperationUtils: addNumbers

- (void)test_addNumbers_twoIntegers_returnsSum {
    NSNumber *result = [CTNumberOperationUtils addNumbers:@5 number:@3];
    XCTAssertEqualObjects(result, @8);
}

- (void)test_addNumbers_twoDoubles_returnsSum {
    NSNumber *result = [CTNumberOperationUtils addNumbers:@(5.0) number:@(2.5)];
    XCTAssertEqualWithAccuracy(result.doubleValue, 7.5, 1e-9);
}

- (void)test_addNumbers_negativeAndPositive_returnsCorrectSum {
    NSNumber *result = [CTNumberOperationUtils addNumbers:@(-3) number:@5];
    XCTAssertEqualObjects(result, @2);
}

#pragma mark - CTNumberOperationUtils: subtractNumbers

- (void)test_subtractNumbers_twoIntegers_returnsDifference {
    NSNumber *result = [CTNumberOperationUtils subtractNumbers:@10 number:@4];
    XCTAssertEqualObjects(result, @6);
}

- (void)test_subtractNumbers_twoDoubles_returnsDifference {
    NSNumber *result = [CTNumberOperationUtils subtractNumbers:@(5.0) number:@(2.0)];
    XCTAssertEqualWithAccuracy(result.doubleValue, 3.0, 1e-9);
}

- (void)test_subtractNumbers_resultIsNegative {
    NSNumber *result = [CTNumberOperationUtils subtractNumbers:@3 number:@8];
    XCTAssertEqualObjects(result, @(-5));
}

#pragma mark - CTNumberOperationUtils: negateNumber

- (void)test_negateNumber_positiveInt_returnsNegative {
    NSNumber *result = [CTNumberOperationUtils negateNumber:@7];
    XCTAssertEqualObjects(result, @(-7));
}

- (void)test_negateNumber_negativeInt_returnsPositive {
    NSNumber *result = [CTNumberOperationUtils negateNumber:@(-4)];
    XCTAssertEqualObjects(result, @4);
}

- (void)test_negateNumber_double_returnsNegated {
    NSNumber *result = [CTNumberOperationUtils negateNumber:@(3.0)];
    XCTAssertEqualWithAccuracy(result.doubleValue, -3.0, 1e-9);
}

- (void)test_negateNumber_zero_returnsZero {
    NSNumber *result = [CTNumberOperationUtils negateNumber:@0];
    XCTAssertEqualObjects(result, @0);
}

#pragma mark - CTJsonComparisonUtils: areEqual

- (void)test_areEqual_sameStrings_returnsYes {
    NSString *a = @"hello";
    NSString *b = @"hello";
    XCTAssertTrue([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_differentStrings_returnsNo {
    NSString *a = @"hello";
    NSString *b = @"world";
    XCTAssertFalse([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_sameNumbers_returnsYes {
    NSNumber *a = @42;
    NSNumber *b = @42;
    XCTAssertTrue([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_differentNumbers_returnsNo {
    NSNumber *a = @42;
    NSNumber *b = @43;
    XCTAssertFalse([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_sameArrays_returnsYes {
    NSArray *a = @[@1, @2];
    NSArray *b = @[@1, @2];
    XCTAssertTrue([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_differentArrays_returnsNo {
    NSArray *a = @[@1];
    NSArray *b = @[@2];
    XCTAssertFalse([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_sameDicts_returnsYes {
    NSDictionary *a = @{@"k": @"v"};
    NSDictionary *b = @{@"k": @"v"};
    XCTAssertTrue([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_differentDicts_returnsNo {
    NSDictionary *a = @{@"k": @"v1"};
    NSDictionary *b = @{@"k": @"v2"};
    XCTAssertFalse([CTJsonComparisonUtils areEqual:a value:b]);
}

- (void)test_areEqual_bothNil_returnsYes {
    XCTAssertTrue([CTJsonComparisonUtils areEqual:nil value:nil]);
}

- (void)test_areEqual_firstNil_returnsNo {
    XCTAssertFalse([CTJsonComparisonUtils areEqual:nil value:@"hello"]);
}

- (void)test_areEqual_secondNil_returnsNo {
    XCTAssertFalse([CTJsonComparisonUtils areEqual:@"hello" value:nil]);
}

- (void)test_areEqual_sameObjectReference_returnsYes {
    NSObject *obj = [[NSObject alloc] init];
    XCTAssertTrue([CTJsonComparisonUtils areEqual:obj value:obj]);
}

@end
