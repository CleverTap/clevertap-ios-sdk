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
#import "CTEventAdapter.h"
#import "CTConstants.h"
#import "CTTriggerEvaluator.h"

@interface CTTriggersMatcher (Tests)
- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName eventProperties:(NSDictionary *)eventProperties;
- (BOOL)matchChargedEventWhenTriggers:(NSArray *)whenTriggers details:(NSDictionary *)details items:(NSArray<NSDictionary *> *)items;
@end

@implementation CTTriggersMatcher (Tests)

- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName eventProperties:(NSDictionary *)eventProperties {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];

    return [self matchEventWhenTriggers:whenTriggers event:event];
}

- (BOOL)matchChargedEventWhenTriggers:(NSArray *)whenTriggers details:(NSDictionary *)details items:(NSArray<NSDictionary *> *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_CHARGED_EVENT eventProperties:details location:kCLLocationCoordinate2DInvalid andItems:items];

    return [self matchEventWhenTriggers:whenTriggers event:event];
}

@end

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
                    @"operator": @1,
                    @"value": @150
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"value": @200
                },
                @{
                    @"propertyName": @"prop3",
                    @"operator": @1,
                    @"value": @150
                },
                @{
                    @"propertyName": @"prop4",
                    @"operator": @1,
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

- (void)testMatchEqualsNumbers {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"value": @150
                },
                @{
                    @"propertyName": @"prop2",
                    @"operator": @1,
                    @"value": @"200"
                },
                @{
                    @"propertyName": @"prop3",
                    @"operator": @1,
                    @"value": @[@150, @"200", @0.55]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
        @"prop1": @[@150, @"200"],
        @"prop2": @[@150, @200],
        @"prop3": @[@"200"]
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.00",
        @"prop2": @[@200.00],
        @"prop3": @[@"0.55"]
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.00",
        @"prop2": @[@200],
        @"prop3": @[@"0.56"]
    }];
    XCTAssertFalse(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@150],
        @"prop2": @"200",
        @"prop3": @[@"56"]
    }];
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
                    @"value": @(150.95)
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @150.950
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.950"
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@150, @"150.95"]
    }];
    XCTAssertTrue(match);
    
    match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150.96"
    }];
    XCTAssertFalse(match);
}

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
                    @"operator": @27
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
                    @"operator": @15,
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

- (void)testMatchEqualsExtectedStringWithActualArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"value": @"test"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @[@"test", @"test1"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @"test"
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"test"
    }];
    
    XCTAssertTrue(match);
}

- (void)testMatchEqualsExtectedNumberWithActualNumbericalString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"value": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150"
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
                    @"value": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @150.99
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @150.99
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @[@"test", @"test2", @"test3"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @[@1, @2, @3]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @[@3, @1, @2]
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
                    @"operator": @2,
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
                    @"value": @240
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"-120"
    }];
    
    XCTAssertTrue(match);
    
    BOOL matchNaN = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"asd"
    }];
    
    XCTAssertFalse(matchNaN);
}

- (void)testMatchGreaterThan {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @0,
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
                    @"value": @150
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"240"
    }];
    
    XCTAssertTrue(match);
    
    BOOL matchNaN = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"asd"
    }];
    
    XCTAssertFalse(matchNaN);
}

- (void)testMatchBetween {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @4,
                    @"value": @[@100, @240]
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

- (void)testMatchBetweenWithString {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @4,
                    @"value": @[@100, @240]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"150"
    }];
    
    XCTAssertTrue(match);
    
    BOOL matchNan = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"a150"
    }];
    
    XCTAssertFalse(matchNan);
}

- (void)testMatchBetweenArrayMoreThan2 {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @4,
                    @"value": @[@100, @240, @330, @"test"]
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
                    @"operator": @4,
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
                    @"operator": @3,
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
                    @"operator": @3,
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
                    @"operator": @3,
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
                    @"operator": @3,
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
                    @"operator": @28,
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

- (void)testMatchNotContainsArrayFromTriggerArray {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @28,
                    @"value": @[@"testing", @"test"]
                }
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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

- (void)testMatchEventWithoutProps {
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"event1",
            @"eventProperties": @[
            ]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{
        @"prop1": @"clevertap"
    }];
    
    BOOL matchNoProps = [triggerMatcher matchEventWhenTriggers:whenTriggers eventName:@"event1" eventProperties:@{}];
    
    XCTAssertTrue(match);
    XCTAssertTrue(matchNoProps);
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
                    @"value": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product_name",
                    @"operator": @1,
                    @"value": @"product 1"
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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

- (void)testMatchChargedEventItemArrayEquals {
    
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"value": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product_name",
                    @"operator": @1,
                    @"value": @[@"product 1", @"product 2"]
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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

- (void)testMatchChargedEventItemArrayContains {
    
    NSArray *whenTriggers = @[
        @{
            @"eventName": @"Charged",
            @"eventProperties": @[
                @{
                    @"propertyName": @"prop1",
                    @"operator": @1,
                    @"value": @150
                }],
            @"itemProperties": @[
                @{
                    @"propertyName": @"product_name",
                    @"operator": @3,
                    @"value": @[@"product 1", @"product 2"]
                }]
        }
    ];
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
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
                    @"value": @150
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
    
    CTTriggersMatcher *triggerMatcher = [[CTTriggersMatcher alloc] init];
    
    BOOL match = [triggerMatcher matchEventWhenTriggers:whenTriggers event:event];
    XCTAssertFalse(match);
}

@end
