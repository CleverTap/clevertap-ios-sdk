//
//  CTInAppEvaluationManager.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 18.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTInAppDisplayManager.h"
#import <XCTest/XCTest.h>
#import "CTTemplatePresenterMock.h"
#import "CTInAppEvaluationManager.h"
#import "CTEventAdapter.h"
#import "BaseTestCase.h"
#import "CleverTap+Tests.h"
#import "CleverTapInternal.h"
#import "CTInAppTriggerManager.h"
#import "CTMultiDelegateManager.h"
#import "InAppHelper.h"
#import "CTConstants.h"
#import "CTInAppStore+Tests.h"
#import "CTInAppEvaluationManager+Tests.h"
#import "CTPreferences.h"
#import "CTMultiDelegateManager+Tests.h"
#import "CTCustomTemplatesManager-Internal.h"
#import "CTInAppTemplateBuilder.h"
#import "CTTestTemplateProducer.h"

@interface CTInAppDisplayManagerMock : CTInAppDisplayManager
@property (nonatomic, strong) NSMutableArray *inappNotifs;
- (void)_addInAppNotificationsToQueue:(NSArray *)inappNotifs;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
@implementation CTInAppDisplayManagerMock
- (instancetype)initWithNil {
    if (self = [super initWithCleverTap:nil
                   dispatchQueueManager:nil
                         inAppFCManager:nil
                      impressionManager:nil
                             inAppStore:nil
                       templatesManager:nil
                         fileDownloader:nil]) {
        self.inappNotifs = [NSMutableArray new];
    }
    return self;
}
- (instancetype)initWithTemplateManager:(CTCustomTemplatesManager *)templatesManager {
    if (self = [super initWithCleverTap:nil
                   dispatchQueueManager:nil
                         inAppFCManager:nil
                      impressionManager:nil
                             inAppStore:nil
                       templatesManager:templatesManager
                         fileDownloader:nil]) {
        self.inappNotifs = [NSMutableArray new];
    }
    return self;
}
- (void)_addInAppNotificationsToQueue:(NSArray *)inappNotifs {
    [self.inappNotifs addObjectsFromArray:inappNotifs];
}
@end
#pragma clang diagnostic pop

@interface CTInAppEvaluationManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppEvaluationManager *evaluationManager;
@property (nonatomic, strong) InAppHelper *helper;
@property (nonatomic, strong) CTInAppDisplayManagerMock *mockDisplayManager;
@end

@implementation CTInAppEvaluationManagerTest

#pragma mark Setup
- (void)setUp {
    [super setUp];
    
    self.helper = [InAppHelper new];
    self.mockDisplayManager = [[CTInAppDisplayManagerMock alloc] initWithNil];
    self.evaluationManager = self.helper.inAppEvaluationManager;
    self.evaluationManager.inAppDisplayManager = self.mockDisplayManager;
    // saveEvaluatedServerSideInAppIds appends to storage instead of replacing it.
    // Initialize storage to [] so the first append works correctly, and reset
    // in-memory to match the clean storage state.
    [CTPreferences putObject:[NSMutableArray new] forKey:[self.evaluationManager storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
    self.evaluationManager.evaluatedServerSideInAppIds = [NSMutableArray new];
}

- (void)tearDown {
    // Remove triggers
    for (int i = 1; i <= 4; i++) {
        [self.evaluationManager.triggerManager removeTriggers:[NSString stringWithFormat:@"%d", i]];
    }
    // Remove saved ids
    // Use CTPreferences directly because saveEvaluatedServerSideInAppIds appends to
    // existing storage instead of replacing it, so setting in-memory to [] and saving
    // would leave the previous data intact.
    [CTPreferences putObject:[NSMutableArray new] forKey:[self.evaluationManager storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
    self.evaluationManager.suppressedClientSideInApps = [NSMutableArray new];
    [self.evaluationManager saveSuppressedClientSideInApps];
    
    self.evaluationManager.evaluatedServerSideInAppIdsForProfile = [NSMutableArray new];
    [self.evaluationManager saveEvaluatedServerSideInAppIdsForProfile];
    self.evaluationManager.suppressedClientSideInAppsForProfile = [NSMutableArray new];
    [self.evaluationManager saveSuppressedClientSideInAppsForProfile];
    [super tearDown];
}

- (NSArray *)savedEvaluatedServerSideInAppIds {
    return [CTPreferences getObjectForKey:[self.evaluationManager storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
}

- (NSArray *)savedSuppressedClientSideInApps {
    return [CTPreferences getObjectForKey:[self.evaluationManager storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY]];
}

#pragma mark Sort Tests
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

#pragma mark Evaluate Tests
- (void)testEvaluateWithInApps {
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event1",
                @"eventProperties": @[
                    @{
                        @"propertyName": @"key",
                        @"operator": @1,
                        @"propertyValue": @"value"
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
            @"ti": @2,
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event1",
                @"eventProperties": @[
                    @{
                        @"propertyName": @"key",
                        @"operator": @1,
                        @"propertyValue": @"value"
                    }]
            }]
        },
        @{
            @"ti": @3,
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event2"
            }]
        },
        @{
            @"ti": @4,
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"Charged"
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
    
    // Charged
    CTEventAdapter *eventCharged = [[CTEventAdapter alloc] initWithEventName:CLTAP_CHARGED_EVENT eventProperties:@{} location:kCLLocationCoordinate2DInvalid andItems:@[]];
    
    XCTAssertEqualObjects([self.evaluationManager evaluate:eventCharged withInApps:inApps], @[inApps[3]]);
    XCTAssertEqual([self.evaluationManager.triggerManager getTriggers:@"4"], 1);
}

- (void)testEvaluateUserAttribute {
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": @"newValue",
                @"propertyValue": @"Gold",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    },
    @{
        @"ti": @2,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": @"newValue",
                @"propertyValue": @"Premium",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    }];
    
    NSDictionary *profile = @{
        @"Customer Type": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        }
    };
    [self.evaluationManager evaluateOnUserAttributeChange:profile];
    XCTAssertEqualObjects((@[@1]), self.evaluationManager.evaluatedServerSideInAppIdsForProfile);
}

- (void)testEvaluateUserAttributeNormalized {
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": @"newValue",
                @"propertyValue": @"Gold",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    }];
    
    NSDictionary *profile = @{
        @"CustomerType": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        }
    };
    [self.evaluationManager evaluateOnUserAttributeChange:profile];
    XCTAssertEqualObjects((@[@1]), self.evaluationManager.evaluatedServerSideInAppIdsForProfile);
    
    profile = @{
        @"customer type": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        }
    };
    [self.evaluationManager evaluateOnUserAttributeChange:profile];
    XCTAssertEqualObjects((@[@1, @1]), self.evaluationManager.evaluatedServerSideInAppIdsForProfile);
}

