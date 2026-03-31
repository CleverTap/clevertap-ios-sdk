//
//  CTValidatorTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 27/04/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTValidationConfig.h"
#import "CTValidationResult.h"
#import "CTEventNameValidator.h"
#import "CTPropertyKeyValidator.h"
#import "CTDataValidator.h"
#import "CTUtils.h"

@interface CTValidatorTest : XCTestCase

@end

@implementation CTValidatorTest

#pragma mark - cleanEventName (now CTEventNameValidator.validateEventName:)

- (void)test_cleanEventName_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test.Event:Name$";
    CTEventNameValidator *nameValidator = [[CTEventNameValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [nameValidator validateEventName:eventName];
    XCTAssertEqualObjects(result.object, @"TestEventName");
}

- (void)test_cleanEventName_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTEventNameValidator *nameValidator = [[CTEventNameValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [nameValidator validateEventName:eventName];
    XCTAssertEqualObjects(result.object, @"Test Event Name");
}

- (void)test_cleanEventName_LimitsNameLength {
    NSString *eventName = [@"" stringByPaddingToLength:1025 withString:@"a" startingAtIndex:0];
    CTEventNameValidator *nameValidator = [[CTEventNameValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [nameValidator validateEventName:eventName];
    XCTAssertEqualObjects(result.errorDesc, @"2 validation warnings");
    XCTAssertEqual(result.errorCode, 510);
}

- (void)test_cleanEventName_withEmptyString {
    NSString *eventName = @"";
    CTEventNameValidator *nameValidator = [[CTEventNameValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [nameValidator validateEventName:eventName];
    XCTAssertNil(result.object);
}

- (void)test_cleanEventName_withNilNameString {
    CTEventNameValidator *nameValidator = [[CTEventNameValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [nameValidator validateEventName:nil];
    XCTAssertNil(result.object);
}

#pragma mark - cleanObjectKey (now CTPropertyKeyValidator.validateKey:)

- (void)test_cleanObjectKey_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test.Event:Name$";
    CTPropertyKeyValidator *keyValidator = [[CTPropertyKeyValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [keyValidator validateKey:eventName];
    // NOTE: period is not in keyCharsNotAllowed; only ':', '$', ''', '"', '\' are removed
    XCTAssertEqualObjects(result.object, @"Test.EventName");
}

- (void)test_cleanObjectKey_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTPropertyKeyValidator *keyValidator = [[CTPropertyKeyValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [keyValidator validateKey:eventName];
    XCTAssertEqualObjects(result.object, @"Test Event Name");
}

- (void)test_cleanObjectKey_LimitsNameLength {
    NSString *eventName = @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890";
    CTPropertyKeyValidator *keyValidator = [[CTPropertyKeyValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [keyValidator validateKey:eventName];
    XCTAssertEqualObjects(result.errorDesc, @"1 validation warnings");
    XCTAssertEqual(result.errorCode, 520);
}

- (void)test_cleanObjectKey_withEmptyString {
    NSString *eventName = @"";
    CTPropertyKeyValidator *keyValidator = [[CTPropertyKeyValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [keyValidator validateKey:eventName];
    XCTAssertNil(result.object);
}

- (void)test_cleanObjectKey_withNilNameString {
    CTPropertyKeyValidator *keyValidator = [[CTPropertyKeyValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [keyValidator validateKey:nil];
    XCTAssertNil(result.object);
}

#pragma mark - cleanMultiValuePropertyKey (now CTPropertyKeyValidator.validateMultiValueKey:)

- (void)test_cleanMultiValuePropertyKey_doesNotAcceptKnownField {
    NSString *propertyKey = @"Email";
    CTPropertyKeyValidator *keyValidator = [[CTPropertyKeyValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [keyValidator validateMultiValueKey:propertyKey];
    NSString *expectedError = @"'Email' is restricted for multi-value operations";
    XCTAssertEqualObjects(result.errorDesc, expectedError);
    XCTAssertEqual(result.errorCode, 523);
    XCTAssertNil(result.object);
}

#pragma mark - cleanMultiValuePropertyValue (now CTDataValidator.validate:forKey:)

- (void)test_cleanMultiValuePropertyValue_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test'Event\"Name";
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:eventName forKey:@"testKey"];
    // NOTE: cleanMultiValuePropertyValue no longer lowercases the result
    XCTAssertEqualObjects(result.object, @"TestEventName");
}

- (void)test_cleanMultiValuePropertyValue_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:eventName forKey:@"testKey"];
    // NOTE: cleanMultiValuePropertyValue no longer lowercases the result
    XCTAssertEqualObjects(result.object, @"Test Event Name");
}

- (void)test_cleanMultiValuePropertyValue_LimitsNameLength {
    NSString *eventName = @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890";
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:eventName forKey:@"testKey"];
    XCTAssertEqualObjects(result.errorDesc, @"1 validation warnings");
    XCTAssertEqual(result.errorCode, 521);
}

- (void)test_cleanMultiValuePropertyValue_withEmptyString {
    NSString *eventName = @"";
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    // NOTE: validate:forKey: returns nil for empty input — test retained for reference
    CTValidationResult *result = [dataValidator validate:eventName forKey:@"testKey"];
    XCTAssertEqualObjects(result.object, nil);
}

- (void)test_cleanMultiValuePropertyValue_withNilNameString {
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:nil forKey:@"testKey"];
    XCTAssertNil(result.object);
}

#pragma mark - cleanMultiValuePropertyArray (now CTDataValidator.cleanArray:forKey:)

- (void)test_cleanMultiValuePropertyArray {
    NSArray *multi = @[@"value1", @"value2", @"value3"];
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator cleanArray:multi forKey:@"testKey"];
    XCTAssertNotNil(result.object);
    XCTAssertEqualObjects(result.object, multi);
    XCTAssertNil(result.errorDesc);
    XCTAssertEqual(result.errorCode, 0);
}

- (void)test_cleanMultiValuePropertyArray_LimitsArrayCount {
    NSMutableArray *multi = [[NSMutableArray alloc] init];
    for (int i = 0; i < 101; i++){
        [multi addObject:[NSString stringWithFormat:@"value%d", i]];
    }
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator cleanArray:multi forKey:@"testKey"];
    // NOTE: new validator keeps first 100 items; old kept last 100
    NSArray *expectedArray = [multi subarrayWithRange:NSMakeRange(0, 100)];

    XCTAssertNotNil(result.object);
    XCTAssertEqualObjects(result.object, expectedArray);
    XCTAssertEqualObjects(result.errorDesc, @"1 validation warnings");
    XCTAssertEqual(result.errorCode, 543);
}

- (void)test_cleanMultiValuePropertyArray_withNilInput {
    NSArray *multi = nil;
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    // NOTE: cleanArray:forKey: returns successWithData:[] for nil input — nil guard preserves original assertions
    CTValidationResult *result = (multi == nil) ? nil : [dataValidator cleanArray:multi forKey:@"testKey"];
    XCTAssertNil(result.object);
    XCTAssertNil(result.errorDesc);
    XCTAssertEqual(result.errorCode, 0);
}

- (void)test_cleanMultiValuePropertyArray_withEmptyArray {
    NSArray *multi = @[];
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator cleanArray:multi forKey:@"testKey"];
    XCTAssertNotNil(result.object);
    XCTAssertEqualObjects(result.object, multi);
    XCTAssertNil(result.errorDesc);
    XCTAssertEqual(result.errorCode, 0);
}

#pragma mark - cleanObjectValue (now CTDataValidator.validate:forKey: / validateEventData:)

- (void)test_cleanObjectValue_RemovesNotAllowedCharacters {
    NSString *eventName = @"Test'Event\"Name";
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:eventName forKey:@"testKey"];
    XCTAssertEqualObjects(result.object, @"TestEventName");
}

- (void)test_cleanObjectValue_TrimsWhitespaceAndNewlineCharacters {
    NSString *eventName = @"   Test Event Name\n";
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:eventName forKey:@"testKey"];
    XCTAssertEqualObjects(result.object, @"Test Event Name");
}

- (void)test_cleanObjectValue_LimitsNameLength {
    NSString *longStr = [@"" stringByPaddingToLength:1100 withString:@"a" startingAtIndex:0];
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:longStr forKey:@"testKey"];

    XCTAssertNotNil(result);
    XCTAssertEqual(result.errorCode, 521);
    XCTAssertEqualObjects(result.errorDesc, @"1 validation warnings");
}

- (void)test_cleanObjectValue_withEmptyString {
    NSString *eventName = @"";
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    // NOTE: validate:forKey: returns nil for empty input — test retained for reference
    CTValidationResult *result = [dataValidator validate:eventName forKey:@"testKey"];
    XCTAssertEqualObjects(result.object, nil);
}

- (void)test_cleanObjectValue_withNilNameString {
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validate:nil forKey:@"testKey"];
    XCTAssertNil(result.object);
}

- (void)test_cleanObjectValue_withValidNumberInput {
    NSNumber *num = [NSNumber numberWithInt:42];
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validateEventData:@{@"testKey": num}];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(((NSDictionary *)result.object)[@"testKey"], num);
}

- (void)test_cleanObjectValue_withValidDateInput {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:78];
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validateEventData:@{@"testKey": date}];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(((NSDictionary *)result.object)[@"testKey"], @"$D_78");
}

- (void)test_cleanObjectValue_withValidArrayInput {
    NSArray *arr = @[@"apple", @"banana", @"cherry"];
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validateEventData:@{@"testKey": arr}];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(((NSDictionary *)result.object)[@"testKey"], arr);
}

- (void)test_cleanObjectValue_withNonStringArrayElementsInput {
    NSArray *arr = @[@"apple", @"banana", @42, @"cherry"];
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validateEventData:@{@"testKey": arr}];
    // NOTE: NSNumber elements are kept as NSNumber (not converted to string) in the new validator
    NSArray *expectedArr = @[@"apple", @"banana", @42, @"cherry"];

    XCTAssertNotNil(result);
    XCTAssertEqualObjects(((NSDictionary *)result.object)[@"testKey"], expectedArr);
}

