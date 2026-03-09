//
//  CTUtilsTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 15/02/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTUtils.h"
#import "NSDictionary+Extensions.h"

@interface CTUtilsTest : XCTestCase

@end

@implementation CTUtilsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_dictionaryToJsonString_withEmptyDictionary {
    NSDictionary *emptyDict = @{};
    NSString *jsonString = [emptyDict toJsonString];
    
    XCTAssertNotNil(jsonString, @"Empty dictionary should return a non-nil JSON string");
    XCTAssertEqualObjects(jsonString, @"{}", @"Empty dictionary should produce empty JSON object");
}

- (void)test_dictionaryToJsonString{
    NSDictionary *dict = @{@"key1":@"value1"};
    NSString *jsonString = [dict toJsonString];
    
    XCTAssertEqualObjects(jsonString, @"{\"key1\":\"value1\"}", @"JSON convertion should match given dictionary");
}

- (void)test_urlEncodeString_withEmptyString{
    NSString *urlString = [CTUtils urlEncodeString:@""];

    XCTAssertNotNil(urlString, @"Empty string should return non nil encoded url string");
    XCTAssertEqualObjects(@"", urlString, @"Empty string should return empty encoded url string");
}

- (void)test_urlEncodeString_withNilString{
    NSString *urlString = [CTUtils urlEncodeString:nil];
    XCTAssertNil(urlString, @"Nil string should return nil");
}

- (void)test_urlEncodeString{
    NSString *urlString = [CTUtils urlEncodeString:@"CT testing 2023"];

    XCTAssertNotNil(urlString, @"A String should return non nil encoded url string");
    XCTAssertEqualObjects(@"CT+testing+2023", urlString, @"String should return encoded url string");
}

- (void)test_doesStringStartWithPrefix_withCorrectPrefix{
    NSString *inputString = @"CleverTap";
    NSString *prefix = @"Cle";
    
    BOOL result = [CTUtils doesString:inputString startWith:prefix];
    XCTAssertTrue(result);
}

- (void)test_doesStringStartWithPrefix_withWrongPrefix{
    NSString *inputString = @"CleverTap";
    NSString *prefix = @"cle";
    
    BOOL result = [CTUtils doesString:inputString startWith:prefix];
    XCTAssertFalse(result);
}

- (void)test_doesStringStartWithPrefix_withPrefixLenghtGreaterThanInputString{
    NSString *inputString = @"CleverTap";
    NSString *prefix = @"CleverTap--";
    
    BOOL result = [CTUtils doesString:inputString startWith:prefix];
    XCTAssertFalse(result);
}

- (void)test_deviceTokenStringFromData{
    NSData *data = [NSData dataWithBytes:"dummy token" length:11];
    NSString *tokenString = [CTUtils deviceTokenStringFromData:data];
    
    XCTAssertNotNil(tokenString);
}

- (void)test_toTwoPlaces{
    double result = [CTUtils toTwoPlaces:10.2];
    
    XCTAssertEqual(result, 10.199999999999999);
}

- (void)test_deviceTokenStringFromNilData {
    NSString *tokenString = [CTUtils deviceTokenStringFromData:nil];
    XCTAssertNil(tokenString);
}

- (void)test_deviceTokenStringFromEmptyData {
    NSData *data = [NSData data];
    NSString *tokenString = [CTUtils deviceTokenStringFromData:data];
    
    XCTAssertNil(tokenString);
}

