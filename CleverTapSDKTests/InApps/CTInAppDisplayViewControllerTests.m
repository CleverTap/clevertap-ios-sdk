//
//  CTInAppDisplayViewControllerTests.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 18/11/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTInAppDisplayViewController.h"
#import "CTInAppNotificationDisplayDelegateMock.h"

@interface CTInAppDisplayViewControllerTests : XCTestCase

@property (nonatomic, strong) CTInAppDisplayViewController *viewController;
@property (nonatomic, strong) CTInAppNotification *inAppNotification;

@end

@implementation CTInAppDisplayViewControllerTests

- (void)setUp {
    [super setUp];
    
    NSDictionary *inApp = @{
        @"ti": @1
    };
    self.inAppNotification = [[CTInAppNotification alloc] initWithJSON:inApp];
    self.viewController = [[CTInAppDisplayViewController alloc] initWithNotification:self.inAppNotification];
}

- (void)tearDown {
    self.viewController = nil;

    [super tearDown];
}

#pragma mark triggerInAppAction Tests

- (void)testAddURLParamsOnly {
    // triggerAction should add url parameters only in extras dictionary
    // if callToAction and buttonId is not present.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?param1=value1&param2=value2"];
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"param1": @"value1",
        @"param2": @"value2"
    };
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    id mockViewController = OCMPartialMock(self.viewController);
    OCMExpect([mockViewController hide:YES]);

    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:nil buttonId:nil];
    OCMVerifyAll(mockViewController);
}

- (void)testAddURLParamsAlongWithC2A {
    // triggerAction should add url parameters along with callToAction and buttonId
    // in extras dictionary.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?param1=value1&param2=value2"];
    NSString *callToAction = @"Test CTA";
    NSString *buttonId = @"button1";
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"wzrk_c2a": callToAction,
        @"button_id": buttonId,
        @"param1": @"value1",
        @"param2": @"value2"
    };
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    id mockViewController = OCMPartialMock(self.viewController);
    OCMExpect([mockViewController hide:YES]);

    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
    OCMVerifyAll(mockViewController);
}

- (void)testC2AParamsParseFromDL {
    // triggerAction should parse c2a url params with __dl__ data
    // when callToAction is not provided.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?wzrk_c2a=c2aParam__dl__https%3A%2F%2Fdeeplink.com%3Fparam1%3Dasd%26param2%3Dvalue2&asd=value"];
    NSString *buttonId = @"button1";
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"wzrk_c2a": @"c2aParam",
        @"button_id": buttonId,
        @"asd": @"value"
    };
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    id mockViewController = OCMPartialMock(self.viewController);
    OCMExpect([mockViewController hide:YES]);

    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:nil buttonId:buttonId];
    OCMVerifyAll(mockViewController);
}

- (void)testC2AParamsDoesNotParseFromDL {
    // triggerAction does not parse c2a url params with __dl__ data when callToAction
    // is provided, wzrk_c2a should have callToAction value only if provided.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?wzrk_c2a=c2aParam__dl__https%3A%2F%2Fdeeplink.com%3Fparam1%3Dasd%26param2%3Dvalue2&asd=value"];
    NSString *callToAction = @"Test CTA";
    NSString *buttonId = @"button1";
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"wzrk_c2a": callToAction,
        @"button_id": buttonId,
        @"asd": @"value"
    };
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    id mockViewController = OCMPartialMock(self.viewController);
    OCMExpect([mockViewController hide:YES]);

    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
    OCMVerifyAll(mockViewController);
}

- (void)testActionURLWhenDLDataPresent {
    // triggerAction should open deeplink url if __dl__ data is present.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?wzrk_c2a=c2aParam__dl__https%3A%2F%2Fdeeplink.com%3Fparam1%3Dasd%26param2%3Dvalue2&asd=value"];
    NSString *callToAction = @"Test CTA";
    NSString *buttonId = @"button1";
    NSURL *expectedURL = [NSURL URLWithString:@"https://deeplink.com?param1=asd&param2=value2"];
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(action.actionURL, expectedURL);
    }];
    self.viewController.delegate = delegate;
    id mockViewController = OCMPartialMock(self.viewController);
    OCMExpect([mockViewController hide:YES]);

    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
    OCMVerifyAll(mockViewController);
}

- (void)testActionURLWhenDLDataNotPresent {
    // triggerAction should open original url if __dl__ data is not present.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?param1=value1&param2=value2"];
    NSString *callToAction = @"Test CTA";
    NSString *buttonId = @"button1";
    NSURL *expectedURL = url;
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(action.actionURL, expectedURL);
    }];
    self.viewController.delegate = delegate;
    id mockViewController = OCMPartialMock(self.viewController);
    OCMExpect([mockViewController hide:YES]);

    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
    OCMVerifyAll(mockViewController);
}

@end
