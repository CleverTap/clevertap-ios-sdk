//
//  CTCustomTemplateTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 7.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTCustomTemplate-Internal.h"
#import "CTCustomTemplateBuilder.h"

@interface CTCustomTemplateTest : XCTestCase

@end

@implementation CTCustomTemplateTest

- (void)testEqual {
    CTCustomTemplate *template = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    CTCustomTemplate *sameTemplate = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    CTCustomTemplate *sameName = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:FUNCTION_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    CTCustomTemplate *differentName = [[CTCustomTemplate alloc] initWithTemplateName:@"template1" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    XCTAssertEqualObjects(template, template);
    XCTAssertEqualObjects(template, sameTemplate);
    XCTAssertEqualObjects(template, sameName);
    XCTAssertNotEqualObjects(template, differentName);
    XCTAssertNotEqualObjects(template, @"template");
}

- (void)testHash {
    CTCustomTemplate *template = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    CTCustomTemplate *sameTemplate = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    CTCustomTemplate *sameName = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:FUNCTION_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    CTCustomTemplate *differentName = [[CTCustomTemplate alloc] initWithTemplateName:@"template1" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    XCTAssertEqual([template hash], [sameTemplate hash]);
    XCTAssertEqual([template hash], [sameName hash]);
    XCTAssertNotEqual([template hash], [differentName hash]);
}

- (void)testIsEqual_withNilObject {
    CTCustomTemplate *template = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    XCTAssertFalse([template isEqual:nil]);
}

- (void)testIsEqual_withNonTemplateObject {
    CTCustomTemplate *template = [[CTCustomTemplate alloc] initWithTemplateName:@"template" templateType:TEMPLATE_TYPE isVisual:true arguments:@[] presenter:nil isSystemDefined:NO];
    XCTAssertFalse([template isEqual:@"template"]);
    XCTAssertFalse([template isEqual:@42]);
}

- (void)testDebugDescription {
    CTCustomTemplate *template = [[CTCustomTemplate alloc] initWithTemplateName:@"myTemplate" templateType:TEMPLATE_TYPE isVisual:YES arguments:@[] presenter:nil isSystemDefined:NO];
    NSString *desc = [template debugDescription];
    XCTAssertNotNil(desc);
    XCTAssertTrue([desc isKindOfClass:[NSString class]]);
    XCTAssertTrue([desc containsString:@"myTemplate"]);
    XCTAssertTrue([desc containsString:@"YES"]);
}

- (void)testDebugDescription_notVisual {
    CTCustomTemplate *template = [[CTCustomTemplate alloc] initWithTemplateName:@"funcTemplate" templateType:FUNCTION_TYPE isVisual:NO arguments:@[] presenter:nil isSystemDefined:NO];
    NSString *desc = [template debugDescription];
    XCTAssertTrue([desc containsString:@"funcTemplate"]);
    XCTAssertTrue([desc containsString:@"NO"]);
}

@end
