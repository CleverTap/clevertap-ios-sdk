//
//  CTLimitsMatcherTest.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 15/09/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTLimitsMatcher.h"
#import "CTInAppTriggerManager.h"
#import "CTClockMock.h"
#import "InAppHelper.h"

@interface CTLimitsMatcherTest : XCTestCase

@property (nonatomic, strong) CTLimitsMatcher *limitsMatcher;
@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppTriggerManager *inAppTriggerManager;
@property (nonatomic, strong) CTClockMock *mockClock;
@property (nonatomic, strong) NSString *testCampaignId;

@end

@implementation CTLimitsMatcherTest

- (void)setUp {
    [super setUp];
    InAppHelper *helper = [InAppHelper new];
    self.testCampaignId = [helper campaignId];
    self.limitsMatcher = [[CTLimitsMatcher alloc] init];
    CTClockMock *mockClock = [[CTClockMock alloc] initWithCurrentDate:[NSDate date]];
    self.mockClock = mockClock;
    self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:helper.accountId deviceId:helper.deviceId
                                                            delegateManager:helper.delegateManager
                                                                      clock:mockClock locale:[NSLocale currentLocale]];
    self.inAppTriggerManager = helper.inAppTriggerManager;
}

- (void)tearDown {
    [super tearDown];
    [self.inAppTriggerManager removeTriggers:self.testCampaignId];
    [self.impressionManager removeImpressions:self.testCampaignId];
}

- (void)testMatchOnExactlyLessThanLimit {
    NSArray *whenLimits = @[
        @{
            @"type": @"onExactly",
            @"limit": @6
        }
    ];
    
    [self.inAppTriggerManager incrementTrigger:self.testCampaignId];
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchOnExactly {
    NSArray *whenLimits = @[
        @{
            @"type": @"onExactly",
            @"limit": @6
        }
    ];
    
    for (int i = 0; i < 6; i++) {
        [self.inAppTriggerManager incrementTrigger:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits
                                       forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager
                                   andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchOnEvery {
    NSArray *whenLimits = @[
        @{
            @"type": @"onEvery",
            @"limit": @6
        }
    ];
    
    for (int i = 0; i < 12; i++) {
        [self.inAppTriggerManager incrementTrigger:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchOnEveryIntermediate {
    NSArray *whenLimits = @[
        @{
            @"type": @"onEvery",
            @"limit": @6
        }
    ];
    
    for (int i = 0; i < 2; i++) {
        [self.inAppTriggerManager incrementTrigger:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchEver {
    NSArray *whenLimits = @[
        @{
            @"type": @"ever",
            @"limit": @6
        }
    ];
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchEverLimitExceeded {
    NSArray *whenLimits = @[
        @{
            @"type": @"ever",
            @"limit": @6
        }
    ];
    
    for (int i = 0; i < 7; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchSession {
    NSArray *whenLimits = @[
        @{
            @"type": @"session",
            @"limit": @6
        }
    ];
    
    [self.impressionManager recordImpression:self.testCampaignId];
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchSessionLimitExceeded {
    NSArray *whenLimits = @[
        @{
            @"type": @"session",
            @"limit": @6
        }
    ];
    
    for (int i = 0; i < 7; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchSeconds {
    NSArray *whenLimits = @[
        @{
            @"type": @"seconds",
            @"limit": @6,
            @"frequency": @12
        }
    ];
    
    for (int i = 0; i < 2; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertTrue(match);
}

- (void)testMatchSecondsLimitExceeded {
    NSArray *whenLimits = @[
        @{
            @"type": @"seconds",
            @"limit": @6,
            @"frequency": @12
        }
    ];

    for (int i = 0; i < 7; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    
    XCTAssertFalse(match);
}

- (void)testMatchMinutes {
    NSArray *whenLimits = @[
        @{
            @"type": @"minutes",
            @"limit": @3,
            @"frequency": @10
        }
    ];
    
    for (int i = 0; i < 2; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertFalse(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60 + 1];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
}

- (void)testMatchHours {
    NSArray *whenLimits = @[
        @{
            @"type": @"hours",
            @"limit": @3,
            @"frequency": @2
        }
    ];

    for (int i = 0; i < 2; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:1 * 60 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertFalse(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:1 * 60 * 60 + 1];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
}

- (void)testMatchDays {
    NSArray *whenLimits = @[
        @{
            @"type": @"days",
            @"limit": @3,
            @"frequency": @2
        }
    ];

    for (int i = 0; i < 2; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:24 * 60 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertFalse(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:24 * 60 * 60 + 1];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
}

- (void)testMatchWeeks {
    NSArray *whenLimits = @[
        @{
            @"type": @"weeks",
            @"limit": @3,
            @"frequency": @2
        }
    ];

    for (int i = 0; i < 2; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:7 * 24 * 60 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertFalse(match);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:7 * 24 * 60 * 60 + 1];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
}

- (void)testMatchMultiple {
    NSArray *whenLimits = @[
        @{
            @"type": @"onExactly",
            @"limit": @1
        },
        @{
            @"type": @"days",
            @"limit": @3,
            @"frequency": @1
        },
        @{
            @"type": @"session",
            @"limit": @6
        }
    ];
    
    [self.inAppTriggerManager incrementTrigger:self.testCampaignId];
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    for (int i = 0; i < 2; i++) {
        [self.impressionManager recordImpression:self.testCampaignId];
    }
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    // Impressions per day no longer match
    [self.impressionManager recordImpression:self.testCampaignId];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertFalse(match);
    
    // Reset impressions and increment trigger, so it will not match
    [self.impressionManager removeImpressions:self.testCampaignId];
    [self.inAppTriggerManager incrementTrigger:self.testCampaignId];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertFalse(match);
}

- (void)testMatchEmpty {
    NSArray *whenLimits = @[
        @{
        }
    ];
    BOOL match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    whenLimits = @[
    ];
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
    
    whenLimits = nil;
    match = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:self.testCampaignId withImpressionManager:self.impressionManager andTriggerManager:self.inAppTriggerManager];
    XCTAssertTrue(match);
}

@end
