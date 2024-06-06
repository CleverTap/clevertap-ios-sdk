//
//  CTCustomTemplateBuilderTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 7.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTCustomTemplatesManager.h"
#import "CTInAppTemplateBuilder.h"
#import "CTAppFunctionBuilder.h"
#import "CTCustomTemplate-Internal.h"
#import "CTTemplatePresenterMock.h"

@interface CTCustomTemplateBuilderTest : XCTestCase

@end

@implementation CTCustomTemplateBuilderTest

- (void)testNameNotSetThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    XCTAssertThrows([templateBuilder build]);
    
    CTAppFunctionBuilder *functionBuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO];
    XCTAssertThrows([functionBuilder build]);
}

- (void)testEmptyNameSetThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    XCTAssertThrows([templateBuilder setName:@""]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([templateBuilder setName:nil]);
#pragma clang diagnostic pop
}

- (void)testNameAlreadySetThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder setName:@"template"];
    XCTAssertThrows([templateBuilder setName:@"template"]);
}

- (void)testInvalidArgumentNameThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    XCTAssertThrows([templateBuilder addArgument:@"" withString:@"string"]);
    XCTAssertThrows([templateBuilder addArgument:@".start" withString:@"string"]);
    XCTAssertThrows([templateBuilder addArgument:@"end." withString:@"string"]);
    XCTAssertThrows([templateBuilder addArgument:@"two.." withString:@"string"]);
}

- (void)testValidArgumentName {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    XCTAssertNoThrow([templateBuilder addArgument:@"name" withString:@"string"]);
    XCTAssertNoThrow([templateBuilder addArgument:@"arg name" withString:@"string"]);
    XCTAssertNoThrow([templateBuilder addArgument:@"valid.name" withString:@"string"]);
    XCTAssertNoThrow([templateBuilder addArgument:@"valid.two.name" withString:@"string"]);
}

- (void)testInvalidArgumentValueDictionaryThrows {
    CTAppFunctionBuilder *functionBuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
    XCTAssertThrows([functionBuilder addArgument:@"invalid type" withString:[NSDictionary dictionary]]);
#pragma clang diagnostic pop
}

- (void)testArgumentEmptyDictionaryThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    XCTAssertThrows([templateBuilder addArgument:@"dictionary" withDictionary:@{}]);
    XCTAssertNoThrow([templateBuilder addArgument:@"dictionary" withDictionary:@{ @"a": @(0) }]);
}

- (void)testArgumentSameNameThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder addArgument:@"arg" withString:@"value"];
    XCTAssertThrows([templateBuilder addArgument:@"arg" withString:@"value"]);
    XCTAssertThrows([templateBuilder addArgument:@"arg" withNumber:@(2)]);
    XCTAssertThrows([templateBuilder addArgument:@"arg" withBool:YES]);
    XCTAssertThrows([templateBuilder addFileArgument:@"arg"]);
    XCTAssertThrows([templateBuilder addActionArgument:@"arg"]);
    XCTAssertThrows([templateBuilder addArgument:@"arg" withDictionary:@{ @"a": @(0) }]);
}

- (void)testArgumentDictionaryName {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder addArgument:@"arg" withDictionary:@{ @"a": @(0) }];
    [templateBuilder addArgument:@"arg" withDictionary:@{ @"b": @(0) }];
    XCTAssertThrows([templateBuilder addArgument:@"arg" withDictionary:@{ @"a": @(0) }]);
}

- (void)testNoPresenterThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder setName:@"template"];
    XCTAssertThrows([templateBuilder build]);
}

- (void)testParentArgsAlreadyDefinedThrows {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder addArgument:@"a.b" withString:@""];
    XCTAssertThrows([templateBuilder addArgument:@"a" withString:@""]);
    XCTAssertThrows([templateBuilder addArgument:@"a.b" withString:@""]);
    
    templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder addArgument:@"a.b.c.d" withString:@""];
    XCTAssertThrows([templateBuilder addArgument:@"a" withString:@""]);
    XCTAssertThrows([templateBuilder addArgument:@"a.b" withString:@""]);
    XCTAssertThrows([templateBuilder addArgument:@"a.b.c" withString:@""]);
    [templateBuilder addArgument:@"a.b.c.e" withString:@""];
    
    
    templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder addArgument:@"a.a.a" withString:@""];
    [templateBuilder addArgument:@"a.a.b" withString:@""];
    XCTAssertThrows([templateBuilder addArgument:@"a.a.a.d" withString:@""]);
    XCTAssertThrows([templateBuilder addArgument:@"a" withString:@""]);
    XCTAssertThrows([templateBuilder addArgument:@"a.a" withString:@""]);
    
    templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder addArgument:@"a.a.a" withString:@""];
    [templateBuilder addArgument:@"a.a.b" withString:@""];
    XCTAssertThrows([templateBuilder addArgument:@"a.a.a.d" withString:@""]);
    XCTAssertThrows([templateBuilder addArgument:@"a" withString:@""]);
    XCTAssertThrows([templateBuilder addArgument:@"a.a" withString:@""]);
    [templateBuilder addArgument:@"a.a.c" withString:@""];
}

