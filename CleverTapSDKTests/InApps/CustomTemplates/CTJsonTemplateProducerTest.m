//
//  CTJsonTemplateProducerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 13.09.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTJsonTemplateProducer.h"
#import "CTTemplatePresenterMock.h"
#import "CTCustomTemplate-Internal.h"

@interface CTJsonTemplateProducerTest : XCTestCase

@property CTTemplatePresenterMock *presenter;
@property CleverTapInstanceConfig *config;

@end

@implementation CTJsonTemplateProducerTest

- (void)setUp {
    self.presenter = [[CTTemplatePresenterMock alloc] init];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
}

- (void)testJsonDefinitions {
    NSString *json = [NSString stringWithFormat:@"{%@, %@}", self.template1, self.function1];
    
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:json templatePresenter:self.presenter functionPresenter:self.presenter];
    
    NSSet *templates = [producer defineTemplates:self.config];
    XCTAssertEqual(2, templates.count);
    
    // Validate template1
    CTCustomTemplate *template1 = [self templateWithName:@"template-1" inSet:templates];
    XCTAssertNotNil(template1);
    XCTAssertEqualObjects(TEMPLATE_TYPE, template1.templateType);

    NSArray *template1Keys = [template1.arguments valueForKey:@"name"];
    NSArray *template1Values = [template1.arguments valueForKey:@"defaultValue"];
    NSDictionary *template1ArgsDict = [NSDictionary dictionaryWithObjects:template1Values forKeys:template1Keys];
    
    XCTAssertEqualObjects(@"Default", template1ArgsDict[@"string"]);
    XCTAssertEqual(0.0, [template1ArgsDict[@"number"] doubleValue]);
    XCTAssertEqual(YES, [template1ArgsDict[@"boolean"] boolValue]);
    XCTAssertEqualObjects([NSNull null], template1ArgsDict[@"file"]);
    XCTAssertEqualObjects([NSNull null], template1ArgsDict[@"action"]);
    XCTAssertEqualObjects(@"Inner Default", template1ArgsDict[@"map.innerString"]);
    XCTAssertEqual(1.0, [template1ArgsDict[@"map.innerNumber"] doubleValue]);
    XCTAssertEqual(NO, [template1ArgsDict[@"map.innerBoolean"] boolValue]);
    XCTAssertEqualObjects(@"Innermost Default", template1ArgsDict[@"map.innerMap.innermostString"]);
    
    // Validate function2
    CTCustomTemplate *function2 = [self templateWithName:@"function-2" inSet:templates];
    XCTAssertNotNil(function2);
    XCTAssertEqualObjects(FUNCTION_TYPE, function2.templateType);
    XCTAssertEqual(NO, function2.isVisual);
    
    NSArray *function2Keys = [function2.arguments valueForKey:@"name"];
    NSArray *function2Values = [function2.arguments valueForKey:@"defaultValue"];
    NSDictionary *function2ArgsDict = [NSDictionary dictionaryWithObjects:function2Values forKeys:function2Keys];
    
    XCTAssertEqualObjects(@"Default", function2ArgsDict[@"functionString"]);
    XCTAssertEqual(0.0, [function2ArgsDict[@"functionNumber"] doubleValue]);
    XCTAssertEqual(YES, [function2ArgsDict[@"functionBoolean"] boolValue]);
    XCTAssertEqualObjects([NSNull null], function2ArgsDict[@"functionFile"]);
    XCTAssertEqualObjects(@"Inner Default", function2ArgsDict[@"functionMap.innerString"]);
}

- (void)testInvalidJson {
    NSString *invalidJson = @"{[]}";
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidJson templatePresenter:self.presenter functionPresenter:self.presenter];
    
    XCTAssertThrows([producer defineTemplates:self.config]);
}

- (void)testPresenterNotProvided {
#pragma clang diagnostic ignored "-Wnonnull"
    NSString *templateJson = [NSString stringWithFormat:@"{%@}", self.template1];
    CTJsonTemplateProducer *templateJsonProducer = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:templateJson templatePresenter:nil functionPresenter:self.presenter];
    XCTAssertThrows([templateJsonProducer defineTemplates:self.config]);
    
    NSString *functionJson = [NSString stringWithFormat:@"{%@}", self.function1];
    CTJsonTemplateProducer *functionJsonProducer = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:functionJson templatePresenter:self.presenter functionPresenter:nil];
    XCTAssertThrows([functionJsonProducer defineTemplates:self.config]);
#pragma clang diagnostic pop
}

