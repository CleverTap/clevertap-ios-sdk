//
//  CleverTapJSInterfaceTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 12/06/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <WebKit/WebKit.h>
#import "CleverTapJSInterface.h"
#import "CleverTapJSInterfacePrivate.h"
#import "CleverTap.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTInAppDisplayViewController.h"
#import "CTNotificationAction.h"
#import "CleverTap+PushPermission.h"

@interface CleverTapJSInterface (Tests)
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, weak) CTInAppDisplayViewController *controller;
- (void)handleMessageFromWebview:(NSDictionary<NSString *,id> *)message forInstance:(CleverTap *)cleverTap;
- (void)triggerInAppAction:(NSDictionary *)actionJson callToAction:(NSString *)callToAction buttonId:(NSString *)buttonId;
@end

@interface CleverTapJSInterfaceTests : XCTestCase

@property (nonatomic, strong) CleverTapJSInterface *jsInterface;
@property (nonatomic, strong) id mockConfig;
@property (nonatomic, strong) id mockCleverTap;
@property (nonatomic, strong) id mockController;
@property (nonatomic, strong) id mockUserContentController;
@property (nonatomic, strong) id mockScriptMessage;

@end

@implementation CleverTapJSInterfaceTests

- (void)setUp {
    [super setUp];
    
    // Create mocks - use OCMPartialMock for CleverTapInstanceConfig with proper initialization
    CleverTapInstanceConfig *realConfig = [[CleverTapInstanceConfig alloc]
                                          initWithAccountId:@"testAccount"
                                          accountToken:@"testToken"
                                          accountRegion:@"testRegion"];
    self.mockConfig = OCMPartialMock(realConfig);
    
    self.mockController = OCMClassMock([CTInAppDisplayViewController class]);
    self.mockUserContentController = OCMClassMock([WKUserContentController class]);
    self.mockScriptMessage = OCMClassMock([WKScriptMessage class]);
    
    // Mock CleverTap class methods
    self.mockCleverTap = OCMClassMock([CleverTap class]);
    OCMStub([self.mockCleverTap sharedInstance]).andReturn(self.mockCleverTap);
    OCMStub([self.mockCleverTap instanceWithConfig:[OCMArg any]]).andReturn(self.mockCleverTap);
}

- (void)tearDown {
    [self.mockConfig stopMocking];
    [self.mockCleverTap stopMocking];
    [self.mockController stopMocking];
    [self.mockUserContentController stopMocking];
    [self.mockScriptMessage stopMocking];
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInitWithConfig {
    // Given
    OCMStub([self.mockConfig isDefaultInstance]).andReturn(NO);
    
    // When
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    
    // Then
    XCTAssertNotNil(self.jsInterface);
    XCTAssertEqual(self.jsInterface.config, self.mockConfig);
    XCTAssertTrue(self.jsInterface.wv_init);
}

- (void)testInitWithConfigForInApps {
    // When
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfigForInApps:self.mockConfig fromController:self.mockController];
    
    // Then
    XCTAssertNotNil(self.jsInterface);
    XCTAssertEqual(self.jsInterface.config, self.mockConfig);
    XCTAssertEqual(self.jsInterface.controller, self.mockController);
    XCTAssertFalse(self.jsInterface.wv_init); // Should be NO for in-app initialization
}

#pragma mark - Version Script Tests

- (void)testVersionScript {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    
    // When
    WKUserScript *script = [self.jsInterface versionScript];
    
    // Then
    XCTAssertNotNil(script);
    XCTAssertTrue([script.source containsString:@"window.cleverTapIOSSDKVersion"]);
    XCTAssertEqual(script.injectionTime, WKUserScriptInjectionTimeAtDocumentStart);
    XCTAssertTrue(script.isForMainFrameOnly);
}

#pragma mark - Message Handling Tests

- (void)testUserContentControllerWithValidDictionaryMessage {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *messageBody = @{@"action": @"recordEventWithProps", @"event": @"test_event"};
    
    OCMStub([self.mockScriptMessage body]).andReturn(messageBody);
    OCMStub([self.mockConfig isDefaultInstance]).andReturn(YES);
    
    // When
    [self.jsInterface userContentController:self.mockUserContentController didReceiveScriptMessage:self.mockScriptMessage];
    
    // Then
    OCMVerify([self.mockCleverTap sharedInstance]);
}

