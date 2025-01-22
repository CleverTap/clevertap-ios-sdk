//
//  CTTriggersMatcherTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 4.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTTriggersMatcher.h"
#import "CTEventAdapter.h"
#import "CTTriggerEvaluator.h"
#import "CTTriggersMatcher+Tests.h"
#import "CTConstants.h"

@interface CTTriggersMatcherTest : XCTestCase
@property (nonatomic, strong) CTLocalDataStore *dataStore;
@end

@implementation CTTriggersMatcherTest

- (void)setUp {
    [super setUp];
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken" accountRegion:@"testRegion"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"testDeviceInfo"];
    CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:config];
    self.dataStore = [[CTLocalDataStore alloc] initWithConfig:config profileValues:[NSMutableDictionary new] andDeviceInfo:deviceInfo dispatchQueueManager:queueManager];
}

#pragma mark Event
- (void)testMatchEventAllOperators {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @0,
                    @"propertyValue": @150
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"propertyValue": @"Equals"
                },
                @{
                    @"propertyName": @"prop3",
                    @"operator": @2,
                    @"propertyValue": @150
                },
                @{
                    @"propertyName": @"prop4",
                    @"operator": @3,
                    @"propertyValue": @"Contains"
                },
                @{
                    @"propertyName": @"prop5",
                    @"operator": @4,
                    @"propertyValue": @[@1, @3]
                },
                @{
                    @"propertyName": @"prop6",
                    @"operator": @15,
                    @"propertyValue": @"NotEquals"
                },
                @{
                    @"propertyName": @"prop7",
                    @"operator": @26
                },
                @{
                    @"propertyName": @"prop8",
                    @"operator": @27
                },
                @{
                    @"propertyName": @"prop9",
                    @"operator": @28,
                    @"propertyValue": @"NotContains"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @160,
        @"prop2": @"Equals",
        @"prop3": @140,
        @"prop4": @"Contains CleverTap",
        @"prop5": @2,
        @"prop6": @"NotEquals!",
        @"prop7": @"is set",
        @"prop9": @"No Contains",
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEventWithoutTriggerProps {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1"
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    XCTAssertTrue(match);
    
    BOOL matchNoProps = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{}];
    XCTAssertTrue(matchNoProps);
}

- (void)testMatchEventWithEmptyTriggerProps {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    XCTAssertTrue(match);
    
    BOOL matchNoProps = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{}];
    XCTAssertTrue(matchNoProps);
}

- (void)testMatchEventWithoutProps {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @"test"
                }],
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL matchNoProps = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{}];
    XCTAssertFalse(matchNoProps);
}

- (void)testMatchEventWithNormalizedName {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"Event 1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    XCTAssertTrue(match);
}

#pragma mark Profile Event

- (void)testMatchProfileEvent {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"profile1 changed",
            @"profileAttrName": @"profile1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"newValue",
                    @"operator": @0,
                    @"propertyValue": @150
                },
                @{
                    @"propertyName": @"oldValue",
                    @"operator": @1,
                    @"propertyValue": @"Equals"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    NSDictionary *eventProperties = @{
        @"newValue": @160,
        @"oldValue": @"Equals"
    };
    
    CTEventAdapter *eventAdapter = [[CTEventAdapter alloc] initWithEventName:@"profile1_changed" profileAttrName:@"profile1" eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:eventAdapter];
    XCTAssertTrue(match);
    
    eventAdapter = [[CTEventAdapter alloc] initWithEventName:@"profile 1_changed" profileAttrName:@"profile 1" eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:eventAdapter];
    XCTAssertTrue(match);
    
    eventAdapter = [[CTEventAdapter alloc] initWithEventName:@"Profile 1_changed" profileAttrName:@"Profile 1" eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:eventAdapter];
    XCTAssertTrue(match);
    
    eventAdapter = [[CTEventAdapter alloc] initWithEventName:@"profile  1_changed" profileAttrName:@"profile  1" eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:eventAdapter];
    XCTAssertTrue(match);
    
    eventAdapter = [[CTEventAdapter alloc] initWithEventName:@"Profile_1_changed" profileAttrName:@"Profile_1" eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:eventAdapter];
    XCTAssertFalse(match);
}

#pragma mark Charged Event

- (void)testMatchChargedEvent {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product_name",
                    @"operator": @1,
                    @"propertyValue": @"product 1"
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"prop1": @150,
    } items:@[
        @{
            @"product_name": @"product 1",
            @"price": @5.99
        },
        @{
            @"product_name": @"product 2",
            @"price": @5.50
        }
    ]];
    
    XCTAssertTrue(match);
}