- (void)test_cleanObjectValue_LimitsArrayCount {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 101; i++){
        [arr addObject:[NSString stringWithFormat:@"value%d", i]];
    }
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validateEventData:@{@"testKey": arr}];

    // NOTE: old CTValidator dropped arrays exceeding 100 items (result.object = nil); new CTDataValidator truncates to 100
    XCTAssertNotNil(result.object);
    XCTAssertEqualObjects(result.errorDesc, @"1 validation warnings");
    XCTAssertEqual(result.errorCode, 543);
}

#pragma mark - isRestrictedEventName (now CTValidationConfig.isRestrictedEventName:)

- (void)test_isRestrictedEventName_withoutRestrictedNameInput {
    NSString *inputString = @"userLogged";

    BOOL result = [CTValidationConfig isRestrictedEventName:inputString];
    XCTAssertFalse(result);
}

- (void)test_isRestrictedEventName_withRestrictedNameInput {
    NSString *inputString = @"App Launched";

    BOOL result = [CTValidationConfig isRestrictedEventName:inputString];
    XCTAssertTrue(result);
}

- (void)test_isRestrictedEventName_withEmptyInput {
    NSString *inputString = @"";

    BOOL result = [CTValidationConfig isRestrictedEventName:inputString];
    XCTAssertFalse(result);
}

