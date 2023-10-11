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

@end