- (void)testChargedWithoutItems {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }],
            @"itemProperties": @[]
        }
    ];
    
    NSArray *whenTriggersNoItems = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"prop1": @150,
    } items:@[
        @{
            @"product_name": @"product 1",
            @"price": @5.99
        },
        @{
            @"product_name": @"product 2",
            @"price": @5.50
        }
    ]];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggersNoItems details:@{
        @"prop1": @150,
    } items:@[
        @{
            @"product_name": @"product 1",
            @"price": @5.99
        },
        @{
            @"product_name": @"product 2",
            @"price": @5.50
        }
    ]];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"prop1": @150,
    } items:@[]];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggersNoItems details:@{
        @"prop1": @150,
    } items:@[]];
    XCTAssertTrue(match);
}

- (void)testMatchChargedEventItemArrayEquals {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product_name",
                    @"operator": @1,
                    @"propertyValue": @[@"product 1", @"product 2"]
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"prop1": @150,
    } items:@[
        @{
            @"product_name": @"product 1",
            @"price": @5.99
        },
        @{
            @"product_name": @"product 2",
            @"price": @5.50
        }
    ]];
    
    XCTAssertTrue(match);
}

- (void)testMatchChargedEventItemArrayEqualsNormalized {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product name",
                    @"operator": @1,
                    @"propertyValue": @[@"product 1"]
                },
                @{
                    @"propertyName": @"price",
                    @"operator": @1,
                    @"propertyValue": @[@5.99]
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"Prop 1": @150,
    } items:@[
        @{
            @"ProductName": @"product 1",
            @"Price": @5.99
        }
    ]];
    
    XCTAssertTrue(match);
}

- (void)testMatchChargedEventItemArrayContains {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product_name",
                    @"operator": @3,
                    @"propertyValue": @[@"product 1", @"product 2"]
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"prop1": @150,
    } items:@[
        @{
            @"product_name": @"product 1",
            @"price": @5.99
        },
        @{
            @"product_name": @"product 2",
            @"price": @5.50
        }
    ]];
    
    XCTAssertTrue(match);
}

- (void)testMatchChargedEventItemArrayContainsNormalized {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product name",
                    @"operator": @3,
                    @"propertyValue": @[@"product 1", @"product 2"]
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"Product Name": @"product 1",
            @"price": @5.50
        }
    ]];
    
    XCTAssertTrue(match);
}

#pragma mark Equals

- (void)testMatchEqualsPrimitives {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"propertyValue": @200
                },
                @{
                    @"propertyName": @"prop3",
                    @"operator": @1,
                    @"propertyValue": @150
                },
                @{
                    @"propertyName": @"prop4",
                    @"operator": @1,
                    @"propertyValue": @"CleverTap"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150,
        @"prop2": @200,
        @"prop3": @"150",
        @"prop4": @"CleverTap"
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsBoolean {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @"true"
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"propertyValue": @"false"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @(YES),
        @"prop2": @(NO)
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @(true),
        @"prop2": @(false)
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @(1),
        @"prop2": @(0)
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @(NO),
        @"prop2": @(YES)
    }];
    XCTAssertFalse(match);
}

- (void)testMatchEqualsBooleanString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @"true"
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"propertyValue": @"false"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"true",
        @"prop2": @"false"
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsBooleanCaseInsensitive {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @"True"
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"propertyValue": @"False"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @(YES),
        @"prop2": @(NO)
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsNumbers {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"propertyValue": @"200"
                },
                @{
                    @"propertyName": @"prop3",
                    @"operator": @1,
                    @"propertyValue": @[@150, @"200", @0.55]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150,
        @"prop2": @200,
        @"prop3": @200
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150",
        @"prop2": @200,
        @"prop3": @"150"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.00",
        @"prop2": @200.00,
        @"prop3": @"0.55"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.00",
        @"prop2": @200,
        @"prop3": @"0.56"
    }];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150,
        @"prop2": @"200",
        @"prop3": @"55"
    }];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"test",
        @"prop2": @"test",
        @"prop3": @"test"
    }];
    XCTAssertFalse(match);
}

- (void)testMatchEqualsNumbersCharged {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"itemProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"propertyValue": @"200"
                },
                @{
                    @"propertyName": @"prop3",
                    @"operator": @1,
                    @"propertyValue": @[@150, @"200", @0.55]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[@{
        @"prop1": @"150",
        @"prop2": @200,
        @"prop3": @"150"
    }]];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"prop1": @1,
            @"prop2": @2,
            @"prop3": @3
        },
        @{
            @"prop1": @150,
            @"prop2": @200,
            @"prop3": @0.55
        },
    ]];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"prop1": @1,
            @"prop2": @2,
            @"prop3": @3
        }
    ]];
    XCTAssertFalse(match);
}

