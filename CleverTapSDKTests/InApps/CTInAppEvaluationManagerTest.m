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

@interface CTInAppEvaluationManager(Test)
- (void)sortByPriority:(NSMutableArray *)inApps;
@end

@interface CTInAppEvaluationManagerTest : XCTestCase

@end

@implementation CTInAppEvaluationManagerTest

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
        }]
    mutableCopy];
    
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
    
    CTInAppEvaluationManager *manager = [CTInAppEvaluationManager new];
    [manager sortByPriority:inApps];
    
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
        }]
    mutableCopy];
    
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
    
    CTInAppEvaluationManager *manager = [CTInAppEvaluationManager new];
    [manager sortByPriority:inApps];
    
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
        }]
    mutableCopy];
    
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
    
    CTInAppEvaluationManager *manager = [CTInAppEvaluationManager new];
    [manager sortByPriority:inApps];
    
    XCTAssertEqualObjects(inApps, expectedInApps);
}


@end
