//
//  CTValidatorTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 27/04/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTValidator.h"
#import "CTValidationResult.h"

@interface CTValidatorTest : XCTestCase

@end

@implementation CTValidatorTest

- (void)test_cleanEventName_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test.Event:Name$";
    CTValidationResult *result = [CTValidator cleanEventName:eventName];
    XCTAssertEqualObjects(result.object, @"TestEventName");
}

- (void)test_cleanEventName_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTValidationResult *result = [CTValidator cleanEventName:eventName];
    XCTAssertEqualObjects(result.object, @"Test Event Name");
}

- (void)test_cleanEventName_LimitsNameLength {
    NSString *eventName = @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890";
    CTValidationResult *result = [CTValidator cleanEventName:eventName];
    NSString *expectedError = [NSString stringWithFormat:@"%@%@", @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijk", @"... exceeded the limit of 120 characters. Trimmed"];
    XCTAssertEqualObjects(result.errorDesc, expectedError);
    XCTAssertEqual(result.errorCode, 510);
}

- (void)test_cleanEventName_withEmptyString {
    NSString *eventName = @"";
    CTValidationResult *result = [CTValidator cleanEventName:eventName];
    XCTAssertNil(result.object);
}

- (void)test_cleanEventName_withNilNameString {
    CTValidationResult *result = [CTValidator cleanEventName:nil];
    XCTAssertNil(result.object);
}

- (void)test_cleanObjectKey_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test.Event:Name$";
    CTValidationResult *result = [CTValidator cleanObjectKey:eventName];
    XCTAssertEqualObjects(result.object, @"TestEventName");
}

- (void)test_cleanObjectKey_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTValidationResult *result = [CTValidator cleanObjectKey:eventName];
    XCTAssertEqualObjects(result.object, @"Test Event Name");
}

- (void)test_cleanObjectKey_LimitsNameLength {
    NSString *eventName = @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890";
    CTValidationResult *result = [CTValidator cleanObjectKey:eventName];
    NSString *expectedError = [NSString stringWithFormat:@"%@%@", @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijk", @"... exceeded the limit of 120 characters. Trimmed"];
    XCTAssertEqualObjects(result.errorDesc, expectedError);
    XCTAssertEqual(result.errorCode, 520);
}

- (void)test_cleanObjectKey_withEmptyString {
    NSString *eventName = @"";
    CTValidationResult *result = [CTValidator cleanObjectKey:eventName];
    XCTAssertNil(result.object);
}

- (void)test_cleanObjectKey_withNilNameString {
    CTValidationResult *result = [CTValidator cleanObjectKey:nil];
    XCTAssertNil(result.object);
}

- (void)test_cleanMultiValuePropertyKey_doesNotAcceptKnownField {
    NSString *propertyKey = @"Email";
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyKey:propertyKey];
    NSString *expectedError = [NSString stringWithFormat:@"%@%@", propertyKey, @" is a restricted key for multi-value properties. Operation aborted."];
    XCTAssertEqualObjects(result.errorDesc, expectedError);
    XCTAssertEqual(result.errorCode, 523);
    XCTAssertNil(result.object);
}

- (void)test_cleanMultiValuePropertyValue_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test'Event\"Name";
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyValue:eventName];
    XCTAssertEqualObjects(result.object, @"testeventname");
}

- (void)test_cleanMultiValuePropertyValue_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyValue:eventName];
    XCTAssertEqualObjects(result.object, @"test event name");
}

- (void)test_cleanMultiValuePropertyValue_LimitsNameLength {
    NSString *eventName = @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890";
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyValue:eventName];
    NSString *expectedError = [NSString stringWithFormat:@"%@%@", @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmno", @"... exceeds the limit of 1024 characters. Trimmed"];
    XCTAssertEqualObjects(result.errorDesc, expectedError);
    XCTAssertEqual(result.errorCode, 521);
}

- (void)test_cleanMultiValuePropertyValue_withEmptyString {
    NSString *eventName = @"";
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyValue:eventName];
    XCTAssertEqualObjects(result.object, @"");
}