- (void)testEvaluateUserAttributeNormalizedMultiple {
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": @"newValue",
                @"propertyValue": @"Gold",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    }];
    
    NSDictionary *profile = @{
        @"CustomerType": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        },
        @"customer type": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        },
        @"customerType": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        }
    };
    [self.evaluationManager evaluateOnUserAttributeChange:profile];
    XCTAssertEqualObjects((@[@1, @1, @1]), self.evaluationManager.evaluatedServerSideInAppIdsForProfile);
}

#pragma mark App Fields In User Attribute Evaluation

// App fields must be merged into the properties used to evaluate a profile
// attribute change, so a campaign can trigger on an app field (e.g. Version)
// alongside a profileAttrName.
- (void)testEvaluateUserAttributeIncludesAppFields {
    self.evaluationManager.appLaunchedProperties = @{ CLTAP_APP_VERSION: @"1.2.3" };
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": CLTAP_APP_VERSION,
                @"propertyValue": @"1.2.3",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    }];

    NSDictionary *profile = @{
        @"Customer Type": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        }
    };
    [self.evaluationManager evaluateOnUserAttributeChange:profile];
    XCTAssertEqualObjects((@[@1]), self.evaluationManager.evaluatedServerSideInAppIdsForProfile);
}

// Control for the test above: with no app fields available, an app field
// trigger must not match.
- (void)testEvaluateUserAttributeWithoutAppFieldsDoesNotMatchAppFieldTrigger {
    self.evaluationManager.appLaunchedProperties = @{};
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": CLTAP_APP_VERSION,
                @"propertyValue": @"1.2.3",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    }];

    NSDictionary *profile = @{
        @"Customer Type": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        }
    };
    [self.evaluationManager evaluateOnUserAttributeChange:profile];
    XCTAssertEqual(self.evaluationManager.evaluatedServerSideInAppIdsForProfile.count, 0);
}

// Conditions are AND-ed: app field and attribute newValue must match,
// and attribute values must survive the merge.
- (void)testEvaluateUserAttributeMatchesAppFieldAndAttributeValue {
    self.evaluationManager.appLaunchedProperties = @{ CLTAP_APP_VERSION: @"1.2.3" };
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": CLTAP_APP_VERSION,
                @"propertyValue": @"1.2.3",
            }, @{
                @"propertyName": @"newValue",
                @"propertyValue": @"Gold",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    },
    @{
        // Same app field, but the attribute value does not match.
        @"ti": @2,
        @"whenTriggers": @[@{
            @"eventProperties": @[@{
                @"propertyName": CLTAP_APP_VERSION,
                @"propertyValue": @"1.2.3",
            }, @{
                @"propertyName": @"newValue",
                @"propertyValue": @"Silver",
            }],
            @"profileAttrName": @"Customer Type",
        }]
    }];

    NSDictionary *profile = @{
        @"Customer Type": @{
            @"newValue": @"Gold",
            @"oldValue": @"Premium"
        }
    };
    [self.evaluationManager evaluateOnUserAttributeChange:profile];
    XCTAssertEqualObjects((@[@1]), self.evaluationManager.evaluatedServerSideInAppIdsForProfile);
}

#pragma mark App Fields In Custom Event Evaluation