- (void)test_haversineDistance {
    NSString* (^decimalPoints)(double) = ^(double number) {
        return [NSString stringWithFormat:@"%.02f", number];
    };
    
    CLLocationCoordinate2D nebraska = CLLocationCoordinate2DMake(41.507483, -99.436554);
    CLLocationCoordinate2D kansas = CLLocationCoordinate2DMake(38.504048, -98.315949);
    
    double distanceNK = [CTUtils haversineDistance:nebraska coordinateB:kansas];
    double expectedDistanceNK = 347.72;
    XCTAssertEqualObjects(decimalPoints(distanceNK), decimalPoints(expectedDistanceNK));

    CLLocationCoordinate2D mumbai = CLLocationCoordinate2DMake(19.07609, 72.877426);
    CLLocationCoordinate2D sofia = CLLocationCoordinate2DMake(42.698334, 23.319941);
    
    double distanceMS = [CTUtils haversineDistance:mumbai coordinateB:sofia];
    double expectedDistanceMS = 5317.06;
    XCTAssertEqualObjects(decimalPoints(distanceMS), decimalPoints(expectedDistanceMS));
    
    XCTAssertEqual([CTUtils haversineDistance:nebraska coordinateB:nebraska], 0);
}

- (void)test_numberFromString {
    XCTAssertNil([CTUtils numberFromString:@"asd"]);
    
    XCTAssertNil([CTUtils numberFromString:@"123asd"]);
    
    XCTAssertNil([CTUtils numberFromString:@"12.3.asd"]);
    
    XCTAssertNil([CTUtils numberFromString:@"asd10"]);
    
    XCTAssertEqualObjects([CTUtils numberFromString:@" 5 "], @(5));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"5 "], @(5));
    
    XCTAssertNil([CTUtils numberFromString:@"12,3"]);
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"010"], @(10));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"0.10"], @(0.10));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@".10"], @(0.10));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"010.10"], @(10.10));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"-0"], @(0));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"-06"], @(-6));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"12.3"], @(12.3));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"-12.3"], @(-12.3));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"10"], @(10));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"-10"], @(-10));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"0"], @(0));
    
    XCTAssertEqualObjects([CTUtils numberFromString:@"0.0"], @(0.0));
}

- (void)test_numberFromStringWithLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"bg_BG"];
    XCTAssertEqualObjects([CTUtils numberFromString:@"12,3" withLocale:locale], @(12.3));
    
    XCTAssertNil([CTUtils numberFromString:@"12.3" withLocale:locale]);
}

- (void)testGetNormalizedName {
    XCTAssertNil([CTUtils getNormalizedName:nil]);
    XCTAssertEqualObjects(@"", [CTUtils getNormalizedName:@""]);
    XCTAssertEqualObjects(@"event1", [CTUtils getNormalizedName:@"Event 1"]);
    XCTAssertEqualObjects(@"event1", [CTUtils getNormalizedName:@"EVENT   1"]);
    XCTAssertEqualObjects(@"event1", [CTUtils getNormalizedName:@"event1"]);
}

- (void)testAreEqualNormalizedNames {
    XCTAssertTrue([CTUtils areEqualNormalizedName:nil andName:nil]);
    XCTAssertTrue([CTUtils areEqualNormalizedName:@"" andName:@""]);
    XCTAssertTrue([CTUtils areEqualNormalizedName:@"Event 1" andName:@"Event1"]);
    XCTAssertTrue([CTUtils areEqualNormalizedName:@"Event 1" andName:@"event1"]);
    XCTAssertTrue([CTUtils areEqualNormalizedName:@"Event 1" andName:@"EVENT    1"]);
    XCTAssertFalse([CTUtils areEqualNormalizedName:@"" andName:nil]);
    XCTAssertFalse([CTUtils areEqualNormalizedName:@"Event 1" andName:nil]);
    XCTAssertFalse([CTUtils areEqualNormalizedName:@"Event 1" andName:@"Event 2"]);
}

#pragma mark - isNullOrEmpty

- (void)test_isNullOrEmpty_nil_returnsYes {
    XCTAssertTrue([CTUtils isNullOrEmpty:nil]);
}

- (void)test_isNullOrEmpty_emptyString_returnsYes {
    XCTAssertTrue([CTUtils isNullOrEmpty:@""]);
}

- (void)test_isNullOrEmpty_emptyArray_returnsYes {
    XCTAssertTrue([CTUtils isNullOrEmpty:@[]]);
}

- (void)test_isNullOrEmpty_emptyDict_returnsYes {
    XCTAssertTrue([CTUtils isNullOrEmpty:@{}]);
}

