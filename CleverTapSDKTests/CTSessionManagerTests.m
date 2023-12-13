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
//@property (nonatomic, strong) CTSessionManager *classObject;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CleverTap *instance;
@end

@implementation CTSessionManagerTests

- (void)setUp {
    id utils = OCMClassMock([CTUIUtils class]);
    OCMStub([utils runningInsideAppExtension]).andReturn(NO);
    
    _config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"test" accountToken:@"test"];
    _instance = [CleverTap instanceWithConfig:_config];
    [_instance.sessionManager createSession];
}

- (void)tearDown {
    [_instance.sessionManager resetSession];
//    _classObject = nil;
    _config = nil;
    _instance = nil;
}

- (void)testSessionId {
    XCTAssertGreaterThan(_instance.sessionManager.sessionId, 0);
}

- (void)testSessionTime {
    long lastSessionEnd = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLastSessionTime config: _config] withResetValue:0];
    XCTAssertGreaterThan(lastSessionEnd, 0);
}

- (void)testFirstRequestInSession {
    XCTAssertTrue(_instance.sessionManager.firstRequestInSession);
}

- (void)testSourceMediumCampaign {
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"install_referrer_status" config: self.config]];
    [_instance pushInstallReferrerSource:@"source" medium:@"medium" campaign:@"campaign"];
    XCTAssertEqualObjects(_instance.sessionManager.source, @"source");
    XCTAssertEqualObjects(_instance.sessionManager.medium, @"medium");
    XCTAssertEqualObjects(_instance.sessionManager.campaign, @"campaign");
}

@end
