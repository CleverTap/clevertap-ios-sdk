//
//  CTLimitsMatcherTest.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 15/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTLimitsMatcher.h"

@interface CTLimitsMatcherTest : XCTestCase

@end

@implementation CTLimitsMatcherTest

- (void)testMatchOnExactlyLessThanLimit {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"onExactly",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    [impressionManager recordImpression:testCampaignId];
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchOnExactly {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"onExactly",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    
    for (int i = 0; i < 6; i++) {
        [impressionManager recordImpression:testCampaignId];
    }
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchOnEvery {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"onEvery",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    
    for (int i = 0; i < 12; i++) {
        [impressionManager recordImpression:testCampaignId];
    }
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchOnEveryIntermediate {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"onEvery",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    
    for (int i = 0; i < 2; i++) {
        [impressionManager recordImpression:testCampaignId];
    }
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchEver {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"ever",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchEverLimitExceeded {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"ever",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    
    for (int i = 0; i < 7; i++) {
        [impressionManager recordImpression:testCampaignId];
    }
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchSession {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"session",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    [impressionManager recordImpression:testCampaignId];
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchSessionLimitExceeded {
    
    NSArray *whenLimits = @[
        @{
            @"type": @"session",
            @"limit": @6
        }
    ];
    
    NSString *testCampaignId = @"testCampaignId";
    CTLimitsMatcher *limitMatcher = [[CTLimitsMatcher alloc] init];
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc]init];
    [impressionManager removeImpressions:testCampaignId];
    
    for (int i = 0; i < 7; i++) {
        [impressionManager recordImpression:testCampaignId];
    }
    
    BOOL match = [limitMatcher matchWhenLimits:whenLimits forCampaignId:testCampaignId withImpressionManager:impressionManager];
    
    XCTAssertFalse(match);
}

@end
