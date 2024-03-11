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
#import "CTCustomTemplatesManager+Tests.h"
#import "CTInAppTemplateBuilder.h"
#import "CTAppFunctionBuilder.h"
#import "CTTemplatePresenterMock.h"
#import "CTTestTemplateProducer.h"

@interface CTCustomTemplatesManagerTest : XCTestCase

@end

@implementation CTCustomTemplatesManagerTest

- (void)tearDown {
    [super tearDown];
    [CTCustomTemplatesManager clearTemplateProducers];
}

- (void)testSync {
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
    [myTemplateBuilder setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
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
    [myTemplate2Builder setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
    [templates addObject:[myTemplate2Builder build]];
    
    CTAppFunctionBuilder *myFunctionBuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO];
    [myFunctionBuilder setName:@"My Function"];
    [myFunctionBuilder addArgument:@"b" withBool:NO];
    [myFunctionBuilder addArgument:@"a" withString:@"1 string"];
    [myFunctionBuilder setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
    [templates addObject:[myFunctionBuilder build]];
    
    CTTestTemplateProducer *producer = [[CTTestTemplateProducer alloc] initWithTemplates:templates];
    [CTCustomTemplatesManager registerTemplateProducer:producer];
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"account1" accountToken:@""];
    CTCustomTemplatesManager *manager = [[CTCustomTemplatesManager alloc] initWithConfig:config];
    
    NSDictionary *syncPayload = [manager syncPayload];
    
    NSLog(@"%@", syncPayload);
    
    XCTAssertEqual([syncPayload[@"definitions"] count], 3);
}

- (void)testTemplatesRegistered {
    NSMutableSet *templates = [NSMutableSet set];
    
    NSString *templateName1 = @"Template1";
    NSString *templateName2 = @"Template2";
    NSString *functionName1 = @"Function1";
    NSString *functionName2 = @"Function2";
    
    CTInAppTemplateBuilder *templateBuilder1 = [CTInAppTemplateBuilder new];
    [templateBuilder1 setName:templateName1];
    [templateBuilder1 setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
    [templates addObject:[templateBuilder1 build]];
    
    CTInAppTemplateBuilder *templateBuilder2 = [CTInAppTemplateBuilder new];
    [templateBuilder2 setName:templateName2];
    [templateBuilder2 setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
    [templates addObject:[templateBuilder2 build]];
    
    CTAppFunctionBuilder *functionBuilder1 = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO];
    [functionBuilder1 setName:functionName1];
    [functionBuilder1 setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
    [templates addObject:[functionBuilder1 build]];
    
    CTAppFunctionBuilder *functionBuilder2 = [[CTAppFunctionBuilder alloc] initWithIsVisual:NO];
    [functionBuilder2 setName:functionName2];
    [functionBuilder2 setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
    [templates addObject:[functionBuilder2 build]];
    
    CTTestTemplateProducer *producer = [[CTTestTemplateProducer alloc] initWithTemplates:templates];
    [CTCustomTemplatesManager registerTemplateProducer:producer];
    
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"accountId1" accountToken:@"token"];
    CTCustomTemplatesManager *manager = [[CTCustomTemplatesManager alloc] initWithConfig:config];
    
    XCTAssertTrue([manager existsTemplateWithName:templateName1]);
    XCTAssertTrue([manager existsTemplateWithName:templateName2]);
    XCTAssertTrue([manager existsTemplateWithName:functionName1]);
    XCTAssertTrue([manager existsTemplateWithName:functionName2]);
    
    XCTAssertFalse([manager existsTemplateWithName:@"non-existent"]);
    
    CleverTapInstanceConfig *config2 = [[CleverTapInstanceConfig alloc] initWithAccountId:@"accountId2" accountToken:@"token"];
    CTCustomTemplatesManager *managerWithConfig2 = [[CTCustomTemplatesManager alloc] initWithConfig:config2];
    
    XCTAssertTrue([manager existsTemplateWithName:templateName1]);
    XCTAssertTrue([manager existsTemplateWithName:templateName2]);
    XCTAssertTrue([manager existsTemplateWithName:functionName1]);
    XCTAssertTrue([manager existsTemplateWithName:functionName2]);
    
    XCTAssertFalse([manager existsTemplateWithName:@"non-existent"]);
}

- (void)testDuplicateTemplateNameThrows {
    NSMutableSet *templates = [NSMutableSet set];
    CTInAppTemplateBuilder *templateBuilder1 = [CTInAppTemplateBuilder new];
    [templateBuilder1 setName:@"Template1"];
    [templateBuilder1 setOnPresentWithPresenter:[CTTemplatePresenterMock new]];
    [templates addObject:[templateBuilder1 build]];
    CTTestTemplateProducer *producer = [[CTTestTemplateProducer alloc] initWithTemplates:templates];
    
    [CTCustomTemplatesManager registerTemplateProducer:producer];
    [CTCustomTemplatesManager registerTemplateProducer:producer];
    
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"accountId1" accountToken:@"token"];
    XCTAssertThrows([[CTCustomTemplatesManager alloc] initWithConfig:config]);
}

@end
