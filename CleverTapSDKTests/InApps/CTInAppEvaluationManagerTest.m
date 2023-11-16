//
//  CTInAppEvaluationManager.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 18.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTInAppEvaluationManager.h"
#import "CTEventAdapter.h"
#import "BaseTestCase.h"
#import "CleverTap+Tests.h"
#import "CleverTapInternal.h"
#import "CTInAppTriggerManager.h"
#import "CTMultiDelegateManager.h"
#import "InAppHelper.h"
#import "CTConstants.h"

@interface CTInAppEvaluationManager(Test)
@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInApps;
- (void)sortByPriority:(NSMutableArray *)inApps;
- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps;
- (BOOL)shouldSuppress:(NSDictionary *)inApp;
- (void)suppress:(NSDictionary *)inApp;
- (NSString *)generateWzrkId:(NSString *)ti;
- (void)updateTTL:(NSMutableDictionary *)inApp;
@end

@interface CTInAppEvaluationManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppEvaluationManager *evaluationManager;
@end

@implementation CTInAppEvaluationManagerTest

- (void)setUp {
    [super setUp];
    
    InAppHelper *helper = [InAppHelper new];
    self.evaluationManager = helper.inAppEvaluationManager;
}

- (void)tearDown {
    // Clean up resources if needed
    //self.evaluationManager = nil;
    for (int i = 1; i <= 3; i++) {
        [self.evaluationManager.triggerManager removeTriggers:[NSString stringWithFormat:@"%d", i]];
    }
    [super tearDown];
}

- (void)testSort {
    NSMutableArray *inApps = [@[
        @{
            @"ti": @1665140111,
            @"priority": @1
        },
        @{
            @"ti": @1665140999,
            @"priority": @1
        },
        @{
            @"ti": @1665141999,
            @"priority": @100
        },
        @{
            @"ti": @1665140050,
            @"priority": @50
        }] mutableCopy];
    
    NSArray *expectedInApps = @[
        @{
            @"ti": @1665141999,
            @"priority": @100
        },
        @{
            @"ti": @1665140050,
            @"priority": @50
        },
        @{
            @"ti": @1665140111,
            @"priority": @1
        },
        @{
            @"ti": @1665140999,
            @"priority": @1
        }
    ];
    
    [self.evaluationManager sortByPriority:inApps];
    
    XCTAssertEqualObjects(inApps, expectedInApps);
}

- (void)testSortNoPriority {
    NSMutableArray *inApps = [@[
        @{
            @"ti": @1665140111
        },
        @{
            @"ti": @1665140999
        },
        @{
            @"ti": @1665141999,
            @"priority": @2
        }] mutableCopy];
    
    NSArray *expectedInApps = @[
        @{
            @"ti": @1665141999,
            @"priority": @2
        },
        @{
            @"ti": @1665140111
        },
        @{
            @"ti": @1665140999
        }
    ];
    
    [self.evaluationManager sortByPriority:inApps];
    XCTAssertEqualObjects(inApps, expectedInApps);
}

- (void)testSortNoTimestamp {
    NSMutableArray *inApps = [@[
        @{
        },
        @{
            @"priority": @2
        },
        @{
            @"ti": @1665140999
        }] mutableCopy];
    
    NSArray *expectedInApps = @[
        @{
            @"priority": @2
        },
        @{
            @"ti": @1665140999
        },
        @{
        }
    ];
    
    [self.evaluationManager sortByPriority:inApps];
    XCTAssertEqualObjects(inApps, expectedInApps);
}

- (void)testSortInvalidAndStringTimestamp {
    NSMutableArray *inApps = [@[
        @{
            @"priority": @2
        },
        @{
            @"priority": @2,
            @"ti": @"asd"
        },
        @{
            @"priority": @2,
            @"ti": @1699900999
        },
        @{
            @"priority": @2,
            @"ti": @"1699900111"
        }] mutableCopy];
    
    NSArray *expectedInApps = @[
        @{
            @"priority": @2,
            @"ti": @"1699900111"
        },
        @{
            @"priority": @2,
            @"ti": @1699900999
        },
        @{
            @"priority": @2,
        },
        @{
            @"priority": @2,
            @"ti": @"asd"
        }
    ];
    
    [self.evaluationManager sortByPriority:inApps];
    XCTAssertEqualObjects(inApps, expectedInApps);
}

