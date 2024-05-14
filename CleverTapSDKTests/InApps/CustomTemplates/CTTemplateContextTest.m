//
//  CTTemplateContextTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 13.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTTemplateContext-Internal.h"
#import "CTInAppTemplateBuilder.h"
#import "CTAppFunctionBuilder.h"
#import "CTTemplatePresenterMock.h"
#import "CTTemplateContext-Internal.h"

@interface CTTemplateContextTest : XCTestCase

@end

@implementation CTTemplateContextTest

- (void)testSimpleValueOverrides {
    CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:self.simpleTemplateNotificationJson];
    CTTemplateContext *context = [[CTTemplateContext alloc] initWithTemplate:self.simpleTemplate andNotification:notification];
    XCTAssertEqual(VARS_OVERRIDE_BOOLEAN, [context boolNamed:@"a.b.c"]);
    XCTAssertEqualObjects(VARS_OVERRIDE_STRING, [context stringNamed:@"a.b.d"]);
    XCTAssertEqualObjects(@(VARS_OVERRIDE_LONG), [context numberNamed:@"a.b.e.f"]);
    XCTAssertEqual(VARS_OVERRIDE_DOUBLE, [context doubleNamed:@"g"]);
    XCTAssertEqual(VARS_OVERRIDE_BOOLEAN, [context boolNamed:@"h"]);
    XCTAssertEqualObjects(VARS_DEFAULT_STRING, [context stringNamed:@"i"]);
    
    NSDictionary *a = [context dictionaryNamed:@"a"];
    XCTAssertTrue([a isEqualToDictionary:(@{
        @"b": @{
            @"c": @(VARS_OVERRIDE_BOOLEAN),
            @"d": VARS_OVERRIDE_STRING,
            @"e": @{
                @"f": @(VARS_OVERRIDE_LONG)
            }
        }
    })]);
    
    NSDictionary *ab = [context dictionaryNamed:@"a.b"];
    XCTAssertTrue([ab isEqualToDictionary:(@{
        @"c": @(VARS_OVERRIDE_BOOLEAN),
        @"d": VARS_OVERRIDE_STRING,
        @"e": @{
            @"f": @(VARS_OVERRIDE_LONG)
        }
    })]);
    
    NSDictionary *abe = [context dictionaryNamed:@"a.b.e"];
    XCTAssertTrue([abe isEqualToDictionary:(@{
        @"f": @(VARS_OVERRIDE_LONG)
    })]);
    
    NSDictionary *abg = [context dictionaryNamed:@"a.b.g"];
    XCTAssertNil(abg);
}

- (void)testValueOverrides {
    XCTAssertEqual(VARS_OVERRIDE_BOOLEAN, [self.templateContext boolNamed:@"boolean"]);
    XCTAssertEqual(VARS_OVERRIDE_STRING, [self.templateContext stringNamed:@"string"]);
    XCTAssertEqual(VARS_OVERRIDE_CHAR, [self.templateContext charNamed:@"char"]);
    XCTAssertEqual(VARS_OVERRIDE_LONG, [self.templateContext longNamed:@"long"]);
    XCTAssertEqual(VARS_OVERRIDE_DOUBLE, [self.templateContext doubleNamed:@"double"]);
    XCTAssertEqualObjects(@(VARS_DEFAULT_INT), [self.templateContext numberNamed:@"noOverrideInt"]);
    XCTAssertFalse([self.templateContext boolNamed:@"overrideWithoutDefinitionBoolean"]);
    XCTAssertNil([self.templateContext numberNamed:@"nonDefinedNumber"]);
}

- (void)testNotDefinedValues {
    XCTAssertFalse([self.templateContext boolNamed:@"overrideWithoutDefinitionBoolean"]);
    XCTAssertNil([self.templateContext stringNamed:@"notDefinedString"]);
    XCTAssertNil([self.templateContext numberNamed:@"notDefinedNumber"]);
    XCTAssertNil([self.templateContext dictionaryNamed:@"notDefinedMap"]);
    XCTAssertEqual(0, [self.templateContext longNamed:@"notDefinedLong"]);
    XCTAssertEqual(0, [self.templateContext charNamed:@"notDefinedChar"]);
    XCTAssertEqual(0, [self.templateContext intNamed:@"notDefinedInt"]);
    XCTAssertEqual(0, [self.templateContext doubleNamed:@"notDefinedDouble"]);
    XCTAssertEqual(0, [self.templateContext floatNamed:@"notDefinedFloat"]);
}

