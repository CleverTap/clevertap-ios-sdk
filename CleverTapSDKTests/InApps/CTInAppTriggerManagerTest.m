//
//  CTInAppTriggerManagerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 3.01.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTInAppTriggerManager.h"
#import "CTMultiDelegateManager+Tests.h"
#import "InAppHelper.h"

@interface CTInAppTriggerManagerTest : XCTestCase

@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;
@property (nonatomic, strong) NSString *testCampaignId;

@end

// NOTE: Main functionality of persisting triggers is tested
// as part of the limits matcher
@implementation CTInAppTriggerManagerTest

- (void)setUp {
    [super setUp];
    self.testCampaignId = CLTAP_TEST_CAMPAIGN_ID;

    CTMultiDelegateManager *delegateManager = [[CTMultiDelegateManager alloc] init];
    
    self.triggerManager = [[CTInAppTriggerManager alloc] initWithAccountId:CLTAP_TEST_ACCOUNT_ID deviceId:CLTAP_TEST_DEVICE_ID delegateManager:delegateManager];
}

- (void)tearDown {
    [super tearDown];
    [self.triggerManager removeTriggers:self.testCampaignId];
}

- (void)testSwitchUserDelegateAdded {
    CTMultiDelegateManager *delegateManager = [[CTMultiDelegateManager alloc] init];
    NSUInteger count = [[delegateManager switchUserDelegates] count];
    
    self.triggerManager = [[CTInAppTriggerManager alloc] initWithAccountId:CLTAP_TEST_ACCOUNT_ID deviceId:CLTAP_TEST_DEVICE_ID delegateManager:delegateManager];
    
    XCTAssertEqual([[delegateManager switchUserDelegates] count], count + 1);
}

- (void)testSwitchUser {
    NSString *firstDeviceId = CLTAP_TEST_DEVICE_ID;
    NSString *secondDeviceId = [NSString stringWithFormat:@"%@_2", firstDeviceId];
    
    // Record triggers for first user
    [self.triggerManager incrementTrigger:self.testCampaignId];
    [self.triggerManager incrementTrigger:self.testCampaignId];
    XCTAssertEqual([self.triggerManager getTriggers:self.testCampaignId], 2);

    // Switch to second user and record impressions
    [self.triggerManager deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([self.triggerManager getTriggers:self.testCampaignId], 0);
    [self.triggerManager incrementTrigger:self.testCampaignId];
    XCTAssertEqual([self.triggerManager getTriggers:self.testCampaignId], 1);

    // Switch to first user to ensure cached impressions for first user are loaded
    [self.triggerManager deviceIdDidChange:firstDeviceId];
    XCTAssertEqual([self.triggerManager getTriggers:self.testCampaignId], 2);

    // Switch to second user to ensure cached impressions for second user are loaded
    [self.triggerManager deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([self.triggerManager getTriggers:self.testCampaignId], 1);

    // Clear in-apps for the second user
    [self.triggerManager removeTriggers:self.testCampaignId];
    // Switch back to first user to tear down
    [self.triggerManager deviceIdDidChange:firstDeviceId];
}

@end
