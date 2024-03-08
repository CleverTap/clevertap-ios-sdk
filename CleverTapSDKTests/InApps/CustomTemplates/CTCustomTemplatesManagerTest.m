//
//  CTCustomTemplatesManagerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 28.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTCustomTemplatesManager.h"
#import "CTInAppTemplateBuilder.h"
#import "CTAppFunctionBuilder.h"

@interface TestPresenter : NSObject<CTTemplatePresenter>
@end

@implementation TestPresenter
- (void)OnCloseClickedWithContext:(CTTemplateContext *)context {
}
- (void)OnPresentWithContext:(CTTemplateContext *)context {
}
@end

@interface TestTemplateProducer : NSObject<CTTemplateProducer>
@end

@implementation TestTemplateProducer

- (NSSet<CTCustomTemplate *> *)defineTemplates:(NSString *)accountId {
    NSMutableSet *templates = [NSMutableSet set];
    
    CTInAppTemplateBuilder *myTemplateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [myTemplateBuilder setName:@"My Template"];
    [myTemplateBuilder addArgument:@"b" withBool:NO];
    [myTemplateBuilder addArgument:@"c" withString:@"1 string"];
    [myTemplateBuilder addArgument:@"d" withString:@"2 string"];
    [myTemplateBuilder addArgument:@"e" withDictionary:@{
        @"h": @7,
        @"f": @{
            @"c": @4,
            @"e": @"6 string",
            @"d": @5
        }
    }];
    [myTemplateBuilder addArgument:@"l" withString:@"9 string"];
    [myTemplateBuilder addArgument:@"k" withNumber:@10];
    [myTemplateBuilder addArgument:@"e.w" withNumber:@8];
    [myTemplateBuilder addArgument:@"e.f.a" withNumber:@3];
    [myTemplateBuilder addArgument:@"a" withDictionary: @{
        @"n": @"12 string",
        @"m": @"11 string"
    }];
    [myTemplateBuilder setOnPresentWithPresenter:[TestPresenter new]];
    [templates addObject:[myTemplateBuilder build]];
    
    CTInAppTemplateBuilder *myTemplate2Builder = [CTInAppTemplateBuilder new];
    [myTemplate2Builder setName:@"My Template 2"];
    [myTemplate2Builder addArgument:@"b" withBool:NO];
    [myTemplate2Builder addArgument:@"c" withString:@"1 string"];
    [myTemplate2Builder addArgument:@"a.d" withNumber:@5];
    [myTemplate2Builder addArgument:@"a.c.a" withNumber:@4];
    [myTemplate2Builder addArgument:@"a" withDictionary: @{
        @"b": @"3 string",
        @"a": @"2 string"
    }];
    [myTemplate2Builder setOnPresentWithPresenter:[TestPresenter new]];
    [templates addObject:[myTemplate2Builder build]];
    
    CTAppFunctionBuilder *myFunctionBuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO];
    [myFunctionBuilder setName:@"My Function"];
    [myFunctionBuilder addArgument:@"b" withBool:NO];
    [myFunctionBuilder addArgument:@"a" withString:@"1 string"];
    [myFunctionBuilder setOnPresentWithPresenter:[TestPresenter new]];
    [templates addObject:[myFunctionBuilder build]];
    
    return templates;
}

@end

@interface CTCustomTemplatesManagerTest : XCTestCase

@end

@implementation CTCustomTemplatesManagerTest

- (void)testSync {
    [CTCustomTemplatesManager registerTemplateProducer:[TestTemplateProducer new]];
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"" accountToken:@""];
    CTCustomTemplatesManager *manager = [[CTCustomTemplatesManager alloc] initWithConfig:config];
    
    NSDictionary *syncPayload = [manager syncPayload];
    
    NSLog(@"%@", syncPayload);
    
    XCTAssertEqual([syncPayload[@"definitions"] count], 3);
}

- (void)testBuild {
    CTInAppTemplateBuilder *myTemplateBuilder = [[CTInAppTemplateBuilder alloc] init];
    [myTemplateBuilder setName:@"My Template"];
    [myTemplateBuilder addArgument:@"a" withBool:NO];
    XCTAssertThrows([myTemplateBuilder addArgument:@"a" withBool:NO]);
    //[myTemplateBuilder build];
}

@end
