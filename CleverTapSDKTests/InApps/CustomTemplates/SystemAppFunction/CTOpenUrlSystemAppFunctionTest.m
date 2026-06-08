//
//  CTOpenUrlSystemAppFunctionTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTOpenUrlSystemAppFunction.h"
#import "CTCustomTemplate-Internal.h"
#import "CTTemplateArgument.h"
#import "CTSystemTemplateActionHandler.h"
#import "CTConstants.h"

@interface CTOpenUrlSystemAppFunctionTest : XCTestCase
@property (nonatomic, strong) id mockHandler;
@property (nonatomic, strong) CTCustomTemplate *template;
@end

@implementation CTOpenUrlSystemAppFunctionTest

- (void)setUp {
    [super setUp];
    self.mockHandler = OCMClassMock([CTSystemTemplateActionHandler class]);
    self.template = [CTOpenUrlSystemAppFunction buildTemplateWithHandler:self.mockHandler];
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
    XCTAssertEqualObjects(self.template.name, CLTAP_OPEN_URL_TEMPLATE_NAME);
}

- (void)test_buildTemplate_isNotVisual {
    XCTAssertFalse(self.template.isVisual);
}

- (void)test_buildTemplate_hasOneArgument {
    XCTAssertEqual(self.template.arguments.count, 1u);
}

- (void)test_buildTemplate_argumentKeyIsOpenUrlActionKey {
    CTTemplateArgument *arg = self.template.arguments.firstObject;
    XCTAssertEqualObjects(arg.name, CLTAP_OPEN_URL_ACTION_KEY);
}

- (void)test_buildTemplate_argumentTypeIsString {
    CTTemplateArgument *arg = self.template.arguments.firstObject;
    XCTAssertEqual(arg.type, CTTemplateArgumentTypeString);
}

@end
