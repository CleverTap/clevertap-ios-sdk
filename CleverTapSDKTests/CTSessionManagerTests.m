//
//  CTSessionManagerTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 16/10/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTSessionManager.h"
#import "CTSessionManager+Tests.h"
#import "CleverTapInternal.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CTUIUtils.h"
#import <OCMock/OCMock.h>

@interface CTSessionManagerTests : XCTestCase
@property (nonatomic, strong) CTSessionManager *classObject;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CleverTap *instance;
@end

@implementation CTSessionManagerTests

- (void)setUp {
    id utils = OCMClassMock([CTUIUtils class]);
    OCMStub([utils runningInsideAppExtension]).andReturn(NO);
    
    _config = [[CleverTapInstanceConfig alloc]initWithAccountId:@"test" accountToken:@"test"];
    _instance = [CleverTap instanceWithConfig:_config];
    CTDelegateManager *delegateManager = [CTDelegateManager new];
    
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc] initWithAccountId:@"test" deviceId:@"test" delegateManager:delegateManager];
    CTInAppFCManager *inAppFCManager = [[CTInAppFCManager alloc] initWithConfig:_config delegateManager:[CTDelegateManager new] deviceId:@"test" impressionManager:impressionManager];
    CTInAppDisplayManager *displayManager = [[CTInAppDisplayManager alloc] initWithCleverTap:_instance dispatchQueueManager:[CTDispatchQueueManager new] inAppFCManager:inAppFCManager impressionManager:impressionManager];
//    CTInAppEvaluationManager *evaluationManager = [[CTInAppEvaluationManager alloc] initWithAccountId:@"test" deviceInfo:_instance.deviceInfo delegateManager:delegateManager impressionManager:impressionManager inAppDisplayManager:displayManager];
    
    
    _classObject = [[CTSessionManager alloc]initWithConfig:_config impressionManager:impressionManager inAppDisplayManager:displayManager];
}

- (void)tearDown {
    [_classObject resetSession];
    _classObject = nil;
    _config = nil;
    _instance = nil;
}

- (void)testSessionId {
    [_classObject createSession];
    XCTAssertGreaterThan(_classObject.sessionId, 0);
}

- (void)testSessionTime {
    [_classObject createSession];
    long lastSessionEnd = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLastSessionTime config: _config] withResetValue:0];
    XCTAssertGreaterThan(lastSessionEnd, 0);
}

- (void)testFirstRequestInSession {
    [_classObject createSession];
    XCTAssertTrue(_classObject.firstRequestInSession);
}

- (void)testScreenCount {
    int screenCount = _instance.sessionManager.screenCount;
    [_instance recordScreenView:@"test"];
    XCTAssertEqual(screenCount + 1, _instance.sessionManager.screenCount);
}

@end