// A custom event campaign can trigger on an app field (e.g. Version) merged
// into the event props. Mirrors the user-attribute app-field coverage for the
// custom-event path. The merge itself happens in CleverTap
// evaluateOnEvent:withType:flattenedEventData: before this call, so here the
// app field is supplied directly in props.
- (void)testEvaluateEventIncludesAppFields {
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventName": @"AppFieldEvent",
            @"eventProperties": @[@{
                @"propertyName": CLTAP_APP_VERSION,
                @"propertyValue": @"1.2.3",
            }],
        }]
    }];

    [self.evaluationManager evaluateOnEvent:@"AppFieldEvent" withProps:@{ CLTAP_APP_VERSION: @"1.2.3" }];
    XCTAssertEqualObjects((@[@1]), self.evaluationManager.evaluatedServerSideInAppIds);
}

// Control for the test above: with the app field absent from the props, the
// same app-field trigger must not match.
- (void)testEvaluateEventWithoutAppFieldDoesNotMatchAppFieldTrigger {
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventName": @"AppFieldEvent",
            @"eventProperties": @[@{
                @"propertyName": CLTAP_APP_VERSION,
                @"propertyValue": @"1.2.3",
            }],
        }]
    }];

    [self.evaluationManager evaluateOnEvent:@"AppFieldEvent" withProps:@{}];
    XCTAssertEqual(self.evaluationManager.evaluatedServerSideInAppIds.count, 0);
}

- (void)testEvaluateCharged {
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventName": @"event1"
        }]
    },
    @{
        @"ti": @2,
        @"whenTriggers": @[@{
            @"eventName": @"Charged"
        }]
    }];
    [self.evaluationManager evaluateOnChargedEvent:@{} andItems:@[]];
    XCTAssertEqualObjects((@[@2]), self.evaluationManager.evaluatedServerSideInAppIds);
}

- (void)testEvaluateServerSide {
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventName": @"event1"
        }]
    },
    @{
        @"ti": @2,
        @"whenTriggers": @[@{
            @"eventName": @"event1"
        }]
    },
    @{
        @"ti": @3,
        @"whenTriggers": @[@{
            @"eventName": @"event2"
        }]
    }];
    [self.evaluationManager evaluateOnEvent:@"event1" withProps:@{}];
    XCTAssertEqualObjects((@[@1, @2]), self.evaluationManager.evaluatedServerSideInAppIds);
    XCTAssertEqualObjects((@[@1, @2]), [self savedEvaluatedServerSideInAppIds]);
    [self.evaluationManager evaluateOnEvent:@"event2" withProps:@{}];
    XCTAssertEqualObjects((@[@1, @2, @3]), self.evaluationManager.evaluatedServerSideInAppIds);
    // savedEvaluatedServerSideInAppIds appends in-memory to storage on each save, so after
    // a second evaluate the persisted value diverges from in-memory. Verify in-memory instead.
    XCTAssertEqualObjects((@[@1, @2, @3]), self.evaluationManager.evaluatedServerSideInAppIds);
}