- (void)test_isNullOrEmpty_nonEmptyString_returnsNo {
    XCTAssertFalse([CTUtils isNullOrEmpty:@"hello"]);
}

- (void)test_isNullOrEmpty_nonEmptyArray_returnsNo {
    XCTAssertFalse([CTUtils isNullOrEmpty:@[@1]]);
}

#pragma mark - jsonObjectToString

- (void)test_jsonObjectToString_stringInput_returnsStringPassthrough {
    NSString *result = [CTUtils jsonObjectToString:@"hello"];
    XCTAssertEqualObjects(result, @"hello");
}

- (void)test_jsonObjectToString_dictInput_returnsJsonString {
    NSString *result = [CTUtils jsonObjectToString:@{@"k": @"v"}];
    XCTAssertNotNil(result);
    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *roundTripped = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    XCTAssertEqualObjects(roundTripped[@"k"], @"v");
}

- (void)test_jsonObjectToString_arrayInput_returnsJsonString {
    NSString *result = [CTUtils jsonObjectToString:@[@1, @2]];
    XCTAssertNotNil(result);
    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *roundTripped = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    XCTAssertEqualObjects(roundTripped, (@[@1, @2]));
}

#pragma mark - isValidCleverTapId

- (void)test_isValidCleverTapId_validAlphanumeric_returnsYes {
    XCTAssertTrue([CTUtils isValidCleverTapId:@"User_123"]);
}

- (void)test_isValidCleverTapId_allowedSpecialChars_returnsYes {
    XCTAssertTrue([CTUtils isValidCleverTapId:@"user@domain.com"]);
    XCTAssertTrue([CTUtils isValidCleverTapId:@"id-123_abc"]);
}

- (void)test_isValidCleverTapId_nil_returnsNo {
    XCTAssertFalse([CTUtils isValidCleverTapId:nil]);
}

- (void)test_isValidCleverTapId_empty_returnsNo {
    XCTAssertFalse([CTUtils isValidCleverTapId:@""]);
}

- (void)test_isValidCleverTapId_tooLong_returnsNo {
    NSString *longId = [@"" stringByPaddingToLength:65 withString:@"a" startingAtIndex:0];
    XCTAssertFalse([CTUtils isValidCleverTapId:longId]);
}

- (void)test_isValidCleverTapId_invalidSpecialChars_returnsNo {
    XCTAssertFalse([CTUtils isValidCleverTapId:@"bad#id"]);
    XCTAssertFalse([CTUtils isValidCleverTapId:@"bad&id"]);
}

#pragma mark - getKeyWithSuffix

- (void)test_getKeyWithSuffix_returnsFormattedKey {
    NSString *result = [CTUtils getKeyWithSuffix:@"prefs" accountID:@"abc123"];
    XCTAssertEqualObjects(result, @"abc123:prefs");
}

#pragma mark - runSyncMainQueue:

- (void)test_runSyncMainQueue_calledFromMainThread_executesBlock {
    __block BOOL executed = NO;
    [CTUtils runSyncMainQueue:^{ executed = YES; }];
    XCTAssertTrue(executed);
}

- (void)test_runSyncMainQueue_calledFromBackgroundThread_executesBlockOnMain {
    XCTestExpectation *exp = [self expectationWithDescription:@"sync main queue"];
    __block BOOL onMain = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [CTUtils runSyncMainQueue:^{
            onMain = [NSThread isMainThread];
        }];
        XCTAssertTrue(onMain);
        [exp fulfill];
    });
    [self waitForExpectations:@[exp] timeout:1.0];
}

#pragma mark - runAsyncMainQueue:

- (void)test_runAsyncMainQueue_executesBlockOnMainThread {
    XCTestExpectation *exp = [self expectationWithDescription:@"async main queue"];
    __block BOOL onMain = NO;
    [CTUtils runAsyncMainQueue:^{
        onMain = [NSThread isMainThread];
        [exp fulfill];
    }];
    [self waitForExpectations:@[exp] timeout:1.0];
    XCTAssertTrue(onMain);
}

@end
