//
//  CTAppRatingSystemAppFunctionTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTAppRatingSystemAppFunction.h"
#import "CTCustomTemplate-Internal.h"
#import "CTSystemTemplateActionHandler.h"
#import "CTConstants.h"

@interface CTAppRatingSystemAppFunctionTest : XCTestCase
@property (nonatomic, strong) id mockHandler;
@property (nonatomic, strong) CTCustomTemplate *template;
@end

@implementation CTAppRatingSystemAppFunctionTest

- (void)setUp {
    [super setUp];
    self.mockHandler = OCMClassMock([CTSystemTemplateActionHandler class]);
    self.template = [CTAppRatingSystemAppFunction buildTemplateWithHandler:self.mockHandler];
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
    XCTAssertEqualObjects(self.template.name, CLTAP_APP_RATING_TEMPLATE_NAME);
}

- (void)test_buildTemplate_isNotVisual {
    XCTAssertFalse(self.template.isVisual);
}

- (void)test_buildTemplate_hasNoArguments {
    XCTAssertEqual(self.template.arguments.count, 0u);
}

- (void)test_buildTemplate_isSystemDefined {
    XCTAssertTrue(self.template.isSystemDefined);
}

@end