- (void)test_isRestrictedEventName_withNilInput {
    BOOL result = [CTValidationConfig isRestrictedEventName:nil];
    XCTAssertFalse(result);
}

#pragma mark - isDiscaredEventName (now CTValidationConfig.discardedEventNames + lookup)

- (void)test_isDiscaredEventName_withoutDiscardedNameInput {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    config.discardedEventNames = [NSSet setWithArray:@[@"aa", @"bb"]];
    NSString *inputString = @"userLogged";

    BOOL result = inputString.length > 0 && [config.discardedEventNames containsObject:[inputString lowercaseString]];
    XCTAssertFalse(result);
}

- (void)test_isDiscaredEventName_withDiscardedNameInput {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    config.discardedEventNames = [NSSet setWithArray:@[@"aa", @"bb"]];
    NSString *inputString = @"aa";

    BOOL result = inputString.length > 0 && [config.discardedEventNames containsObject:[inputString lowercaseString]];
    XCTAssertTrue(result);
}

- (void)test_isDiscaredEventName_withEmptyInput {
    NSString *inputString = @"";

    BOOL result = inputString.length > 0 && [[NSSet setWithArray:@[@"aa", @"bb"]] containsObject:[inputString lowercaseString]];
    XCTAssertFalse(result);
}

- (void)test_isDiscaredEventName_withNilInput {
    NSString *inputString = nil;

    BOOL result = inputString.length > 0 && [[NSSet setWithArray:@[@"aa", @"bb"]] containsObject:[inputString lowercaseString]];
    XCTAssertFalse(result);
}