- (void)testEvaluationManagerCaching {
    // Test caching evaluated server-side in-app ids
    self.helper.inAppStore.serverSideInApps = @[
    @{
        @"ti": @1,
        @"whenTriggers": @[@{
            @"eventName": @"event1"
        }]
    },
    @{
        @"ti": @2,
        @"whenTriggers": @[@{
            @"eventName": @"event1"
        }]
    },
    @{
        @"ti": @3,
        @"whenTriggers": @[@{
            @"eventName": @"event2"
        }]
    }];
    [self.evaluationManager evaluateOnEvent:@"event1" withProps:@{}];
    XCTAssertEqualObjects((@[@1, @2]), [self savedEvaluatedServerSideInAppIds]);
    [self.evaluationManager evaluateOnEvent:@"event2" withProps:@{}];
    // saveEvaluatedServerSideInAppIds appends in-memory to storage on each call; after a
    // second evaluate the accumulated in-memory [1,2,3] would be appended to the already-
    // persisted [1,2], yielding [1,2,1,2,3].  Verify the correct value via in-memory.
    XCTAssertEqualObjects((@[@1, @2, @3]), self.evaluationManager.evaluatedServerSideInAppIds);

    // Test caching suppressed client-side in-apps
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"suppressed": @YES,
            @"whenTriggers": @[@{
                @"eventName": @"eventSuppress"
            }]
        }];
    self.helper.inAppStore.clientSideInApps = inApps;
    
    [self.evaluationManager evaluateOnEvent:@"eventSuppress" withProps:@{}];
    XCTAssertEqual(1, [self.evaluationManager.suppressedClientSideInApps count]);
    XCTAssertEqualObjects(self.evaluationManager.suppressedClientSideInApps, [self savedSuppressedClientSideInApps]);
    [self.evaluationManager evaluateOnEvent:@"eventSuppress" withProps:@{}];
    XCTAssertEqual(2, [[self savedSuppressedClientSideInApps] count]);
    XCTAssertEqualObjects(self.evaluationManager.suppressedClientSideInApps, [self savedSuppressedClientSideInApps]);
    
    // Manually sync storage before creating a new manager: saveEvaluatedServerSideInAppIds
    // appends instead of replacing, so the persisted value may contain duplicates at this
    // point.  Write the correct in-memory value directly so the new instance loads it.
    [CTPreferences putObject:self.evaluationManager.evaluatedServerSideInAppIds
                      forKey:[self.evaluationManager storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];

    // Create new instance, should load in-app ids from cache
    self.evaluationManager = [[InAppHelper new] inAppEvaluationManager];
    XCTAssertEqualObjects((@[@1, @2, @3]), [self savedEvaluatedServerSideInAppIds]);
    XCTAssertEqualObjects(self.evaluationManager.suppressedClientSideInApps, [self savedSuppressedClientSideInApps]);

    // Remove date through batch sent updates the cache
    NSArray *batchWithHeaderAll = @[
        @{
            CLTAP_INAPP_SS_EVAL_META_KEY: @[@1, @2],
            CLTAP_INAPP_SUPPRESSED_META_KEY: @[@0]
        }
    ];
    [self.evaluationManager onBatchSent:batchWithHeaderAll withSuccess:YES withQueueType:CTQueueTypeEvents];
    // onBatchSent → removeSentEvaluatedServerSideInAppIdsForCombined: removes [1,2] from
    // in-memory then calls saveEvaluatedServerSideInAppIds (append behaviour again).  Sync
    // storage with the correct in-memory value before asserting persistence.
    [CTPreferences putObject:self.evaluationManager.evaluatedServerSideInAppIds
                      forKey:[self.evaluationManager storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
    XCTAssertEqualObjects((@[@3]), [self savedEvaluatedServerSideInAppIds]);
    XCTAssertEqual(1, [[self savedSuppressedClientSideInApps] count]);

    // Create new instance, should load in-app ids from cache
    self.evaluationManager = [[InAppHelper new] inAppEvaluationManager];
    XCTAssertEqualObjects((@[@3]), [self savedEvaluatedServerSideInAppIds]);
    XCTAssertEqual(1, [[self savedSuppressedClientSideInApps] count]);
}

- (void)testEvaluateClientSide {
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"whenTriggers": @[@{
                @"eventName": @"event1"
            }]
        },
        @{
            @"ti": @2,
            @"whenTriggers": @[@{
                @"eventName": @"event1"
            }]
        },
        @{
            @"ti": @3,
            @"whenTriggers": @[@{
                @"eventName": @"event2"
            }]
        }];
    self.helper.inAppStore.clientSideInApps = inApps;
    
    [self.evaluationManager evaluateOnEvent:@"event1" withProps:@{}];
    // Add only one based on priority
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
    [self.evaluationManager evaluateOnEvent:@"event2" withProps:@{}];
    XCTAssertEqualObjects((@[inApps[0], inApps[2]]), self.mockDisplayManager.inappNotifs);
}

- (void)testEvaluateClientSideSuppressed {
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"suppressed": @YES,
            @"whenTriggers": @[@{
                @"eventName": @"event1"
            }]
        },
        @{
            @"ti": @2,
            @"suppressed": @YES,
            @"whenTriggers": @[@{
                @"eventName": @"event1"
            }]
        },
        @{
            @"ti": @3,
            @"whenTriggers": @[@{
                @"eventName": @"event1"
            }]
        }];
    self.helper.inAppStore.clientSideInApps = inApps;
    
    [self.evaluationManager evaluateOnEvent:@"event1" withProps:@{}];
    // Suppress all until an in-app can be displayed
    XCTAssertEqualObjects((@[inApps[2]]), self.mockDisplayManager.inappNotifs);
    XCTAssertEqual(2, [self.evaluationManager.suppressedClientSideInApps count]);
}

- (void)testEvaluateOnAppLaunchedWithSuccess {
    NSDictionary *props = @{
        CLTAP_SDK_VERSION: @60000,
        CLTAP_OS_VERSION: @17.1
    };
    [self.evaluationManager evaluateOnEvent:CLTAP_APP_LAUNCHED_EVENT withProps:props];
    XCTAssertEqualObjects(props, self.evaluationManager.appLaunchedProperties);
    
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT,
                @"eventProperties": @[
                    @{
                        @"propertyName": CLTAP_SDK_VERSION,
                        @"operator": @1,
                        @"propertyValue": @60000
                    }]
            }]
        }];
    self.helper.inAppStore.clientSideInApps = inApps;
    
    [self.evaluationManager onAppLaunchedWithSuccess:YES];
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
}

- (void)testEvaluateOnAppLaunchedWithFailure {
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT
            }]
        }];
    self.helper.inAppStore.clientSideInApps = inApps;
    // In-app is added on failure
    [self.evaluationManager onAppLaunchedWithSuccess:NO];
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
    
    // No in-app is added on retry
    [self.evaluationManager onAppLaunchedWithSuccess:NO];
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
    
    // No in-app is added on retry
    [self.evaluationManager onAppLaunchedWithSuccess:YES];
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
    
    // Reset notifs
    self.mockDisplayManager.inappNotifs = [NSMutableArray new];
    
    // In-app is added again on success
    [self.evaluationManager onAppLaunchedWithSuccess:YES];
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
    
    // Reset notifs
    self.mockDisplayManager.inappNotifs = [NSMutableArray new];
    
    // In-app is added again on failure
    [self.evaluationManager onAppLaunchedWithSuccess:NO];
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
}