- (void)testDictionaryArguments {
    NSDictionary *notificationVars = self.templateNotificationJson[@"vars"];
    
    NSDictionary *map = [self.templateContext dictionaryNamed:@"map"];
    XCTAssertEqualObjects(notificationVars[@"map.int"], map[@"int"]);
    XCTAssertEqualObjects(notificationVars[@"map.float"], map[@"float"]);
    XCTAssertEqualObjects(@25, map[@"noOverrideInt"]);
    
    NSDictionary *innerMap = map[@"innerMap"];
    [self verifyInnerMap:notificationVars map:innerMap];
    XCTAssertTrue([innerMap isEqualToDictionary:[self.templateContext dictionaryNamed:@"map.innerMap"]]);
    
    NSDictionary *innermostMap = innerMap[@"innermostMap"];
    [self verifyInnermostMap:notificationVars map:innermostMap];
    XCTAssertTrue([innermostMap isEqualToDictionary:[self.templateContext dictionaryNamed:@"map.innerMap.innermostMap"]]);
}

- (void)testActionsValueInDictionary {
    NSDictionary *actionsMap = [self.templateContext dictionaryNamed:@"map.actions"];
    XCTAssertEqualObjects(VARS_ACTION_FUNCTION_NAME, actionsMap[@"function"]);
    XCTAssertEqualObjects(@"close", actionsMap[@"close"]);
}

- (void)verifyInnerMap:(NSDictionary *)vars map:(NSDictionary *)map {
    XCTAssertEqualObjects(vars[@"map.innerMap.boolean"], map[@"boolean"]);
    XCTAssertEqualObjects(vars[@"map.innerMap.string"], map[@"string"]);
    XCTAssertEqualObjects(vars[@"map.innerMap.char"], map[@"char"]);
    XCTAssertEqualObjects(vars[@"map.innerMap.int"], map[@"int"]);
    XCTAssertEqualObjects(vars[@"map.innerMap.long"], map[@"long"]);
    XCTAssertEqualObjects(vars[@"map.innerMap.double"], map[@"double"]);
    XCTAssertEqualObjects(@15, map[@"noOverrideInt"]);
}

- (void)verifyInnermostMap:(NSDictionary *)vars map:(NSDictionary *)map {
    XCTAssertEqualObjects(vars[@"map.innerMap.innermostMap.int"], map[@"int"]);
    XCTAssertEqualObjects(vars[@"map.innerMap.innermostMap.string"], map[@"string"]);
    XCTAssertEqualObjects(vars[@"map.innerMap.innermostMap.boolean"], map[@"boolean"]);
    XCTAssertEqualObjects(@YES, map[@"noOverrideBoolean"]);
}

- (CTCustomTemplate *)simpleTemplate {
    CTInAppTemplateBuilder *builder = [[CTInAppTemplateBuilder alloc] init];
    [builder setName:TEMPLATE_NAME];
    [builder addArgument:@"a.b.c" withBool:VARS_DEFAULT_BOOLEAN];
    [builder addArgument:@"a.b.d" withString:VARS_DEFAULT_STRING];
    [builder addArgument:@"a.b.e.f" withNumber:@(VARS_DEFAULT_LONG)];
    [builder addArgument:@"g" withNumber:@(VARS_DEFAULT_DOUBLE)];
    [builder addArgument:@"h" withBool:VARS_DEFAULT_BOOLEAN];
    [builder addArgument:@"i" withString:VARS_DEFAULT_STRING];
    [builder setPresenter:[CTTemplatePresenterMock new]];
    return [builder build];
}

- (NSDictionary *)simpleTemplateNotificationJson {
    return @{
        @"templateName": TEMPLATE_NAME,
        @"type": @"custom-code",
        @"vars": @{
            @"a.b.c": @(VARS_OVERRIDE_BOOLEAN),
            @"a.b.d": VARS_OVERRIDE_STRING,
            @"a.b.e.f": @(VARS_OVERRIDE_LONG),
            @"g": @(VARS_OVERRIDE_DOUBLE),
            @"h": @YES
        }
    };
}

- (CTTemplateContext *)templateContext {
    CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:self.templateNotificationJson];
    return [[CTTemplateContext alloc] initWithTemplate:self.template andNotification:notification];
}

