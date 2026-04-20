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

- (void)testResetSession_clearsSessionId {
    XCTAssertGreaterThan(_instance.sessionManager.sessionId, 0);
    [_instance.sessionManager resetSession];
    XCTAssertEqual(_instance.sessionManager.sessionId, 0);
}

- (void)testResetSession_setsScreenCountToOne {
    _instance.sessionManager.screenCount = 5;
    [_instance.sessionManager resetSession];
    XCTAssertEqual(_instance.sessionManager.screenCount, 1);
}

- (void)testResetSession_clearsSourceMediumCampaign {
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"install_referrer_status" config: self.config]];
    [_instance pushInstallReferrerSource:@"source" medium:@"medium" campaign:@"campaign"];
    XCTAssertNotNil(_instance.sessionManager.source);
    [_instance.sessionManager resetSession];
    XCTAssertNil(_instance.sessionManager.source);
    XCTAssertNil(_instance.sessionManager.medium);
    XCTAssertNil(_instance.sessionManager.campaign);
}

- (void)testSetSource_cannotBeOverriddenInSameSession {
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:@"install_referrer_status" config: self.config]];
    [_instance pushInstallReferrerSource:@"first" medium:@"m" campaign:@"c"];
    [_instance pushInstallReferrerSource:@"second" medium:@"m2" campaign:@"c2"];
    XCTAssertEqualObjects(_instance.sessionManager.source, @"first");
}

- (void)testCreateSessionIfNeeded_whenAlreadyInSession_keepsExistingSession {
    long existingId = _instance.sessionManager.sessionId;
    XCTAssertGreaterThan(existingId, 0);
    [_instance.sessionManager createSessionIfNeeded];
    XCTAssertEqual(_instance.sessionManager.sessionId, existingId);
}

- (void)testUpdateSessionTime_whenNotInSession_isNoOp {
    [_instance.sessionManager resetSession];
    XCTAssertEqual(_instance.sessionManager.sessionId, 0);
    // Should not crash and sessionId must remain 0
    [_instance.sessionManager updateSessionTime:12345];
    XCTAssertEqual(_instance.sessionManager.sessionId, 0);
}

@end