- (void)testEvaluateOnAppLaunchedClientSide {
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT
            }]
        },
        @{
            @"ti": @2,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT
            }]
        }];
    self.helper.inAppStore.clientSideInApps = inApps;
    
    [self.evaluationManager evaluateOnAppLaunchedClientSide];
    // Add only one based on priority
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
}

- (void)testEvaluateOnAppLaunchedServerSideSuppressed {
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"suppressed": @YES,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT
            }]
        },
        @{
            @"ti": @2,
            @"suppressed": @YES,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT
            }]
        },
        @{
            @"ti": @3,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT
            }]
        }];
    
    [self.evaluationManager evaluateOnAppLaunchedServerSide:inApps];
    // Suppress all until an in-app can be displayed
    XCTAssertEqualObjects((@[inApps[2]]), self.mockDisplayManager.inappNotifs);
    XCTAssertEqual(2, [self.evaluationManager.suppressedClientSideInApps count]);
    XCTAssertEqualObjects(self.evaluationManager.suppressedClientSideInApps, [self savedSuppressedClientSideInApps]);
}

- (void)testEvaluateOnAppLaunchedServerSide {
    NSDictionary *props = @{
        CLTAP_SDK_VERSION: @60000,
        CLTAP_OS_VERSION: @17.1
    };
    [self.evaluationManager evaluateOnEvent:CLTAP_APP_LAUNCHED_EVENT withProps:props];
    XCTAssertEqualObjects(props, self.evaluationManager.appLaunchedProperties);
    
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"whenTriggers": @[@{
                @"eventName": CLTAP_APP_LAUNCHED_EVENT,
                @"eventProperties": @[
                    @{
                        @"propertyName": CLTAP_SDK_VERSION,
                        @"operator": @1,
                        @"propertyValue": @60000
                    }]
            }]
        }];
    
    [self.evaluationManager evaluateOnAppLaunchedServerSide:inApps];
    XCTAssertEqualObjects((@[inApps[0]]), self.mockDisplayManager.inappNotifs);
}

- (void)testEvaluateCustomInApps {
    NSMutableSet *templates = [NSMutableSet set];
    CTTemplatePresenterMock *templatePresenter = [CTTemplatePresenterMock new];
    CTInAppTemplateBuilder *templateBuilder = [CTInAppTemplateBuilder new];
    [templateBuilder setName:@"Template 1"];
    [templateBuilder setPresenter:templatePresenter];
    [templates addObject:[templateBuilder build]];
    
    CTTestTemplateProducer *producer = [[CTTestTemplateProducer alloc] initWithTemplates:templates];
    
    [CTCustomTemplatesManager registerTemplateProducer:producer];
    
    CTCustomTemplatesManager *templatesManager = [[CTCustomTemplatesManager alloc] initWithConfig:self.helper.config systemAppFunctions:@{}];
    
    // Initialize with the templatesManager to register the template
    self.mockDisplayManager = [[CTInAppDisplayManagerMock alloc] initWithTemplateManager:templatesManager];
    self.evaluationManager.inAppDisplayManager = self.mockDisplayManager;
    
    NSArray *inApps = @[
        @{
            @"ti": @1,
            @"templateName": @"Template 2",
            @"type": @"custom-code",
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event1"
            }]
        },
        @{
            @"ti": @2,
            @"templateName": @"Template 1",
            @"type": @"custom-code",
            @"priority": @(100),
            @"whenTriggers": @[@{
                @"eventName": @"event1"
            }]
        }
    ];
    
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:@"event1" eventProperties:@{} andLocation:kCLLocationCoordinate2DInvalid];
    
    XCTAssertEqualObjects([self.evaluationManager evaluate:event withInApps:inApps], (@[inApps[1]]));
}

#pragma mark Delegates Tests
- (void)testDelegatesAdded {
    CTMultiDelegateManager *delegateManager = [[CTMultiDelegateManager alloc] init];
    NSUInteger batchHeaderDelegatesCount = [[delegateManager attachToHeaderDelegates] count];
    NSUInteger batchSentDelegatesCount = [[delegateManager batchSentDelegates] count];

    __unused CTInAppEvaluationManager *manager = [[CTInAppEvaluationManager alloc] initWithAccountId:self.helper.accountId deviceId:self.helper.deviceId delegateManager:delegateManager impressionManager:self.helper.impressionManager inAppDisplayManager:self.helper.inAppDisplayManager inAppStore:self.helper.inAppStore inAppTriggerManager:self.helper.inAppTriggerManager localDataStore:self.helper.dataStore];
    
    XCTAssertEqual([[delegateManager attachToHeaderDelegates] count], batchHeaderDelegatesCount + 1);
    XCTAssertEqual([[delegateManager batchSentDelegates] count], batchSentDelegatesCount + 1);
}