- (void)testMatchEqualsDouble {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @(150.95)
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150.950
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.950"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.96"
    }];
    XCTAssertFalse(match);
}

- (void)testMatchEqualsExtectedStringWithActualArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @"test"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"test", @"test2"]
    }];
    
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"test1", @"test2"]
    }];
    
    XCTAssertFalse(match);
}

- (void)testMatchEqualsExtectedArrayWithActualString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @[@"test", @"test1"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"test"]
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"test1"]
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"test2"]
    }];
    XCTAssertFalse(match);
}

- (void)testMatchEqualsExtectedNumberWithActualArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"test", @150]
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsExtectedStringWithActualString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @"test"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"test"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"Test"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"TEST"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @12
    }];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": [NSNull null]
    }];
    XCTAssertFalse(match);
}

- (void)testMatchEqualsPropertyNameWithNormalization {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @"test"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop 1": @"test"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"Prop  1": @"test"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"E vent1" eventProperties:@{
        @"Prop  1": @"test"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"Prop.1": @"test"
    }];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"Prop  1": @"test1",
        @"Prop1": @"test",
    }];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"Prop1": @"test1",
        @"prop 1": @"test2",
        @"prop1": @"test",
    }];
    XCTAssertTrue(match);
}

- (void)testMatchEqualsExtectedNumberWithActualString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"test"
    }];
    XCTAssertFalse(match);
}

- (void)testMatchEqualsExtectedDoubleWithActualDouble {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150.99
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150.99
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsExtectedDoubleWithActualDoubleString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150.99
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.99"
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsExtectedArrayWithActualArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @[@"test", @"test2", @"test3"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"test2", @"test3", @"test"]
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsExtectedArrayWithActualArrayNumber {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @[@1, @2, @3]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@3, @1, @2]
    }];
    
    XCTAssertTrue(match);
}

#pragma mark Set
- (void)testMatchSet {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @26
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    XCTAssertTrue(match);
}

- (void)testMatchSetCharged {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"itemProperties": @[
                @{
                    @"propertyName": @"item1",
                    @"operator": @26
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"item2": @1
        },
        @{
            @"item1": @1
        }
    ]];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"item2": @1
        }
    ]];
    XCTAssertFalse(match);
}

#pragma mark Not Set
- (void)testMatchNotSet {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @27
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop2": @150
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchNotSetCharged {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"itemProperties": @[
                @{
                    @"propertyName": @"item1",
                    @"operator": @27
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"item2": @1
        },
        @{
            @"item1": @1
        }
    ]];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"item2": @1
        }
    ]];
    XCTAssertTrue(match);
}

#pragma mark Not Equals
- (void)testMatchNotEquals {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @15,
                    @"propertyValue": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @240
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    XCTAssertFalse(match);
}

- (void)testMatchNotEqualsArrays {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @15,
                    @"propertyValue": @[@150, @240]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@241]
    }];
    XCTAssertTrue(match);
    
    // If any Not Equals any
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@150, @100]
    }];
    XCTAssertTrue(match);
}

#pragma mark Less Than
- (void)testMatchLessThan {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @2,
                    @"propertyValue": @240
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    
    XCTAssertTrue(match);
    
    BOOL matchNoProp = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
    }];
    
    XCTAssertFalse(matchNoProp);
}

- (void)testMatchLessThanWithString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @2,
                    @"propertyValue": @240
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"-120"
    }];
    
    XCTAssertTrue(match);
    
    BOOL matchNaN = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"asd"
    }];
    
    XCTAssertFalse(matchNaN);
}

- (void)testMatchLessThanWithArrays {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @2,
                    @"propertyValue": @[@240]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"-120"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@250, @-1]
    }];
    XCTAssertTrue(match);
    
    whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @2,
                    @"propertyValue": @[@240, @500]
                }
            ]
        }
    ];
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"-120"
    }];
    XCTAssertFalse(match);
}

#pragma mark Greater Than
- (void)testMatchGreaterThan {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @0,
                    @"propertyValue": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @240
    }];
    
    XCTAssertTrue(match);
    
    BOOL matchNoProp = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
    }];
    
    XCTAssertFalse(matchNoProp);
}