- (void)test_cleanMultiValuePropertyValue_withNilNameString {
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyValue:nil];
    XCTAssertNil(result.object);
}

- (void)test_cleanMultiValuePropertyArray {
    NSArray *multi = @[@"value1", @"value2", @"value3"];
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyArray:multi forKey:@"testKey"];
    XCTAssertNotNil(result.object);
    XCTAssertEqual(result.object, multi);
    XCTAssertNil(result.errorDesc);
    XCTAssertEqual(result.errorCode, 0);
}

- (void)test_cleanMultiValuePropertyArray_LimitsArrayCount {
    NSMutableArray *multi = [[NSMutableArray alloc] init];
    for (int i = 0; i < 101; i++){
        [multi addObject:[NSString stringWithFormat:@"value%d", i]];
    }
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyArray:multi forKey:@"testKey"];
    NSArray *expectedArray = [multi subarrayWithRange:NSMakeRange((NSUInteger) 1, (NSUInteger) 100)];
    NSString *expectedError = [NSString stringWithFormat:@"Multi value user property for key testKey exceeds the limit of %d items. Trimmed", 100];
    
    XCTAssertNotNil(result.object);
    XCTAssertEqualObjects(result.object, expectedArray);
    XCTAssertEqualObjects(result.errorDesc, expectedError);
    XCTAssertEqual(result.errorCode, 521);
}

- (void)test_cleanMultiValuePropertyArray_withNilInput {
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyArray:nil forKey:@"testKey"];
    XCTAssertNil(result.object);
    XCTAssertNil(result.errorDesc);
    XCTAssertEqual(result.errorCode, 0);
}

- (void)test_cleanMultiValuePropertyArray_withEmptyArray {
    NSArray *multi = @[];
    CTValidationResult *result = [CTValidator cleanMultiValuePropertyArray:multi forKey:@"testKey"];
    XCTAssertNotNil(result.object);
    XCTAssertEqual(result.object, multi);
    XCTAssertNil(result.errorDesc);
    XCTAssertEqual(result.errorCode, 0);
}

- (void)test_cleanObjectValue_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test'Event\"Name";
    CTValidationResult *result = [CTValidator cleanObjectValue:eventName context:CTValidatorContextProfile];
    XCTAssertEqualObjects(result.object, @"TestEventName");
}

- (void)test_cleanObjectValue_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTValidationResult *result = [CTValidator cleanObjectValue:eventName context:CTValidatorContextProfile];
    XCTAssertEqualObjects(result.object, @"Test Event Name");
}

- (void)test_cleanObjectValue_LimitsNameLength {
    NSString *longStr = [@"" stringByPaddingToLength:1100 withString:@"a" startingAtIndex:0];
    CTValidationResult *result = [CTValidator cleanObjectValue:longStr context:CTValidatorContextProfile];
    NSString *expectedError = [NSString stringWithFormat:@"%@... exceeds the limit of %d characters. Trimmed", [longStr substringToIndex:1023], 1024];
    
    XCTAssertNotNil(result);
    XCTAssertEqual(result.errorCode, 521);
    XCTAssertEqualObjects(result.errorDesc, expectedError);
}

- (void)test_cleanObjectValue_withEmptyString {
    NSString *eventName = @"";
    CTValidationResult *result = [CTValidator cleanObjectValue:eventName context:CTValidatorContextProfile];
    XCTAssertEqualObjects(result.object, @"");
}

- (void)test_cleanObjectValue_withNilNameString {
    CTValidationResult *result = [CTValidator cleanObjectValue:nil context:CTValidatorContextProfile];
    XCTAssertNil(result.object);
}

- (void)test_cleanObjectValue_withValidNumberInput {
    NSNumber *num = [NSNumber numberWithInt:42];
    CTValidationResult *result = [CTValidator cleanObjectValue:num context:CTValidatorContextProfile];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.object, num);
}

- (void)test_cleanObjectValue_withValidDateInput {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:78];
    CTValidationResult *result = [CTValidator cleanObjectValue:date context:CTValidatorContextProfile];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.object, @"$D_78");
}