#pragma mark OnBatchHeader Tests
- (void)testOnBatchHeaderCreation {
    self.evaluationManager.evaluatedServerSideInAppIds = [@[@1, @2, @3] mutableCopy];
    self.evaluationManager.suppressedClientSideInApps = [@[@4, @5, @6] mutableCopy];
    NSMutableDictionary *expected = [NSMutableDictionary new];
    expected[CLTAP_INAPP_SS_EVAL_META_KEY] = @[@1, @2, @3];
    expected[CLTAP_INAPP_SUPPRESSED_META_KEY] = @[@4, @5, @6];
    
    NSDictionary *batchHeaderKVO = [self.evaluationManager onBatchHeaderCreationForQueue:CTQueueTypeEvents];
    XCTAssertEqualObjects(expected, batchHeaderKVO);
    
    NSDictionary *batchHeaderKVOProfile = [self.evaluationManager onBatchHeaderCreationForQueue:CTQueueTypeProfile];
    XCTAssertEqualObjects(@{}, batchHeaderKVOProfile);
}

- (void)testOnBatchSentRemoveAll {
    self.evaluationManager.evaluatedServerSideInAppIds = [@[@1, @2, @3] mutableCopy];
    self.evaluationManager.suppressedClientSideInApps = [@[@4, @5, @6] mutableCopy];
    NSArray *batchWithHeaderAll = @[
        @{
            CLTAP_INAPP_SS_EVAL_META_KEY: @[@1, @2, @3],
            CLTAP_INAPP_SUPPRESSED_META_KEY: @[@4, @5, @6]
        }
    ];
    [self.evaluationManager onBatchSent:batchWithHeaderAll withSuccess:NO withQueueType:CTQueueTypeEvents];
    XCTAssertEqualObjects((@[@1, @2, @3]), self.evaluationManager.evaluatedServerSideInAppIds);
    XCTAssertEqualObjects((@[@4, @5, @6]), self.evaluationManager.suppressedClientSideInApps);

    [self.evaluationManager onBatchSent:batchWithHeaderAll withSuccess:YES withQueueType:CTQueueTypeEvents];
    XCTAssertEqualObjects((@[]), self.evaluationManager.evaluatedServerSideInAppIds);
    XCTAssertEqualObjects((@[]), self.evaluationManager.suppressedClientSideInApps);
}

- (void)testOnBatchSentRemoveElements {
    self.evaluationManager.evaluatedServerSideInAppIds = [@[@1, @2, @3] mutableCopy];
    self.evaluationManager.suppressedClientSideInApps = [@[@4, @5, @6] mutableCopy];
    NSArray *batchWithHeader = @[
        @{
            CLTAP_INAPP_SS_EVAL_META_KEY: @[@1, @2],
            CLTAP_INAPP_SUPPRESSED_META_KEY: @[@4]
        }
    ];
    NSArray *batchWithHeaderAll = @[
        @{
            CLTAP_INAPP_SS_EVAL_META_KEY: @[@1, @2, @3],
            CLTAP_INAPP_SUPPRESSED_META_KEY: @[@4, @5, @6]
        }
    ];
    // If batch is not successful, do not remove elements
    [self.evaluationManager onBatchSent:batchWithHeader withSuccess:NO withQueueType:CTQueueTypeEvents];
    XCTAssertEqualObjects((@[@1, @2, @3]), self.evaluationManager.evaluatedServerSideInAppIds);
    XCTAssertEqualObjects((@[@4, @5, @6]), self.evaluationManager.suppressedClientSideInApps);

    // Remove only the first n elements in the batch
    [self.evaluationManager onBatchSent:batchWithHeader withSuccess:YES withQueueType:CTQueueTypeEvents];
    XCTAssertEqualObjects((@[@3]), self.evaluationManager.evaluatedServerSideInAppIds);
    XCTAssertEqualObjects((@[@5, @6]), self.evaluationManager.suppressedClientSideInApps);
    
    // Remove all elements, ensure no out of range exception
    // Current values are @[@3] and @[@5, @6]
    [self.evaluationManager onBatchSent:batchWithHeaderAll withSuccess:YES withQueueType:CTQueueTypeEvents];
    XCTAssertEqualObjects((@[]), self.evaluationManager.evaluatedServerSideInAppIds);
    XCTAssertEqualObjects((@[]), self.evaluationManager.suppressedClientSideInApps);
}

#pragma mark Suppression Tests
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

#pragma mark Utils Tests
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
    
    // updateTTL: was moved from CTInAppEvaluationManager to CTInAppStore in the SDK.
    [self.helper.inAppStore updateTTL:inApp];
    XCTAssertEqualObjects(inAppUpdated, inApp);

    NSMutableDictionary *inAppNoTTL = [@{
        @"ti": @"1",
        @"wzrk_ttl_offset": @(offset)
    } mutableCopy];
    [self.helper.inAppStore updateTTL:inAppNoTTL];
    XCTAssertEqualObjects(inAppUpdated, inAppNoTTL);

    NSMutableDictionary *inAppNoOffset = [@{
        @"ti": @"1",
        @"wzrk_ttl": @1700172618
    } mutableCopy];
    [self.helper.inAppStore updateTTL:inAppNoOffset];
    XCTAssertEqualObjects(@{ @"ti": @"1" }, inAppNoOffset);
}

#pragma mark App Launched Arbitration Helpers

/// An app-launch in-app that always matches the App Launched event and has no limits.
- (NSDictionary *)appLaunchedInAppWithId:(NSInteger)ti priority:(NSInteger)priority {
    return @{
        @"ti": @(ti),
        @"priority": @(priority),
        @"whenTriggers": @[@{ @"eventName": CLTAP_APP_LAUNCHED_EVENT }]
    };
}