- (void)testMatchGreaterThanWithString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @0,
                    @"propertyValue": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"240"
    }];
    
    XCTAssertTrue(match);
    
    BOOL matchNaN = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"asd"
    }];
    
    XCTAssertFalse(matchNaN);
}

- (void)testMatchGreaterThanWithArrays {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @0,
                    @"propertyValue": @[@240]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @600
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@250, @-1, @600]
    }];
    XCTAssertTrue(match);
    
    whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @0,
                    @"propertyValue": @[@240, @500]
                }
            ]
        }
    ];
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @600
    }];
    XCTAssertFalse(match);
}

#pragma mark Between
- (void)testMatchBetween {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @4,
                    @"propertyValue": @[@100, @240]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @100
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @240
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @1
    }];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @250
    }];
    XCTAssertFalse(match);
    
    BOOL matchNan = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"a150"
    }];
    
    XCTAssertFalse(matchNan);
}

- (void)testMatchBetweenCharged {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"itemProperties": @[
                @{
                    @"propertyName": @"item1",
                    @"operator": @4,
                    @"propertyValue": @[@100, @240]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"item1": @1
        },
        @{
            @"item1": @101
        }
    ]];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{} items:@[
        @{
            @"item1": @300
        },
        @{
            @"item1": @400
        }
    ]];
    XCTAssertFalse(match);
}

- (void)testMatchBetweenArrayMoreThan2 {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @4,
                    @"propertyValue": @[@100, @240, @330, @"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchBetweenEmptyArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @4,
                    @"propertyValue": @[]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    
    XCTAssertFalse(match);
}

#pragma mark Contains
- (void)testMatchContainsString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @3,
                    @"propertyValue": @"clever"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"cle"
    }];
    XCTAssertFalse(match);
}

- (void)testMatchContainsStringBool {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @3,
                    @"propertyValue": @"true"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"this is true"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"this is false"
    }];
    XCTAssertFalse(match);
}

- (void)testMatchContainsNumber {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @3,
                    @"propertyValue": @1234
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"1234567"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @1234567
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @123
    }];
    XCTAssertFalse(match);
}

- (void)testMatchContainsArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @3,
                    @"propertyValue": @[@"clever", @"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchContainsArrayNumber {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @3,
                    @"propertyValue": @[@1234, @"45678"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"123456"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @456789
    }];
    XCTAssertTrue(match);
}

- (void)testMatchContainsArrayEmpty {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @3,
                    @"propertyValue": @[]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    
    XCTAssertFalse(match);
}

- (void)testMatchContainsStringWithPropertyArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @3,
                    @"propertyValue": @"clever"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"clevertap",@"test"]
    }];
    
    XCTAssertTrue(match);
}

#pragma mark Not Contains
- (void)testMatchNotContainsArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @28,
                    @"propertyValue": @[@"testing", @"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"te"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"test"
    }];
    XCTAssertFalse(match);
}

- (void)testMatchNotContainsArrayFromTriggerArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @28,
                    @"propertyValue": @[@"testing", @"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"clevertap", @"yes"]
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchNotContainsString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @28,
                    @"propertyValue": @"test"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    
    XCTAssertTrue(match);
}
#pragma mark System and Notification properties
- (void)testMatchSystemProperties {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"CT SDK Version",
                    @"operator": @1,
                    @"propertyValue": @60000
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        CLTAP_SDK_VERSION: @60000
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
    }];
    XCTAssertFalse(match);
}

- (void)testMatchSystemPropertiesCurrentAndLegacy {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"CT SDK Version",
                    @"operator": @1,
                    @"propertyValue": @60000
                },
                @{
                    @"propertyName": @"ct_sdk_version",
                    @"operator": @1,
                    @"propertyValue": @60000
                },
                @{
                    @"propertyName": @"CT App Version",
                    @"operator": @1,
                    @"propertyValue": @"6.0.0"
                },
                @{
                    @"propertyName": @"ct_app_version",
                    @"operator": @1,
                    @"propertyValue": @"6.0.0"
                },
                @{
                    @"propertyName": @"ct_os_version",
                    @"operator": @1,
                    @"propertyValue": @"17.1.1"
                },
                @{
                    @"propertyName": @"CT OS Version",
                    @"operator": @1,
                    @"propertyValue": @"17.1.1"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        CLTAP_SDK_VERSION: @60000,
        CLTAP_APP_VERSION: @"6.0.0",
        CLTAP_OS_VERSION: @"17.1.1"
    }];
    XCTAssertTrue(match);
}

