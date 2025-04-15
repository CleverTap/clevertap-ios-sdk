//
//  CTSystemAppFunctionsTest.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 14/04/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTSystemAppFunctions.h"
#import "CTSystemTemplateActionHandler.h"
#import "CTConstants.h"
#import "CTCustomTemplate-Internal.h"

@interface CTSystemAppFunctionsTest : XCTestCase

@property CTSystemTemplateActionHandler *actionHandler;
@property NSDictionary<NSString *, CTCustomTemplate *> *systemAppFunctions;

@end

@implementation CTSystemAppFunctionsTest

- (void)setUp {
    self.actionHandler = [[CTSystemTemplateActionHandler alloc] init];
    self.systemAppFunctions = [CTSystemAppFunctions systemAppFunctionsWithHandler:self.actionHandler];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSystemAppFunctions {
    // Verify total system app function count is 3.
    XCTAssertEqual(self.systemAppFunctions.count, 3);
    
    CTCustomTemplate *pushPermissionTemplate = self.systemAppFunctions[CLTAP_PUSH_PERMISSION_TEMPLATE_NAME];
    CTCustomTemplate *openUrlTemplate = self.systemAppFunctions[CLTAP_OPEN_URL_TEMPLATE_NAME];
    CTCustomTemplate *appRatingTemplate = self.systemAppFunctions[CLTAP_APP_RATING_TEMPLATE_NAME];
    
    // Verify Push Permission template
    XCTAssertEqualObjects(pushPermissionTemplate.name, CLTAP_PUSH_PERMISSION_TEMPLATE_NAME);
    XCTAssertEqualObjects(pushPermissionTemplate.arguments[0].name, CLTAP_FB_SETTINGS_KEY);
    XCTAssertEqualObjects(pushPermissionTemplate.arguments[0].defaultValue, @(NO));
    
    // Verify Open Url template
    XCTAssertEqualObjects(openUrlTemplate.name, CLTAP_OPEN_URL_TEMPLATE_NAME);
    XCTAssertEqualObjects(openUrlTemplate.arguments[0].name, CLTAP_OPEN_URL_ACTION_KEY);
    XCTAssertEqualObjects(openUrlTemplate.arguments[0].defaultValue, @(""));
    
    // Verify App Rating template
    XCTAssertEqualObjects(appRatingTemplate.name, CLTAP_APP_RATING_TEMPLATE_NAME);
    XCTAssertEqual(appRatingTemplate.arguments.count, 0);
}

@end