- (void)test_cleanObjectValue_withValidArrayInput {
    NSArray *arr = @[@"apple", @"banana", @"cherry"];
    CTValidationResult *result = [CTValidator cleanObjectValue:arr context:CTValidatorContextProfile];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.object, arr);
}

- (void)test_cleanObjectValue_withNonStringArrayElementsInput {
    NSArray *arr = @[@"apple", @"banana", @42, @"cherry"];
    CTValidationResult *result = [CTValidator cleanObjectValue:arr context:CTValidatorContextProfile];
    NSArray *expectedArr = @[@"apple", @"banana", @"42", @"cherry"];

    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.object, expectedArr);
}

- (void)test_cleanObjectValue_LimitsArrayCount {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 101; i++){
        [arr addObject:[NSString stringWithFormat:@"value%d", i]];
    }
    
    CTValidationResult *result = [CTValidator cleanObjectValue:arr context:CTValidatorContextProfile];
    NSString *expectedError = [NSString stringWithFormat:@"Invalid user profile property array count: 101; max is: 100"];
    
    XCTAssertNil(result.object);
    XCTAssertEqualObjects(result.errorDesc, expectedError);
    XCTAssertEqual(result.errorCode, 521);
}

- (void)test_isRestrictedEventName_withoutRestrictedNameInput {
    NSString *inputString = @"userLogged";
    
    BOOL result = [CTValidator isRestrictedEventName:inputString];
    XCTAssertFalse(result);
}

- (void)test_isRestrictedEventName_withRestrictedNameInput {
    NSString *inputString = @"App Launched";
    
    BOOL result = [CTValidator isRestrictedEventName:inputString];
    XCTAssertTrue(result);
}

- (void)test_isRestrictedEventName_withEmptyInput {
    NSString *inputString = @"";
    
    BOOL result = [CTValidator isRestrictedEventName:inputString];
    XCTAssertFalse(result);
}

- (void)test_isRestrictedEventName_withNilInput {
    BOOL result = [CTValidator isRestrictedEventName:nil];
    XCTAssertFalse(result);
}

- (void)test_isDiscaredEventName_withoutDiscardedNameInput {
    [CTValidator setDiscardedEvents:@[@"aa",@"bb"]];
    NSString *inputString = @"userLogged";
    
    BOOL result = [CTValidator isDiscaredEventName:inputString];
    XCTAssertFalse(result);
}

- (void)test_isDiscaredEventName_withDiscardedNameInput {
    [CTValidator setDiscardedEvents:@[@"aa",@"bb"]];
    NSString *inputString = @"aa";
    
    BOOL result = [CTValidator isDiscaredEventName:inputString];
    XCTAssertTrue(result);
}

- (void)test_isDiscaredEventName_withEmptyInput {
    NSString *inputString = @"";
    
    BOOL result = [CTValidator isDiscaredEventName:inputString];
    XCTAssertFalse(result);
}

- (void)test_isDiscaredEventName_withNilInput {
    BOOL result = [CTValidator isDiscaredEventName:nil];
    XCTAssertFalse(result);
}

- (void)test_isValidCleverTapId_withValidInput {
    BOOL result = [CTValidator isValidCleverTapId:@"sampleCTid"];
    XCTAssertTrue(result);
}

- (void)test_isValidCleverTapId_withMoreThanMaxInput {
    NSString *inputString = [@"" stringByPaddingToLength:65 withString:@"a" startingAtIndex:0];
    
    BOOL result = [CTValidator isValidCleverTapId:inputString];
    XCTAssertFalse(result);
}

- (void)test_isValidCleverTapId_withNotAllowedSpecialCharsInput {
    BOOL result = [CTValidator isValidCleverTapId:@"#clevertap"];
    XCTAssertFalse(result);
}

- (void)test_isValidCleverTapId_withEmptyInput {
    BOOL result = [CTValidator isValidCleverTapId:@""];
    XCTAssertFalse(result);
}

- (void)test_isValidCleverTapId_withNilInput {
    BOOL result = [CTValidator isValidCleverTapId:nil];
    XCTAssertFalse(result);
}

@end
