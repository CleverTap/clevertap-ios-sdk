//
//  CTPushPermissionSystemAppFunctionTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTPushPermissionSystemAppFunction.h"
#import "CTCustomTemplate-Internal.h"
#import "CTTemplateArgument.h"
#import "CTSystemTemplateActionHandler.h"
#import "CTConstants.h"

@interface CTPushPermissionSystemAppFunctionTest : XCTestCase
@property (nonatomic, strong) id mockHandler;
@property (nonatomic, strong) CTCustomTemplate *template;
@end

@implementation CTPushPermissionSystemAppFunctionTest

- (void)setUp {
    [super setUp];
    self.mockHandler = OCMClassMock([CTSystemTemplateActionHandler class]);
    self.template = [CTPushPermissionSystemAppFunction buildTemplateWithHandler:self.mockHandler];
}

- (void)tearDown {
    [self.mockHandler stopMocking];
    self.mockHandler = nil;
    self.template = nil;
    [super tearDown];
}

- (void)test_buildTemplate_returnsNonNil {
    XCTAssertNotNil(self.template);
}

- (void)test_buildTemplate_hasCorrectName {
    XCTAssertEqualObjects(self.template.name, CLTAP_PUSH_PERMISSION_TEMPLATE_NAME);
}

- (void)test_buildTemplate_isNotVisual {
    XCTAssertFalse(self.template.isVisual);
}

- (void)test_buildTemplate_hasOneArgument {
    XCTAssertEqual(self.template.arguments.count, 1u);
}

- (void)test_buildTemplate_argumentKeyIsFbSettingsKey {
    CTTemplateArgument *arg = self.template.arguments.firstObject;
    XCTAssertEqualObjects(arg.name, CLTAP_FB_SETTINGS_KEY);
}

- (void)test_buildTemplate_argumentTypeIsBool {
    CTTemplateArgument *arg = self.template.arguments.firstObject;
    XCTAssertEqual(arg.type, CTTemplateArgumentTypeBool);
}

@end
