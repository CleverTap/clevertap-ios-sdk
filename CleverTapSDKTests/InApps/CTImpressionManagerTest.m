//
//  CTImpressionManagerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 27.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTImpressionManager.h"
#import "CTDelegateManager.h"

@interface CTImpressionManager(Tests)
- (NSInteger)getImpressionCount:(NSString *)campaignId;
@end

@interface CTImpressionManagerTest : XCTestCase

@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) NSString *testCampaignId;

@end

@implementation CTImpressionManagerTest

- (void)setUp {
    [super setUp];
    self.testCampaignId = @"testCampaignId";
    // Initialize the CTDelegateManager for testing
    CTDelegateManager *delegateManager = [[CTDelegateManager alloc] init];
    self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:@"testAccountID"
                                                                   deviceId:@"testDeviceID"
                                                            delegateManager:delegateManager];
}

- (void)tearDown {
    [super tearDown];
    [self.impressionManager removeImpressions:self.testCampaignId];
}

- (void)testRecordImpression {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    XCTAssertEqual([self.impressionManager perSessionTotal], 1, @"Impression count should be 1 after recording an impression");
    XCTAssertEqual([self.impressionManager perSession:self.testCampaignId], 1, @"Impression count for the specific campaign should be 1");
}

- (void)testImpressionCountMethods {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    XCTAssertEqual([self.impressionManager perSecond:self.testCampaignId seconds:1], 1, @"Impression count per second should be 1");
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:1], 1, @"Impression count per minute should be 1");
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:1], 1, @"Impression count per hour should be 1");
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 1, @"Impression count per day should be 1");
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 1, @"Impression count per week should be 1");
}

- (void)testImpressionStorage {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 1, @"Impression count should be 1 after recording an impression");
    
    [self.impressionManager removeImpressions:self.testCampaignId];
    
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 0, @"Impression count should be 0 after removing impressions");
}

@end
