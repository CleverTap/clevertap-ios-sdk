//
//  CTPreferencesTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 27/04/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTPreferences.h"
#import "XCTestCase+XCTestCase_Tests.h"

@interface CTPreferencesTest : XCTestCase

@end

@implementation CTPreferencesTest

- (void)setUp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(2333333333333333333) forKey:@"WizRocketlongValueForTesting"];
}

- (void)tearDown {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"WizRocketlongValueForTesting"];
}

- (void)test_getIntForKey_withValidKey {
    long longValue = [CTPreferences getIntForKey:@"longValueForTesting" withResetValue:55555888888];
    
    XCTAssertEqual(longValue, 2333333333333333333);
}

-(void)test_getIntForKey_withInvalidKey {
    long longValue = [CTPreferences getIntForKey:@"invalidTestKey" withResetValue:55555888888];
    
    XCTAssertEqual(longValue, 55555888888);
}

-(void)test_putInt_withValidKey {
    [CTPreferences putInt:898989898989 forKey:@"putKeyTest"];
    long checkValue = [[CTPreferences getObjectForKey:@"putKeyTest"] longLongValue];
    XCTAssertEqual(checkValue, 898989898989);
}

-(void)test_putInt_withInvalidKey {
    [CTPreferences putInt:898989898989 forKey:@"putKeyTest"];
    long checkValue = [[CTPreferences getObjectForKey:@"putInvalidKeyTest"] longLongValue];
    XCTAssertEqual(checkValue, 0);
}

- (void)test_getStringForKey_withValidKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"stringValueForTesting" forKey:@"WizRocketstringValueForTesting"];
    
    NSString *stringValue = [CTPreferences getStringForKey:@"stringValueForTesting" withResetValue:@"testResetStringValue"];
    
    XCTAssertEqualObjects(stringValue, @"stringValueForTesting");
}

- (void)test_getStringForKey_withInvalidKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"stringValueForTesting" forKey:@"WizRocketstringValueForTesting"];
    
    NSString *stringValue = [CTPreferences getStringForKey:@"invalidTestKey" withResetValue:@"testResetStringValue"];
    
    XCTAssertEqual(stringValue, @"testResetStringValue");
}

-(void)test_putString_withValidKey {
    [CTPreferences putString:@"putStringValue" forKey:@"putKeyTest"];
    NSString *checkValue = [CTPreferences getObjectForKey:@"putKeyTest"];
    
    XCTAssertEqualObjects(checkValue, @"putStringValue");
}

-(void)test_putString_withInvalidKey {
    [CTPreferences putString:@"putStringValue" forKey:@"putKeyTest"];
    NSString *checkValue = [CTPreferences getObjectForKey:@"putKeyInvalidTest"];
    
    XCTAssertNil(checkValue);
}

- (void)test_getObjectForKey_withValidKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"stringValueForTesting" forKey:@"WizRocketstringValueForTesting"];

    id idValue = [CTPreferences getObjectForKey:@"stringValueForTesting"];
    
    XCTAssertEqualObjects(idValue, @"stringValueForTesting");
}

- (void)test_getObjectForKey_withInvalidKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"stringValueForTesting" forKey:@"WizRocketstringValueForTesting"];

    id idValue = [CTPreferences getObjectForKey:@"invalidTestStringKey"];
    
    XCTAssertNil(idValue);
}

-(void)test_putObject_withValidKey {
    [CTPreferences putObject:@88 forKey:@"putObjectValidKeyTest"];
    id checkValue = [CTPreferences getObjectForKey:@"putObjectValidKeyTest"];
    XCTAssertEqualObjects(checkValue, @88);
}

-(void)test_putObject_withInvalidKey {
    id checkValue = [CTPreferences getObjectForKey:[self randomString]];
    XCTAssertNil(checkValue);
}

-(void)test_removeObjectForKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"objectValueForTesting" forKey:@"WizRocketobjectValueForTesting"];

    [CTPreferences removeObjectForKey:@"objectValueForTesting"];
    
    id checkValue = [CTPreferences getObjectForKey:@"WizRocketobjectValueForTesting"];
    
    XCTAssertNil(checkValue);
}
@end
