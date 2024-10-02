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
#import "CTConstants.h"

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
    
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJson:json templatePresenter:self.presenter functionPresenter:self.presenter];
    
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

- (void)testNoArguments {
    NSString *noArgumentsJson = @"{"
    @"\"template-1\": {"
    "  \"type\": \"template\","
    "  \"arguments\": {"
    "    }"
    "  }"
    "}";
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJson:noArgumentsJson templatePresenter:self.presenter functionPresenter:self.presenter];
    
    NSSet *templates = [producer defineTemplates:self.config];
    CTCustomTemplate *template1 = [self templateWithName:@"template-1" inSet:templates];
    XCTAssertNotNil(template1);
    XCTAssertEqualObjects(TEMPLATE_TYPE, template1.templateType);
    XCTAssertEqual(0, template1.arguments.count);
}

- (void)testNoJson {
    NSString *nilJson = nil;
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJson:nilJson templatePresenter:self.presenter functionPresenter:self.presenter];
    
    XCTAssertThrowsSpecificNamed([producer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);
}

- (void)testPresenterNotProvided {
#pragma clang diagnostic ignored "-Wnonnull"
    NSString *templateJson = [NSString stringWithFormat:@"{%@}", self.template1];
    CTJsonTemplateProducer *templateJsonProducer = [[CTJsonTemplateProducer alloc] initWithJson:templateJson templatePresenter:nil functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([templateJsonProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);
    
    NSString *functionJson = [NSString stringWithFormat:@"{%@}", self.function1];
    CTJsonTemplateProducer *functionJsonProducer = [[CTJsonTemplateProducer alloc] initWithJson:functionJson templatePresenter:self.presenter functionPresenter:nil];
    XCTAssertThrowsSpecificNamed([functionJsonProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);
#pragma clang diagnostic pop
}

- (void)testInvalidJson {
    NSString *invalidJson = @"{[]}";
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJson:invalidJson templatePresenter:self.presenter functionPresenter:self.presenter];
    
    XCTAssertThrowsSpecificNamed([producer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);
}

- (void)testEmptyObjectArgument {
    NSString *json = [@"{"
        @"\"template-1\": {"
        "  \"type\": \"template\","
        "  \"arguments\": {"
        "    \"map\": {"
        "      \"type\": \"object\","
        "      \"value\": {"
        "       }"
        "      }"
        "    }"
        "  }"
        "}" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJson:json templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([producer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);
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
    
    CTJsonTemplateProducer *invalidTemplateTypeProducer = [[CTJsonTemplateProducer alloc] initWithJson:invalidTemplateTypeJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([invalidTemplateTypeProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);

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
    
    CTJsonTemplateProducer *invalidArgumentTypeProducer = [[CTJsonTemplateProducer alloc] initWithJson:invalidArgumentTypeJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([invalidArgumentTypeProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);

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
    
    CTJsonTemplateProducer *invalidFileValueJsonProducer = [[CTJsonTemplateProducer alloc] initWithJson:invalidFileValueJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([invalidFileValueJsonProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);

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
    
    CTJsonTemplateProducer *invalidFunctionFileValueJsonProducer = [[CTJsonTemplateProducer alloc] initWithJson:invalidFunctionFileValueJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([invalidFunctionFileValueJsonProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);

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
    
    CTJsonTemplateProducer *invalidActionValueJsonProducer = [[CTJsonTemplateProducer alloc] initWithJson:invalidActionValueJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([invalidActionValueJsonProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);

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
    
    CTJsonTemplateProducer *invalidFunctionActionProducer = [[CTJsonTemplateProducer alloc] initWithJson:invalidFunctionActionJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([invalidFunctionActionProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);

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
    
    CTJsonTemplateProducer *invalidNestedFileJsonProducer = [[CTJsonTemplateProducer alloc] initWithJson:invalidNestedFileJson templatePresenter:self.presenter functionPresenter:self.presenter];
    XCTAssertThrowsSpecificNamed([invalidNestedFileJsonProducer defineTemplates:self.config], NSException, CLTAP_CUSTOM_TEMPLATE_EXCEPTION);
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
