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

@interface CTLimitsMatcherTest : XCTestCase
@property (nonatomic, strong) CTLimitsMatcher *limitsMatcher;
@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppTriggerManager *inAppTriggerManager;
@property (nonatomic, strong) NSString *testCampaignId;
@end

@implementation CTLimitsMatcherTest

- (void)setUp {
    [super setUp];
    self.testCampaignId = @"testCampaignId";
    self.limitsMatcher = [[CTLimitsMatcher alloc] init];
    self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:@"testAccountId" deviceId:@"testDeviceId" delegateManager:[CTDelegateManager new]];
    self.inAppTriggerManager = [[CTInAppTriggerManager alloc]initWithAccountId:@"testAccountId" deviceId:@"testDeviceId"];
}

- (void)tearDown {
    [super tearDown];
    [self.inAppTriggerManager removeTriggers:self.testCampaignId];
    [self.impressionManager removeImpressions:self.testCampaignId];
    
    
    
    [self removeAllKeysWithPrefix:[NSUserDefaults standardUserDefaults] withPrefix:@"WizRockettestAccountId_testDeviceId_impressions"];
    [self removeAllKeysWithPrefix:[NSUserDefaults standardUserDefaults] withPrefix:@"WizRockettestAccountId_testDeviceId_triggers"];
}

- (void)removeAllKeysWithPrefix:(NSUserDefaults *)userDefaults withPrefix:(NSString *)prefix {
    NSDictionary *userDefaultsDictionary = [userDefaults dictionaryRepresentation];
    for (NSString *key in userDefaultsDictionary) {
        if ([key hasPrefix:prefix]) {
            [userDefaults removeObjectForKey:key];
        }
    }
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

@end
