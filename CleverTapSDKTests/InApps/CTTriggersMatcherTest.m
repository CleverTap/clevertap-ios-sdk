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

@end
