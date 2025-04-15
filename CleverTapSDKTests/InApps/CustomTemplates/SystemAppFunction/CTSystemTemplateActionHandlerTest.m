//
//  CTSystemTemplateActionHandlerTest.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 15/04/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTSystemTemplateActionHandler.h"
#import "CTPushPrimerManagerMock.h"
#import "InAppHelper.h"

API_AVAILABLE(ios(10.0))
@interface CTSystemTemplateActionHandlerTest : XCTestCase

@property (nonatomic, strong) CTSystemTemplateActionHandler *actionHandler;
@property (nonatomic, strong) CTPushPrimerManagerMock *pushPrimerManager;
@property (nonatomic, strong) InAppHelper *helper;

@end

@implementation CTSystemTemplateActionHandlerTest

- (void)setUp {
    self.actionHandler = [[CTSystemTemplateActionHandler alloc] init];
    
    self.helper = [InAppHelper new];
    CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:self.helper.config];
    self.pushPrimerManager = [[CTPushPrimerManagerMock alloc] initWithConfig:self.helper.config
                                                         inAppDisplayManager:self.helper.inAppDisplayManager
                                                        dispatchQueueManager:queueManager];
    [self.actionHandler setPushPrimerManager:self.pushPrimerManager];
}

- (void)tearDown {
    self.actionHandler = nil;

    [super tearDown];
}

- (void)testPromptPushPermissionNotPresentedWhenPushEnabled {
    self.pushPrimerManager.currentPushStatus = UNAuthorizationStatusAuthorized;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prompt push permission completed."];
    [self.pushPrimerManager checkAndUpdatePushPermissionStatusWithCompletion:^(CTPushPermissionStatus status) {
        self.pushPrimerManager.pushPermissionStatus = status;
        
        [self.actionHandler promptPushPermission:YES withCompletionBlock:^(BOOL presented) {
            XCTAssertEqual(presented, NO);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleOpenUrlSuccess {
    NSString *action = @"https://clevertap.com";
    BOOL success = [self.actionHandler handleOpenURL:action];
    XCTAssertTrue(success);
}

- (void)testHandleOpenUrlNotSuccess {
    NSString *action = @"";
    BOOL success = [self.actionHandler handleOpenURL:action];
    XCTAssertFalse(success);
    
    action = @"htt!!ps://clevertap.com";
    success = [self.actionHandler handleOpenURL:action];
    XCTAssertFalse(success);
}

@end
