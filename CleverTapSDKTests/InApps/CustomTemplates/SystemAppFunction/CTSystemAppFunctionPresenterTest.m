//
//  CTSystemAppFunctionPresenterTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTSystemAppFunctionPresenter.h"
#import "CTSystemTemplateActionHandler.h"
#import "CTTemplateContext.h"
#import "CTConstants.h"

@interface CTSystemAppFunctionPresenterTest : XCTestCase
@property (nonatomic, strong) id mockHandler;
@property (nonatomic, strong) CTSystemAppFunctionPresenter *presenter;
@end

@implementation CTSystemAppFunctionPresenterTest

- (void)setUp {
    [super setUp];
    self.mockHandler = OCMClassMock([CTSystemTemplateActionHandler class]);
    self.presenter = [[CTSystemAppFunctionPresenter alloc] initWithSystemTemplateActionHandler:self.mockHandler];
}

- (void)tearDown {
    [self.mockHandler stopMocking];
    self.mockHandler = nil;
    self.presenter = nil;
    [super tearDown];
}

- (id)mockContextWithTemplateName:(NSString *)name {
    id ctx = OCMClassMock([CTTemplateContext class]);
    OCMStub([ctx templateName]).andReturn(name);
    return ctx;
}

#pragma mark - init

- (void)test_init_returnsNonNil {
    XCTAssertNotNil(self.presenter);
}

#pragma mark - onCloseClicked:

- (void)test_onCloseClicked_doesNotCrash {
    id ctx = [self mockContextWithTemplateName:CLTAP_PUSH_PERMISSION_TEMPLATE_NAME];
    XCTAssertNoThrow([self.presenter onCloseClicked:ctx]);
    [ctx stopMocking];
}

#pragma mark - onPresent: — push permission

- (void)test_onPresent_pushPermission_callsPromptPushPermission {
    id ctx = [self mockContextWithTemplateName:CLTAP_PUSH_PERMISSION_TEMPLATE_NAME];
    OCMStub([ctx boolNamed:CLTAP_FB_SETTINGS_KEY]).andReturn(NO);
    OCMStub([ctx presented]);
    OCMStub([ctx dismissed]);

    OCMExpect([self.mockHandler promptPushPermission:NO withCompletionBlock:OCMOCK_ANY]);

    [self.presenter onPresent:ctx];

    OCMVerifyAll(self.mockHandler);
    [ctx stopMocking];
}

- (void)test_onPresent_pushPermission_passesFbSettings {
    id ctx = [self mockContextWithTemplateName:CLTAP_PUSH_PERMISSION_TEMPLATE_NAME];
    OCMStub([ctx boolNamed:CLTAP_FB_SETTINGS_KEY]).andReturn(YES);
    OCMStub([ctx presented]);
    OCMStub([ctx dismissed]);

    OCMExpect([self.mockHandler promptPushPermission:YES withCompletionBlock:OCMOCK_ANY]);

    [self.presenter onPresent:ctx];

    OCMVerifyAll(self.mockHandler);
    [ctx stopMocking];
}

#pragma mark - onPresent: — open URL

- (void)test_onPresent_openURL_callsHandleOpenURL {
    id ctx = [self mockContextWithTemplateName:CLTAP_OPEN_URL_TEMPLATE_NAME];
    OCMStub([ctx stringNamed:CLTAP_OPEN_URL_ACTION_KEY]).andReturn(@"https://example.com");
    OCMStub([ctx presented]);
    OCMStub([ctx dismissed]);

    // Use OCMExpect with andReturn so both the return value and the call expectation
    // are registered together — avoids OCMStub consuming the call before OCMExpect tracks it.
    OCMExpect([self.mockHandler handleOpenURL:@"https://example.com"]).andReturn(YES);

    [self.presenter onPresent:ctx];

    OCMVerifyAll(self.mockHandler);
    [ctx stopMocking];
}

- (void)test_onPresent_openURL_callsDismissed {
    id ctx = [self mockContextWithTemplateName:CLTAP_OPEN_URL_TEMPLATE_NAME];
    OCMStub([ctx stringNamed:CLTAP_OPEN_URL_ACTION_KEY]).andReturn(@"https://example.com");
    OCMStub([self.mockHandler handleOpenURL:OCMOCK_ANY]).andReturn(NO);

    OCMExpect([ctx dismissed]);

    [self.presenter onPresent:ctx];

    OCMVerifyAll(ctx);
    [ctx stopMocking];
}

#pragma mark - onPresent: — app rating

- (void)test_onPresent_appRating_callsPromptAppRating {
    id ctx = [self mockContextWithTemplateName:CLTAP_APP_RATING_TEMPLATE_NAME];
    OCMStub([ctx presented]);
    OCMStub([ctx dismissed]);

    OCMExpect([self.mockHandler promptAppRatingWithCompletionBlock:OCMOCK_ANY]);

    [self.presenter onPresent:ctx];

    OCMVerifyAll(self.mockHandler);
    [ctx stopMocking];
}

#pragma mark - onPresent: — unknown template

- (void)test_onPresent_unknownTemplate_doesNotCrash {
    id ctx = [self mockContextWithTemplateName:@"ctsystem_unknown"];
    XCTAssertNoThrow([self.presenter onPresent:ctx]);
    [ctx stopMocking];
}

@end