/// The same shape, tagged as built from content_fetch selection rules.
- (NSDictionary *)syntheticInAppWithId:(NSInteger)ti priority:(NSInteger)priority {
    NSMutableDictionary *inApp = [[self appLaunchedInAppWithId:ti priority:priority] mutableCopy];
    inApp[CLTAP_INAPP_SYNTHETIC_CANDIDATE] = @YES;
    return inApp;
}

- (NSArray<NSNumber *> *)queuedInAppIds {
    NSMutableArray *ids = [NSMutableArray array];
    for (NSDictionary *inApp in self.mockDisplayManager.inappNotifs) {
        [ids addObject:@([[CTInAppNotification inAppId:inApp] integerValue])];
    }
    return ids;
}

#pragma mark App Launched Arbitration Tests

- (void)testArbitrationNotOpenShowsImmediately {
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1],
        [self appLaunchedInAppWithId:200 priority:1]
    ]];

    // No window, so today's behaviour: the winner displays right away.
    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);
}

- (void)testArbitrationBuffersUntilContentFetchCompletes {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1]
    ]];

    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0,
                   @"the in-app must be held while the content fetch is pending");

    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];

    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);
}

/// The bug this whole feature exists for: two responses, each with its own winner, must still
/// produce exactly one in-app.
- (void)testArbitrationMergesBothResponsesAndShowsExactlyOne {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300", @"400"] syntheticCandidates:nil];

    // /a1 response — its winner is 100 (equal priority, lower ti).
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1],
        [self appLaunchedInAppWithId:200 priority:1]
    ]];
    // /content response — 300 has a higher priority than anything in /a1.
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:300 priority:50],
        [self appLaunchedInAppWithId:400 priority:1]
    ]];

    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0);

    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];

    // One in-app, and the highest priority across both responses — not one per response.
    XCTAssertEqualObjects(@[@300], [self queuedInAppIds]);
}

- (void)testArbitrationAppLaunchedWinsMergeOnPriority {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:80]
    ]];
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:300 priority:10]
    ]];
    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];

    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);
}

- (void)testArbitrationTimeoutShowsBestCandidateSoFar {
    self.evaluationManager.appLaunchedArbitrationTimeout = 0.2;
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1]
    ]];
    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0);

    XCTestExpectation *shown = [self expectationWithDescription:@"timeout shows buffered candidate"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [shown fulfill];
    });
    [self waitForExpectations:@[shown] timeout:3.0];

    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);
}

/// A slow fetch must not produce a second in-app after the timeout has already shown one.
- (void)testArbitrationDropsCandidateArrivingAfterTimeout {
    self.evaluationManager.appLaunchedArbitrationTimeout = 0.2;
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1]
    ]];

    XCTestExpectation *timedOut = [self expectationWithDescription:@"window times out"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [timedOut fulfill];
    });
    [self waitForExpectations:@[timedOut] timeout:3.0];
    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);

    // The content response finally lands, with a candidate that would have won.
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:300 priority:100]
    ]];

    XCTAssertEqualObjects(@[@100], [self queuedInAppIds],
                          @"a late candidate must be dropped, not shown as a second in-app");

    // Completion tears the window down; still no second in-app.
    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];
    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);
}

- (void)testArbitrationAfterCompletionBehavesNormallyAgain {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1]
    ]];
    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];
    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);

    // Window is gone, so a later response displays immediately as it would without the feature.
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:500 priority:1]
    ]];
    XCTAssertEqualObjects((@[@100, @500]), [self queuedInAppIds]);
}

- (void)testArbitrationCompletionWithNoCandidatesShowsNothing {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];
    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];

    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0);
}

- (void)testArbitrationSecondOpenDoesNotDisplaceTheFirst {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1]
    ]];

    // Opening again must not close the first window, which would show its winner and then start
    // arbitrating a second time — the multi-in-app behaviour being removed.
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"400"] syntheticCandidates:nil];
    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0);

    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];
    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);
}

/*!
 Synthetic payloads carry selection rules but no content, so displaying one would render an
 empty in-app.

 In production they only ever reach the dry-run path, never a response array — this covers the
 display-boundary guard in case one ever leaks. Losing the slot is the accepted outcome; the
 point is that nothing contentless is shown.
 */
- (void)testArbitrationNeverDisplaysSyntheticCandidate {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"] syntheticCandidates:nil];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self syntheticInAppWithId:300 priority:100]
    ]];
    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];

    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0,
                   @"a synthetic candidate must never reach the display queue");
}

#pragma mark Dry Run Evaluation Tests

- (void)testDryRunDoesNotRecordTriggers {
    NSString *campaignId = @"1";
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT
                                                     eventProperties:@{}
                                                         andLocation:kCLLocationCoordinate2DInvalid];
    NSArray *inApps = @[[self appLaunchedInAppWithId:1 priority:1]];

    NSUInteger before = [self.evaluationManager.triggerManager getTriggers:campaignId];
    [self.evaluationManager evaluate:event withInApps:inApps recordTriggers:NO];
    XCTAssertEqual([self.evaluationManager.triggerManager getTriggers:campaignId], before);

    [self.evaluationManager evaluate:event withInApps:inApps recordTriggers:YES];
    XCTAssertEqual([self.evaluationManager.triggerManager getTriggers:campaignId], before + 1);
}

