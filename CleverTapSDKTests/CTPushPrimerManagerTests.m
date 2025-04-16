//
//  CTPushPrimerManagerTests.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 14/04/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTPushPrimerManagerMock.h"
#import "InAppHelper.h"

API_AVAILABLE(ios(10.0))
@interface CTPushPrimerManagerTests : XCTestCase

@property (nonatomic, strong) CTPushPrimerManagerMock *pushPrimerManager;
@property (nonatomic, strong) InAppHelper *helper;

@end

@implementation CTPushPrimerManagerTests

- (void)setUp {
    [super setUp];
    
    self.helper = [InAppHelper new];
    
    CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:self.helper.config];
    self.pushPrimerManager = [[CTPushPrimerManagerMock alloc] initWithConfig:self.helper.config
                                                         inAppDisplayManager:self.helper.inAppDisplayManager
                                                        dispatchQueueManager:queueManager];
}

- (void)tearDown {
    self.pushPrimerManager = nil;
    
    [super tearDown];
}

- (void)testPushPermissionStatusEnabledWhenAuthorized {
    self.pushPrimerManager.currentPushStatus = UNAuthorizationStatusAuthorized;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Push permission updated."];
    [self.pushPrimerManager checkAndUpdatePushPermissionStatusWithCompletion:^(CTPushPermissionStatus status) {
        XCTAssertEqual(status, CTPushEnabled);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testPushPermissionStatusNotEnabledWhenDenied {
    self.pushPrimerManager.currentPushStatus = UNAuthorizationStatusDenied;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Push permission updated."];
    [self.pushPrimerManager checkAndUpdatePushPermissionStatusWithCompletion:^(CTPushPermissionStatus status) {
        XCTAssertEqual(status, CTPushNotEnabled);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testPushPermissionStatusNotEnabledWhenNotDetermined {
    self.pushPrimerManager.currentPushStatus = UNAuthorizationStatusNotDetermined;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Push permission updated."];
    [self.pushPrimerManager checkAndUpdatePushPermissionStatusWithCompletion:^(CTPushPermissionStatus status) {
        XCTAssertEqual(status, CTPushNotEnabled);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
