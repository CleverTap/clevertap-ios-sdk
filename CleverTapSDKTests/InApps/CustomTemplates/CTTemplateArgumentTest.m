//
//  CTTemplateArgumentTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 10.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTTemplateArgument.h"

@interface CTTemplateArgumentTest : XCTestCase

@end

@implementation CTTemplateArgumentTest

- (void)testInit {
    NSString *name = @"testName";
    id defaultValue = @(42);
    CTTemplateArgument *argument = [[CTTemplateArgument alloc] initWithName:name type:CTTemplateArgumentTypeNumber defaultValue:defaultValue];
    
    XCTAssertEqualObjects(argument.name, name);
    XCTAssertEqual(argument.type, CTTemplateArgumentTypeNumber);
    XCTAssertEqualObjects(argument.defaultValue, defaultValue);
}

- (void)testEquals {
    CTTemplateArgument *argument1 = [[CTTemplateArgument alloc] initWithName:@"testName" type:CTTemplateArgumentTypeNumber defaultValue:@(42)];
    CTTemplateArgument *argument2 = [[CTTemplateArgument alloc] initWithName:@"testName" type:CTTemplateArgumentTypeNumber defaultValue:@(42)];
    CTTemplateArgument *argument3 = [[CTTemplateArgument alloc] initWithName:@"otherName" type:CTTemplateArgumentTypeNumber defaultValue:@(42)];
    CTTemplateArgument *argument4 = [[CTTemplateArgument alloc] initWithName:@"testName" type:CTTemplateArgumentTypeString defaultValue:@"test"];
    
    XCTAssertEqualObjects(argument1, argument2);
    XCTAssertNotEqualObjects(argument1, argument3);
    XCTAssertNotEqualObjects(argument1, argument4);
}

- (void)testHash {
    CTTemplateArgument *argument1 = [[CTTemplateArgument alloc] initWithName:@"testName" type:CTTemplateArgumentTypeNumber defaultValue:@(42)];
    CTTemplateArgument *argument2 = [[CTTemplateArgument alloc] initWithName:@"testName" type:CTTemplateArgumentTypeNumber defaultValue:@(42)];
    CTTemplateArgument *argument3 = [[CTTemplateArgument alloc] initWithName:@"otherName" type:CTTemplateArgumentTypeString defaultValue:@"test"];
    
    XCTAssertEqual(argument1.hash, argument2.hash);
    XCTAssertNotEqual(argument1.hash, argument3.hash);
}

- (void)testDescription {
    CTTemplateArgument *argument = [[CTTemplateArgument alloc] initWithName:@"testName" type:CTTemplateArgumentTypeNumber defaultValue:@(42)];
    NSString *description = [argument description];
    
    XCTAssertTrue([description containsString:@"testName"]);
    XCTAssertTrue([description containsString:@"number"]);
    XCTAssertTrue([description containsString:@"42"]);
}

@end