- (void)testInvalidValues {
    // Invalid Template Type JSON
    NSString *invalidTemplateTypeJson = @"{"
        "\"template\": {"
            "\"type\": \"string\","
            "\"arguments\": {"
                "\"string\": {"
                    "\"type\": \"string\","
                    "\"value\": \"Text\""
                "}"
            "}"
        "}"
    "}";
    
    CTJsonTemplateProducer *producer1 = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidTemplateTypeJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrows([producer1 defineTemplates:self.config]);

    // Invalid Argument Type JSON
    NSString *invalidArgumentTypeJson = @"{"
        "\"template\": {"
            "\"type\": \"template\","
            "\"arguments\": {"
                "\"json\": {"
                    "\"type\": \"json\","
                    "\"value\": {}"
                "}"
            "}"
        "}"
    "}";
    
    CTJsonTemplateProducer *producer2 = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidArgumentTypeJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrows([producer2 defineTemplates:self.config]);

    // Invalid File Value JSON
    NSString *invalidFileValueJson = @"{"
        "\"template\": {"
            "\"type\": \"template\","
            "\"arguments\": {"
                "\"file\": {"
                    "\"type\": \"file\","
                    "\"value\": \"https://files.example.com/file.pdf\""
                "}"
            "}"
        "}"
    "}";
    
    CTJsonTemplateProducer *producer3 = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidFileValueJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrows([producer3 defineTemplates:self.config]);

    // Invalid Function File Value JSON
    NSString *invalidFunctionFileValueJson = @"{"
        "\"template\": {"
            "\"type\": \"function\","
            "\"arguments\": {"
                "\"file\": {"
                    "\"type\": \"file\","
                    "\"value\": \"https://files.example.com/file.pdf\""
                "}"
            "}"
        "}"
    "}";
    
    CTJsonTemplateProducer *producer4 = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidFunctionFileValueJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrows([producer4 defineTemplates:self.config]);

    // Invalid Action Value JSON
    NSString *invalidActionValueJson = @"{"
        "\"template\": {"
            "\"type\": \"template\","
            "\"arguments\": {"
                "\"action\": {"
                    "\"type\": \"action\","
                    "\"value\": \"function1\""
                "}"
            "}"
        "}"
    "}";
    
    CTJsonTemplateProducer *producer5 = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidActionValueJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrows([producer5 defineTemplates:self.config]);

    // Invalid Function Action JSON
    NSString *invalidFunctionActionJson = @"{"
        "\"template\": {"
            "\"type\": \"function\","
            "\"isVisual\": true,"
            "\"arguments\": {"
                "\"action\": {"
                    "\"type\": \"action\""
                "}"
            "}"
        "}"
    "}";
    
    CTJsonTemplateProducer *producer6 = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidFunctionActionJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrows([producer6 defineTemplates:self.config]);

    // Invalid Nested File JSON
    NSString *invalidNestedFileJson = @"{"
        "\"template\": {"
            "\"type\": \"template\","
            "\"arguments\": {"
                "\"map\": {"
                    "\"type\": \"object\","
                    "\"value\": {"
                        "\"file\": {"
                            "\"type\": \"file\""
                        "}"
                    "}"
                "}"
            "}"
        "}"
    "}";
    
    CTJsonTemplateProducer *producer7 = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:invalidNestedFileJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrows([producer7 defineTemplates:self.config]);
}

- (CTCustomTemplate * _Nullable)templateWithName:(NSString *)name inSet:(NSSet *)templates {
    return [templates objectsPassingTest:^BOOL(CTCustomTemplate * _Nonnull template, BOOL * _Nonnull stop) {
        if ([template.name isEqualToString:name]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }].anyObject;
}

- (NSString *)template1 {
    return [
        @"\"template-1\": {"
        "  \"type\": \"template\","
        "  \"arguments\": {"
        "    \"string\": {"
        "      \"type\": \"string\","
        "      \"value\": \"Default\""
        "    },"
        "    \"number\": {"
        "      \"type\": \"number\","
        "      \"value\": 0"
        "    },"
        "    \"boolean\": {"
        "      \"type\": \"boolean\","
        "      \"value\": true"
        "    },"
        "    \"file\": {"
        "      \"type\": \"file\""
        "    },"
        "    \"action\": {"
        "      \"type\": \"action\""
        "    },"
        "    \"map\": {"
        "      \"type\": \"object\","
        "      \"value\": {"
        "        \"innerString\": {"
        "          \"type\": \"string\","
        "          \"value\": \"Inner Default\""
        "        },"
        "        \"innerNumber\": {"
        "          \"type\": \"number\","
        "          \"value\": 1"
        "        },"
        "        \"innerBoolean\": {"
        "          \"type\": \"boolean\","
        "          \"value\": false"
        "        },"
        "        \"innerMap\": {"
        "          \"type\": \"object\","
        "          \"value\": {"
        "            \"innermostString\": {"
        "              \"type\": \"string\","
        "              \"value\": \"Innermost Default\""
        "            }"
        "          }"
        "        }"
        "      }"
        "    }"
        "  }"
        "}" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)function1 {
    return [
        @"\"function-2\": {"
        "  \"type\": \"function\","
        "  \"isVisual\": false,"
        "  \"arguments\": {"
        "    \"functionString\": {"
        "      \"type\": \"string\","
        "      \"value\": \"Default\""
        "    },"
        "    \"functionNumber\": {"
        "      \"type\": \"number\","
        "      \"value\": 0"
        "    },"
        "    \"functionBoolean\": {"
        "      \"type\": \"boolean\","
        "      \"value\": true"
        "    },"
        "    \"functionFile\": {"
        "      \"type\": \"file\""
        "    },"
        "    \"functionMap\": {"
        "      \"type\": \"object\","
        "      \"value\": {"
        "        \"innerString\": {"
        "          \"type\": \"string\","
        "          \"value\": \"Inner Default\""
        "        }"
        "      }"
        "    }"
        "  }"
        "}" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