- (void)testUserContentControllerWithNonDictionaryMessage {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSString *messageBody = @"invalid_message";
    
    OCMStub([self.mockScriptMessage body]).andReturn(messageBody);
    
    // When
    [self.jsInterface userContentController:self.mockUserContentController didReceiveScriptMessage:self.mockScriptMessage];
    
    // Then
    OCMVerify(never(), [self.mockCleverTap sharedInstance]);
}

- (void)testUserContentControllerWithDefaultInstance {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *messageBody = @{@"action": @"recordEventWithProps"};
    
    OCMStub([self.mockScriptMessage body]).andReturn(messageBody);
    OCMStub([self.mockConfig isDefaultInstance]).andReturn(YES);
    
    // When
    [self.jsInterface userContentController:self.mockUserContentController didReceiveScriptMessage:self.mockScriptMessage];
    
    // Then
    OCMVerify([self.mockCleverTap sharedInstance]);
}

- (void)testUserContentControllerWithCustomInstance {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *messageBody = @{@"action": @"recordEventWithProps"};
    
    OCMStub([self.mockScriptMessage body]).andReturn(messageBody);
    OCMStub([self.mockConfig isDefaultInstance]).andReturn(NO);
    
    // When
    [self.jsInterface userContentController:self.mockUserContentController didReceiveScriptMessage:self.mockScriptMessage];
    
    // Then
    OCMVerify([self.mockCleverTap instanceWithConfig:self.mockConfig]);
}

#pragma mark - Action Handling Tests

- (void)testRecordEventWithProps {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"recordEventWithProps",
        @"event": @"test_event",
        @"properties": @{@"key": @"value"}
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap recordEvent:@"test_event" withProps:@{@"key": @"value"}]);
}

- (void)testProfilePush {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"profilePush",
        @"properties": @{@"name": @"John Doe"}
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profilePush:@{@"name": @"John Doe"}]);
}

- (void)testProfileSetMultiValues {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSArray *values = @[@"value1", @"value2"];
    NSDictionary *message = @{
        @"action": @"profileSetMultiValues",
        @"values": values,
        @"key": @"interests"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileSetMultiValues:values forKey:@"interests"]);
    
}

- (void)testProfileAddMultiValue {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"profileAddMultiValue",
        @"value": @"new_interest",
        @"key": @"interests"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileAddMultiValue:@"new_interest" forKey:@"interests"]);
}

- (void)testProfileAddMultiValues {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSArray *values = @[@"interest1", @"interest2"];
    NSDictionary *message = @{
        @"action": @"profileAddMultiValues",
        @"values": values,
        @"key": @"interests"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileAddMultiValues:values forKey:@"interests"]);
}

- (void)testProfileRemoveValueForKey {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"profileRemoveValueForKey",
        @"key": @"old_property"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileRemoveValueForKey:@"old_property"]);
}

- (void)testProfileRemoveMultiValue {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"profileRemoveMultiValue",
        @"value": @"unwanted_interest",
        @"key": @"interests"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileRemoveMultiValue:@"unwanted_interest" forKey:@"interests"]);
}

- (void)testProfileRemoveMultiValues {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSArray *values = @[@"interest1", @"interest2"];
    NSDictionary *message = @{
        @"action": @"profileRemoveMultiValues",
        @"values": values,
        @"key": @"interests"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileRemoveMultiValues:values forKey:@"interests"]);
}

- (void)testRecordChargedEvent {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"recordChargedEvent",
        @"chargeDetails": @{@"Amount": @100},
        @"items": @[@{@"Product": @"Book"}]
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap recordChargedEventWithDetails:@{@"Amount": @100} andItems:@[@{@"Product": @"Book"}]]);
}

- (void)testOnUserLogin {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"onUserLogin",
        @"properties": @{@"Identity": @"user123"}
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap onUserLogin:@{@"Identity": @"user123"}]);
}

- (void)testProfileIncrementValueBy {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"profileIncrementValueBy",
        @"value": @5,
        @"key": @"score"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileIncrementValueBy:@5 forKey:@"score"]);
}

- (void)testProfileDecrementValueBy {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"profileDecrementValueBy",
        @"value": @3,
        @"key": @"lives"
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap profileDecrementValueBy:@3 forKey:@"lives"]);
}

- (void)testDismissInAppNotification {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfigForInApps:self.mockConfig fromController:self.mockController];
    NSDictionary *message = @{@"action": @"dismissInAppNotification"};
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockController hide:YES]);
}