- (void)testArgumentValue {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder addArgument:@"a" withString:@""];
    [templateBuilder addArgument:@"b" withBool:nil];
    [templateBuilder addFileArgument:@"c"];
    [templateBuilder addActionArgument:@"d"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([templateBuilder addArgument:@"e" withString:nil]);
    XCTAssertThrows([templateBuilder addArgument:@"f" withString:[NSNull null]]);
    XCTAssertThrows([templateBuilder addArgument:@"g" withNumber:nil]);
    XCTAssertThrows([templateBuilder addArgument:@"h" withDictionary:nil]);
#pragma clang diagnostic pop
}

- (void)testArgumentOrder {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder setName:@"template"];
    [templateBuilder setPresenter:[CTTemplatePresenterMock new]];
    [templateBuilder addArgument:@"a" withString:@""];
    [templateBuilder addArgument:@"b" withBool:YES];
    [templateBuilder addFileArgument:@"c"];
    [templateBuilder addActionArgument:@"d"];
    
    CTCustomTemplate *template = [templateBuilder build];
    XCTAssertEqualObjects(template.arguments[0].name, @"a");
    XCTAssertEqualObjects(template.arguments[1].name, @"b");
    XCTAssertEqualObjects(template.arguments[2].name, @"c");
    XCTAssertEqualObjects(template.arguments[3].name, @"d");
}

- (void)testFlatDictionaryArgument {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder setName:@"template"];
    [templateBuilder setPresenter:[CTTemplatePresenterMock new]];
    [templateBuilder addArgument:@"e" withDictionary:@{
        @"g": @"value",
        @"h": @1,
        @"f": @{
            @"c": @10,
            @"e": @"",
            @"d": @99
        }
    }];
    
    CTCustomTemplate *template = [templateBuilder build];
    NSSet *expected = [[NSSet alloc] initWithArray: @[
        [[CTTemplateArgument alloc] initWithName:@"e.h" type:CTTemplateArgumentTypeNumber defaultValue:@1],
        [[CTTemplateArgument alloc] initWithName:@"e.g" type:CTTemplateArgumentTypeString defaultValue:@"value"],
        [[CTTemplateArgument alloc] initWithName:@"e.f.c" type:CTTemplateArgumentTypeNumber defaultValue:@10],
        [[CTTemplateArgument alloc] initWithName:@"e.f.e" type:CTTemplateArgumentTypeString defaultValue:@""],
        [[CTTemplateArgument alloc] initWithName:@"e.f.d" type:CTTemplateArgumentTypeNumber defaultValue:@99]
    ]];
    XCTAssertEqualObjects([[NSSet alloc] initWithArray:template.arguments], expected);
}

- (void)testArguments {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder setName:@"template"];
    [templateBuilder setPresenter:[CTTemplatePresenterMock new]];
    [templateBuilder addArgument:@"string" withString:@"string value"];
    [templateBuilder addArgument:@"string 2" withString:@"string value 2"];
    [templateBuilder addArgument:@"bool" withBool:YES];
    [templateBuilder addArgument:@"number" withNumber:@(9999.99999999999)];
    [templateBuilder addArgument:@"int" withNumber:[NSNumber numberWithInteger:12345]];
    [templateBuilder addArgument:@"float" withNumber:[NSNumber numberWithFloat:1.99]];
    [templateBuilder addFileArgument:@"file"];
    [templateBuilder addActionArgument:@"action"];
    
    CTCustomTemplate *template = [templateBuilder build];
    NSSet *expected = [[NSSet alloc] initWithArray: @[
        [[CTTemplateArgument alloc] initWithName:@"string" type:CTTemplateArgumentTypeString defaultValue:@"string value"],
        [[CTTemplateArgument alloc] initWithName:@"string 2" type:CTTemplateArgumentTypeString defaultValue:@"string value 2"],
        [[CTTemplateArgument alloc] initWithName:@"bool" type:CTTemplateArgumentTypeBool defaultValue:@(YES)],
        [[CTTemplateArgument alloc] initWithName:@"number" type:CTTemplateArgumentTypeNumber defaultValue:@(9999.99999999999)],
        [[CTTemplateArgument alloc] initWithName:@"int" type:CTTemplateArgumentTypeNumber defaultValue:@(12345)],
        [[CTTemplateArgument alloc] initWithName:@"float" type:CTTemplateArgumentTypeNumber defaultValue:@(1.99f)],
        [[CTTemplateArgument alloc] initWithName:@"file" type:CTTemplateArgumentTypeFile defaultValue:nil],
        [[CTTemplateArgument alloc] initWithName:@"action" type:CTTemplateArgumentTypeAction defaultValue:nil],
    ]];
    XCTAssertEqualObjects([[NSSet alloc] initWithArray:template.arguments], expected);
}

- (void)testFunctionArgumentDictionary {
    CTAppFunctionBuilder *functionBuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO];
    [functionBuilder addArgument:@"arg" withDictionary:@{ @"a": @"value" }];
    [functionBuilder setName:@"function"];
    [functionBuilder setPresenter:[CTTemplatePresenterMock new]];
    CTCustomTemplate *template = [functionBuilder build];
    CTTemplateArgument *arg = [[CTTemplateArgument alloc] initWithName:@"arg.a" type:CTTemplateArgumentTypeString defaultValue:@"value"];
    XCTAssertEqualObjects(arg, template.arguments.firstObject);
}

@end
