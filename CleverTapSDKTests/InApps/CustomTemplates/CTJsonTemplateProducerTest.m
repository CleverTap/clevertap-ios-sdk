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

@end

@implementation CTJsonTemplateProducerTest

- (void)testJsonDefinitions {
    NSString *json = [NSString stringWithFormat:@"{%@, %@}", self.template1, self.function1];
    
    CTTemplatePresenterMock *presenter = [[CTTemplatePresenterMock alloc] init];
    CTJsonTemplateProducer *producer = [[CTJsonTemplateProducer alloc] initWithJsonTemplateDefinitions:json templatePresenter:presenter functionPresenter:presenter];
    
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    
    NSSet *templates = [producer defineTemplates:config];
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