- (void)testMatchNotificationProperties {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Notification Viewed",
            @"eventProperties": @[
                @{
                    @"propertyName": CLTAP_PROP_CAMPAIGN_ID,
                    @"operator": @3,
                    @"propertyValue": @1701172437
                },
                @{
                    @"propertyName": CLTAP_PROP_WZRK_ID,
                    @"operator": @3,
                    @"propertyValue": @1701172437
                },
                @{
                    @"propertyName": CLTAP_PROP_VARIANT,
                    @"operator": @1,
                    @"propertyValue": CLTAP_NOTIFICATION_PIVOT_DEFAULT
                },
                @{
                    @"propertyName": CLTAP_PROP_WZRK_PIVOT,
                    @"operator": @1,
                    @"propertyValue": CLTAP_NOTIFICATION_PIVOT_DEFAULT
                },
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"Notification Viewed" eventProperties:@{
        CLTAP_PROP_WZRK_ID: @"1701172437_20231128",
        CLTAP_PROP_WZRK_PIVOT: CLTAP_NOTIFICATION_PIVOT_DEFAULT
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
    }];
    XCTAssertFalse(match);
}

#pragma mark GeoRadius
- (void)testMatchEventWithGeoRadius {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"geoRadius": @[
                @{
                    @"lat": @19.07609,
                    @"lng": @72.877426,
                    @"rad": @2
                }]
        }
    ];
    
    // Distance ~1.1km
    CLLocationCoordinate2D location1km = CLLocationCoordinate2DMake(19.08609, 72.877426);
    
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:@"event1" eventProperties:@{} andLocation:location1km];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:event];
    XCTAssertTrue(match);
    
    // Distance ~2.2km
    CLLocationCoordinate2D location2km = CLLocationCoordinate2DMake(19.09609, 72.877426);
    event = [[CTEventAdapter alloc] initWithEventName:@"event1" eventProperties:@{} andLocation:location2km];
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:event];
    XCTAssertFalse(match);
}

- (void)testMatchEventWithGeoRadiusButNotParams {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }],
            @"geoRadius": @[
                @{
                    @"lat": @19.07609,
                    @"lng": @72.877426,
                    @"rad": @2
                }]
        }
    ];
    
    // Distance ~1.1km
    CLLocationCoordinate2D location1km = CLLocationCoordinate2DMake(19.08609, 72.877426);
    
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:@"event1" eventProperties:@{@"prop1": @151} andLocation:location1km];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:event];
    XCTAssertFalse(match);
}

#pragma mark FirstTimeOnly

- (void)testMatchEventWithFirstTimeOnly {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"firstTimeOnly": @YES
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    CTLocalDataStore *dataStoreMock = OCMPartialMock(self.dataStore);
    id mockIsEventLoggedFirstTime = OCMStub([dataStoreMock isEventLoggedFirstTime:@"event1"]).andReturn(YES);
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{}];
    
    XCTAssertTrue(match);
    OCMVerify(mockIsEventLoggedFirstTime);
}

- (void)testMatchChargedEventWithFirstTimeOnly {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"firstTimeOnly": @YES,
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"propertyValue": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product_name",
                    @"operator": @1,
                    @"propertyValue": @"product 1"
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    
    CTLocalDataStore *dataStoreMock = OCMPartialMock(self.dataStore);
    id mockIsEventLoggedFirstTime = OCMStub([dataStoreMock isEventLoggedFirstTime:@"Charged"]).andReturn(YES);
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"prop1": @150,
    } items:@[
        @{
            @"product_name": @"product 1",
            @"price": @5.99
        },
        @{
            @"product_name": @"product 2",
            @"price": @5.50
        }
    ]];
    XCTAssertTrue(match);
    OCMVerify(mockIsEventLoggedFirstTime);
}

- (void)testMatchEventFirstTimeOnlyWithGeoRadius {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"firstTimeOnly": @YES,
            @"geoRadius": @[
                @{
                    @"lat": @19.07609,
                    @"lng": @72.877426,
                    @"rad": @2
                }]
        }
    ];
    
    // Distance ~1.1km
    CLLocationCoordinate2D location1km = CLLocationCoordinate2DMake(19.08609, 72.877426);
    
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:@"event1" eventProperties:@{} andLocation:location1km];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] initWithDataStore:self.dataStore];
    CTLocalDataStore *dataStoreMock = OCMPartialMock(self.dataStore);
    id mockIsEventLoggedFirstTime = OCMStub([dataStoreMock isEventLoggedFirstTime:@"event1"]).andReturn(YES);
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:event];
    XCTAssertTrue(match);
}

@end