- (void)testEvaluateWithInApps {
    NSArray *inApps = @[
        @{
            @"ti": @"1",
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event1",
                @"eventProperties": @[
                    @{
                        @"propertyName": @"key",
                        @"operator": @1,
                        @"value": @"value"
                    }]
            }],
            @"frequencyLimits": @[
                @{
                    
                }
            ],
            @"occurrenceLimits": @[
                @{
                    
                }
            ]
        },
        @{
            @"ti": @"2",
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event1",
                @"eventProperties": @[
                    @{
                        @"propertyName": @"key",
                        @"operator": @1,
                        @"value": @"value"
                    }]
            }]
        },
        @{
            @"ti": @"3",
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event2"
            }]
        }
    ];
    
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:@"event1" eventProperties:@{ @"key": @"value" } andLocation:kCLLocationCoordinate2DInvalid];
    CTEventAdapter *event2 = [[CTEventAdapter alloc] initWithEventName:@"event2" eventProperties:@{} andLocation:kCLLocationCoordinate2DInvalid];
    
    XCTAssertEqualObjects([self.evaluationManager evaluate:event withInApps:inApps], (@[inApps[0], inApps[1]]));
    XCTAssertEqualObjects([self.evaluationManager evaluate:event2 withInApps:inApps], @[inApps[2]]);
    XCTAssertEqualObjects([self.evaluationManager evaluate:event withInApps:inApps], (@[inApps[0], inApps[1]]));
    
    XCTAssertEqual([self.evaluationManager.triggerManager getTriggers:@"1"], 2);
    XCTAssertEqual([self.evaluationManager.triggerManager getTriggers:@"2"], 2);
    XCTAssertEqual([self.evaluationManager.triggerManager getTriggers:@"3"], 1);
}

- (void)testShouldSuppress {
    NSDictionary *inApp = @{
        @"ti": @"1"
    };
    
    NSDictionary *suppressedInApp = @{
        @"ti": @"1",
        @"suppressed": @YES
    };
    
    NSDictionary *notSuppressedInApp = @{
        @"ti": @"1",
        @"suppressed": @NO
    };
    
    XCTAssertFalse([self.evaluationManager shouldSuppress:inApp]);
    XCTAssertTrue([self.evaluationManager shouldSuppress:suppressedInApp]);
    XCTAssertFalse([self.evaluationManager shouldSuppress:notSuppressedInApp]);
}

- (void)testSuppressInApp {
    NSDictionary *inApp = @{
        @"ti": @"1",
        @"wzrk_pivot": @"pivot",
        @"wzrk_cgId": @0
    };
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:CLTAP_DATE_FORMAT];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary *suppressedInAppData = @{
        @"wzrk_id": [NSString stringWithFormat:@"1_%@", date],
        @"wzrk_pivot": @"pivot",
        @"wzrk_cgId": @0
    };
    
    [self.evaluationManager suppress:inApp];
    XCTAssertEqual([self.evaluationManager.suppressedClientSideInApps count], 1);
    XCTAssertEqualObjects(self.evaluationManager.suppressedClientSideInApps[0], suppressedInAppData);
    
    NSDictionary *inAppNoPivotNoCG = @{
        @"ti": @"1"
    };
    
    suppressedInAppData = @{
        @"wzrk_id": [NSString stringWithFormat:@"1_%@", date],
        @"wzrk_pivot": @"wzrk_default"
    };
    
    [self.evaluationManager suppress:inAppNoPivotNoCG];
    XCTAssertEqualObjects(self.evaluationManager.suppressedClientSideInApps[1], suppressedInAppData);
}

- (void)testGenerateWzrkId {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:CLTAP_DATE_FORMAT];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    XCTAssertEqualObjects([self.evaluationManager generateWzrkId:@"1699900111"], ([NSString stringWithFormat:@"1699900111_%@", date]));
}

- (void)testUpdateTTL {
    NSUInteger offset = 24 * 60 *60;
    NSMutableDictionary *inApp = [@{
        @"ti": @"1",
        @"wzrk_ttl_offset": @(offset),
        @"wzrk_ttl": @1700172618
    } mutableCopy];
    
    NSInteger ttl = [[NSDate date] timeIntervalSince1970] + offset;
    NSMutableDictionary *inAppUpdated = [@{
        @"ti": @"1",
        @"wzrk_ttl_offset": @(offset),
        @"wzrk_ttl": [NSNumber numberWithLong:ttl]
    } mutableCopy];
    
    [self.evaluationManager updateTTL:inApp];
    XCTAssertEqualObjects(inAppUpdated, inApp);
    
    NSMutableDictionary *inAppNoTTL = [@{
        @"ti": @"1",
        @"wzrk_ttl_offset": @(offset)
    } mutableCopy];
    [self.evaluationManager updateTTL:inAppNoTTL];
    XCTAssertEqualObjects(inAppUpdated, inAppNoTTL);
    
    NSMutableDictionary *inAppNoOffset = [@{
        @"ti": @"1",
        @"wzrk_ttl": @1700172618
    } mutableCopy];
    [self.evaluationManager updateTTL:inAppNoOffset];
    XCTAssertEqualObjects(@{ @"ti": @"1" }, inAppNoOffset);
}

@end