- (void)testPromptForPushPermissionWithController {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfigForInApps:self.mockConfig fromController:self.mockController];
    NSDictionary *message = @{
        @"action": @"promptForPushPermission",
        @"showFallbackSettings": @YES
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockController hide:NO]);
    OCMVerify([self.mockCleverTap promptForPushPermission:@YES]);
}

- (void)testPromptForPushPermissionWithoutController {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{
        @"action": @"promptForPushPermission",
        @"showFallbackSettings": @NO
    };
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then
    OCMVerify([self.mockCleverTap promptForPushPermission:@NO]);
}

#pragma mark - In-App Action Tests

- (void)testTriggerInAppActionWithValidAction {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfigForInApps:self.mockConfig fromController:self.mockController];
    
    NSDictionary *actionJson = @{@"type": @"url", @"url": @"https://example.com"};
    NSString *callToAction = @"Learn More";
    NSString *buttonId = @"button1";
    
    id mockAction = OCMClassMock([CTNotificationAction class]);
    OCMStub([mockAction alloc]).andReturn(mockAction);
    OCMStub([mockAction initWithJSON:actionJson]).andReturn(mockAction);
    OCMStub([mockAction error]).andReturn(nil);
    
    // When
    [self.jsInterface triggerInAppAction:actionJson callToAction:callToAction buttonId:buttonId];
    
    // Then
    OCMVerify([self.mockController triggerInAppAction:mockAction callToAction:callToAction buttonId:buttonId]);
    
    [mockAction stopMocking];
}

- (void)testTriggerInAppActionWithNilActionJson {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfigForInApps:self.mockConfig fromController:self.mockController];
    
    // When
    [self.jsInterface triggerInAppAction:nil callToAction:@"Learn More" buttonId:@"button1"];
    
    // Then
    OCMVerify(never(), [self.mockController triggerInAppAction:[OCMArg any] callToAction:[OCMArg any] buttonId:[OCMArg any]]);
}

- (void)testTriggerInAppActionWithNilController {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *actionJson = @{@"type": @"url", @"url": @"https://example.com"};
    
    // When
    [self.jsInterface triggerInAppAction:actionJson callToAction:@"Learn More" buttonId:@"button1"];
    
    // Then - Should not crash and should not call controller methods
}

- (void)testTriggerInAppActionWithNSNullValues {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfigForInApps:self.mockConfig fromController:self.mockController];
    
    NSDictionary *actionJson = @{@"type": @"url", @"url": @"https://example.com"};
    
    id mockAction = OCMClassMock([CTNotificationAction class]);
    OCMStub([mockAction alloc]).andReturn(mockAction);
    OCMStub([mockAction initWithJSON:actionJson]).andReturn(mockAction);
    OCMStub([mockAction error]).andReturn(nil);
    
    // When
    [self.jsInterface triggerInAppAction:actionJson callToAction:(NSString *)[NSNull null] buttonId:(NSString *)[NSNull null]];
    
    // Then
    OCMVerify([self.mockController triggerInAppAction:mockAction callToAction:nil buttonId:nil]);
    
    [mockAction stopMocking];
}

- (void)testTriggerInAppActionWithActionError {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfigForInApps:self.mockConfig fromController:self.mockController];
    
    NSDictionary *actionJson = @{@"invalid": @"data"};
    NSError *error = [NSError errorWithDomain:@"TestDomain" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Invalid action"}];
    
    id mockAction = OCMClassMock([CTNotificationAction class]);
    OCMStub([mockAction alloc]).andReturn(mockAction);
    OCMStub([mockAction initWithJSON:actionJson]).andReturn(mockAction);
    OCMStub([mockAction error]).andReturn(error);
    
    // When
    [self.jsInterface triggerInAppAction:actionJson callToAction:@"Learn More" buttonId:@"button1"];
    
    // Then
    OCMVerify(never(), [self.mockController triggerInAppAction:[OCMArg any] callToAction:[OCMArg any] buttonId:[OCMArg any]]);
    
    [mockAction stopMocking];
}

#pragma mark - Unknown Action Tests

- (void)testHandleUnknownAction {
    // Given
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.mockConfig];
    NSDictionary *message = @{@"action": @"unknownAction"};
    
    // When
    [self.jsInterface handleMessageFromWebview:message forInstance:self.mockCleverTap];
    
    // Then - Should not crash and should not call any CleverTap methods
    OCMVerify(never(), [self.mockCleverTap recordEvent:[OCMArg any] withProps:[OCMArg any]]);
    OCMVerify(never(), [self.mockCleverTap profilePush:[OCMArg any]]);
}

@end