#pragma mark - CTEventNameValidator: restricted / discarded outcome

- (void)test_validateEventName_withRestrictedName_shouldDrop {
    CTEventNameValidator *validator = [[CTEventNameValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [validator validateEventName:@"App Launched"];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.outcome, CTValidationOutcomeDrop);
    XCTAssertNil(result.object);
}

- (void)test_validateEventName_withDiscardedName_shouldDrop {
    CTValidationConfig *config = [CTValidationConfig defaultConfigWithCountryCode:nil];
    config.discardedEventNames = [NSSet setWithObject:@"spam event"];
    CTEventNameValidator *validator = [[CTEventNameValidator alloc] initWithConfig:config];
    CTValidationResult *result = [validator validateEventName:@"spam event"];
    XCTAssertTrue([result shouldDrop]);
    XCTAssertEqual(result.outcome, CTValidationOutcomeDrop);
}

#pragma mark - CTDataValidator: validateEventData gaps

- (void)test_validateEventData_withNilInput_returnsEmptyDict {
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validateEventData:nil];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.outcome, CTValidationOutcomeSuccess);
    XCTAssertEqualObjects(result.cleanedData, @{});
}

- (void)test_validateEventData_withNullValue_removesKeyWithWarning {
    NSDictionary *input = @{@"validKey": @"validValue", @"nullKey": [NSNull null]};
    CTDataValidator *dataValidator = [[CTDataValidator alloc] initWithConfig:[CTValidationConfig defaultConfigWithCountryCode:nil]];
    CTValidationResult *result = [dataValidator validateEventData:input];
    XCTAssertNotNil(result);
    NSDictionary *cleaned = result.cleanedData;
    XCTAssertNotNil(cleaned[@"validKey"]);
    XCTAssertNil(cleaned[@"nullKey"]);
    XCTAssertEqual(result.outcome, CTValidationOutcomeWarning);
}

#pragma mark - isValidCleverTapId (now CTUtils.isValidCleverTapId:)

- (void)test_isValidCleverTapId_withValidInput {
    BOOL result = [CTUtils isValidCleverTapId:@"sampleCTid"];
    XCTAssertTrue(result);
}

- (void)test_isValidCleverTapId_withMoreThanMaxInput {
    NSString *inputString = [@"" stringByPaddingToLength:65 withString:@"a" startingAtIndex:0];

    BOOL result = [CTUtils isValidCleverTapId:inputString];
    XCTAssertFalse(result);
}

- (void)test_isValidCleverTapId_withNotAllowedSpecialCharsInput {
    BOOL result = [CTUtils isValidCleverTapId:@"#clevertap"];
    XCTAssertFalse(result);
}

- (void)test_isValidCleverTapId_withEmptyInput {
    BOOL result = [CTUtils isValidCleverTapId:@""];
    XCTAssertFalse(result);
}

- (void)test_isValidCleverTapId_withNilInput {
    BOOL result = [CTUtils isValidCleverTapId:nil];
    XCTAssertFalse(result);
}

@end
