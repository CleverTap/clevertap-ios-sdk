//
//  CTTriggersMatcherTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 4.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTTriggersMatcher.h"

@interface CTTriggersMatcherTest : XCTestCase

@end

@implementation CTTriggersMatcherTest

- (void)testMatchEqualsPrimitives {
    
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"equals",
                    @"value": @150
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @"equals",
                    @"value": @200
                },
                @{
                    @"propertyName": @"prop3",
                    @"operator": @"equals",
                    @"value": @150
                },
                @{
                    @"propertyName": @"prop4",
                    @"operator": @"equals",
                    @"value": @"CleverTap"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150,
        @"prop2": @200,
        @"prop3": @"150",
        @"prop4": @"CleverTap"
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchChargedEvent {
    
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"equals",
                    @"value": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"equals",
                    @"value": @150
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchChargedEventWhenTriggers:whenTriggers details:@{
        @"prop3": @3,
        @"prop4": @4
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
    
    // TODO: do a proper charged test
    XCTAssertFalse(match);
}

- (void)testMatchSet {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"set"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchNotSet {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"not_set"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop2": @150
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchNotEquals {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"not_equals",
                    @"value": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @240
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchLessThan {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"less_than",
                    @"value": @240
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchGreaterThan {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"greater_than",
                    @"value": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @240
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchBetween {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"between",
                    @"value": @[@100,@240]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchBetweenArrayMoreThan2 {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"between",
                    @"value": @[@100,@240,@330,@"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"operator": @"between",
                    @"value": @[]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150
    }];
    
    XCTAssertFalse(match);
}

- (void)testMatchContainsString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"contains",
                    @"value": @"clever"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchContainsArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"contains",
                    @"value": @[@"clever", @"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
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
                    @"operator": @"contains",
                    @"value": @[]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"operator": @"contains",
                    @"value": @"clever"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@"clevertap",@"test"]
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchNotContainsArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @"not_contains",
                    @"value": @[@"testing", @"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
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
                    @"operator": @"not_contains",
                    @"value": @"test"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    
    XCTAssertTrue(match);
}

@end