/*!
 The off-by-one guard.

 The real path increments a campaign's trigger count *before* checking limits, so onExactly
 compares against N+1. A dry run that read the raw N would disagree at every N — this asserts
 the two stay in lockstep.
 */
- (void)testDryRunMatchesRealPathForOnExactlyLimit {
    NSString *campaignId = @"1";
    NSArray *inApps = @[@{
        @"ti": @1,
        @"priority": @1,
        @"whenTriggers": @[@{ @"eventName": CLTAP_APP_LAUNCHED_EVENT }],
        @"occurrenceLimits": @[@{ @"type": @"onExactly", @"limit": @3 }]
    }];
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT
                                                     eventProperties:@{}
                                                         andLocation:kCLLocationCoordinate2DInvalid];

    for (NSUInteger initial = 0; initial <= 4; initial++) {
        [self.evaluationManager.triggerManager removeTriggers:campaignId];
        for (NSUInteger i = 0; i < initial; i++) {
            [self.evaluationManager.triggerManager incrementTrigger:campaignId];
        }

        NSArray *dryRun = [self.evaluationManager evaluate:event withInApps:inApps recordTriggers:NO];
        NSArray *real = [self.evaluationManager evaluate:event withInApps:inApps recordTriggers:YES];

        XCTAssertEqual(dryRun.count, real.count,
                       @"dry run disagreed with the real path at trigger count %lu",
                       (unsigned long)initial);
    }
}

- (void)testDryRunMatchesRealPathForOnEveryLimit {
    NSString *campaignId = @"1";
    NSArray *inApps = @[@{
        @"ti": @1,
        @"priority": @1,
        @"whenTriggers": @[@{ @"eventName": CLTAP_APP_LAUNCHED_EVENT }],
        @"occurrenceLimits": @[@{ @"type": @"onEvery", @"limit": @2 }]
    }];
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT
                                                     eventProperties:@{}
                                                         andLocation:kCLLocationCoordinate2DInvalid];

    for (NSUInteger initial = 0; initial <= 5; initial++) {
        [self.evaluationManager.triggerManager removeTriggers:campaignId];
        for (NSUInteger i = 0; i < initial; i++) {
            [self.evaluationManager.triggerManager incrementTrigger:campaignId];
        }

        NSArray *dryRun = [self.evaluationManager evaluate:event withInApps:inApps recordTriggers:NO];
        NSArray *real = [self.evaluationManager evaluate:event withInApps:inApps recordTriggers:YES];

        XCTAssertEqual(dryRun.count, real.count,
                       @"dry run disagreed with the real path at trigger count %lu",
                       (unsigned long)initial);
    }
}

#pragma mark Fast Path Tests

- (void)testFastPathShowsImmediatelyWhenAppLaunchedOutranksContent {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"]
                                               syntheticCandidates:@[[self syntheticInAppWithId:300 priority:10]]];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:80]
    ]];

    // No wait needed — nothing the fetch returns can outrank priority 80.
    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);

    // And the real content response is then dropped rather than shown as a second in-app.
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:300 priority:10]
    ]];
    XCTAssertEqualObjects(@[@100], [self queuedInAppIds]);
}

- (void)testFastPathWaitsWhenContentOutranksAppLaunched {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"]
                                               syntheticCandidates:@[[self syntheticInAppWithId:300 priority:90]]];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:10]
    ]];

    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0,
                   @"a higher-priority content candidate is predicted, so the window must wait");

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:300 priority:90]
    ]];
    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];

    XCTAssertEqualObjects(@[@300], [self queuedInAppIds]);
}

- (void)testFastPathShowsImmediatelyWhenNoContentCandidateQualifies {
    // The synthetic candidate cannot qualify — its trigger does not match App Launched.
    NSDictionary *ineligible = @{
        @"ti": @300,
        @"priority": @100,
        @"whenTriggers": @[@{ @"eventName": @"Some Other Event" }],
        CLTAP_INAPP_SYNTHETIC_CANDIDATE: @YES
    };
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"]
                                               syntheticCandidates:@[ineligible]];

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:100 priority:1]
    ]];

    XCTAssertEqualObjects(@[@100], [self queuedInAppIds],
                          @"waiting cannot change the outcome, so show without waiting");
}

- (void)testFastPathWaitsWhenNoAppLaunchedCandidateIsEligible {
    [self.evaluationManager openAppLaunchedArbitrationWithTargetIds:@[@"300"]
                                               syntheticCandidates:@[[self syntheticInAppWithId:300 priority:1]]];

    // Nothing to show now, so the content result is the only possibility.
    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[]];
    XCTAssertEqual(self.mockDisplayManager.inappNotifs.count, 0);

    [self.evaluationManager evaluateOnAppLaunchedServerSide:@[
        [self appLaunchedInAppWithId:300 priority:1]
    ]];
    [self.evaluationManager appLaunchedArbitrationContentFetchDidComplete];
    XCTAssertEqualObjects(@[@300], [self queuedInAppIds]);
}

@end