- (CTCustomTemplate *)template {
    CTInAppTemplateBuilder *templateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [templateBuilder setName:TEMPLATE_NAME_NESTED];
    [templateBuilder addArgument:@"boolean" withBool:NO];
    [templateBuilder addArgument:@"char" withNumber:[NSNumber numberWithChar:VARS_DEFAULT_CHAR]];
    [templateBuilder addArgument:@"string" withString:VARS_DEFAULT_STRING];
    [templateBuilder addArgument:@"long" withNumber:[NSNumber numberWithLong:VARS_DEFAULT_LONG]];
    [templateBuilder addArgument:@"double" withNumber:@(VARS_DEFAULT_DOUBLE)];
    [templateBuilder addArgument:@"map.int" withNumber:@(VARS_DEFAULT_INT)];
    [templateBuilder addArgument:@"noOverrideInt" withNumber:@(VARS_DEFAULT_INT)];
    [templateBuilder addArgument:@"map.noOverrideInt" withNumber:@25];
    [templateBuilder addArgument:@"map" withDictionary:@{
        @"float": @15.6f,
        @"innerMap": @{
            @"boolean": @NO,
            @"string": @"Default",
            @"noOverrideInt": @15
        }
    }];
    [templateBuilder addArgument:@"map.innerMap" withDictionary:@{
        @"char": @10,
        @"int": @1100,
        @"long": @21474836472,
        @"innermostMap": @{
            @"int": @1200,
            @"string": @"Default",
            @"boolean": @NO,
            @"noOverrideBoolean": @YES
        }
    }];
    [templateBuilder addArgument:@"map.innerMap.double" withNumber:@12.12];
    [templateBuilder addActionArgument:@"map.actions.function"];
    [templateBuilder addActionArgument:@"map.actions.close"];
    [templateBuilder addActionArgument:@"map.actions.openUrl"];
    [templateBuilder setPresenter:[CTTemplatePresenterMock new]];
    return [templateBuilder build];
}

- (NSDictionary *)templateNotificationJson {
    return @{
        @"templateName": TEMPLATE_NAME_NESTED,
        @"type": @"custom-code",
        @"vars": @{
            @"boolean": @(VARS_OVERRIDE_BOOLEAN),
            @"string": VARS_OVERRIDE_STRING,
            @"char": @(VARS_OVERRIDE_CHAR),
            @"long": @(VARS_OVERRIDE_LONG),
            @"double": @(VARS_OVERRIDE_DOUBLE),
            @"overrideWithoutDefinitionBoolean": @YES,
            @"map.actions.close": @{
                @"actions": @{
                    @"type": @"close"
                }
            },
            @"map.actions.function": @{
                @"actions": @{
                    @"templateName": VARS_ACTION_FUNCTION_NAME,
                    @"type": @"custom-code",
                    @"vars": @{
                        @"boolean": @(VARS_ACTION_OVERRIDE_BOOLEAN),
                        @"string": VARS_ACTION_OVERRIDE_STRING,
                        @"int": @(VARS_ACTION_OVERRIDE_INT)
                    }
                }
            },
            @"map.actions.openUrl": @{
                @"actions": @{
                    @"type": @"url",
                    @"ios": VARS_ACTION_OPEN_URL_ADDRESS
                }
            },
            @"map.int": @123,
            @"map.float": @15.6f,
            @"map.innerMap.boolean": @YES,
            @"map.innerMap.string": @"String",
            @"map.innerMap.char": @1,
            @"map.innerMap.int": @1345,
            @"map.innerMap.long": @21474836470,
            @"map.innerMap.double": @3402823466385288.0,
            @"map.innerMap.innermostMap.int": @1024,
            @"map.innerMap.innermostMap.string": @"innerText",
            @"map.innerMap.innermostMap.boolean": @YES
        }
    };
}

static NSString * const TEMPLATE_NAME = @"Template";
static NSString * const TEMPLATE_NAME_NESTED = @"TemplateNestedArgs";
static NSString * const FUNCTION_NAME_TOP_LEVEL = @"FunctionTopLevel";

static BOOL const VARS_OVERRIDE_BOOLEAN = YES;
static NSString * const VARS_OVERRIDE_STRING = @"Text";
static char const VARS_OVERRIDE_CHAR = 10;
static long long const VARS_OVERRIDE_LONG = 21474836475;
static double const VARS_OVERRIDE_DOUBLE = 3402823466385285.0;

static BOOL const VARS_DEFAULT_BOOLEAN = NO;
static NSString * const VARS_DEFAULT_STRING = @"Default";
static char const VARS_DEFAULT_CHAR = 1;
static long long const VARS_DEFAULT_LONG = 5435050l;
static double const VARS_DEFAULT_DOUBLE = 12.345678;
static int const VARS_DEFAULT_INT = 35;

static NSString * const VARS_ACTION_FUNCTION_NAME = @"function";
static BOOL const VARS_ACTION_OVERRIDE_BOOLEAN = YES;
static NSString * const VARS_ACTION_OVERRIDE_STRING = @"Function text";
static int const VARS_ACTION_OVERRIDE_INT = 5421;

static NSString * const VARS_ACTION_OPEN_URL_ADDRESS = @"https://clevertap.com";

@end
