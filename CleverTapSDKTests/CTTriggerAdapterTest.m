//
//  CTTriggerAdapterTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTTriggerAdapter.h"
#import "CTTriggerCondition.h"
#import "CTTriggerRadius.h"

@interface CTTriggerAdapterTest : XCTestCase
@end

@implementation CTTriggerAdapterTest

#pragma mark - eventName

- (void)test_initWithJSON_setsEventName {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{@"eventName": @"Purchase"}];
    XCTAssertEqualObjects(adapter.eventName, @"Purchase");
}

- (void)test_profileAttrName_setsFromJSON {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{@"profileAttrName": @"age"}];
    XCTAssertEqualObjects(adapter.profileAttrName, @"age");
}

- (void)test_firstTimeOnly_setsFromJSON {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{@"firstTimeOnly": @YES}];
    XCTAssertTrue(adapter.firstTimeOnly);
}

#pragma mark - propertyCount

- (void)test_propertyCount_withNilProperties_returnsZero {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{@"eventName": @"Viewed"}];
    XCTAssertEqual(adapter.propertyCount, 0);
}

- (void)test_propertyCount_withProperties_returnsCount {
    NSDictionary *json = @{
        @"eventName": @"Viewed",
        @"eventProperties": @[
            @{@"propertyName": @"category", @"operator": @1, @"propertyValue": @"shoes"},
            @{@"propertyName": @"price", @"operator": @0, @"propertyValue": @50}
        ]
    };
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:json];
    XCTAssertEqual(adapter.propertyCount, 2);
}

#pragma mark - itemsCount

- (void)test_itemsCount_withNilItems_returnsZero {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{}];
    XCTAssertEqual(adapter.itemsCount, 0);
}

- (void)test_itemsCount_withItems_returnsCount {
    NSDictionary *json = @{
        @"itemProperties": @[
            @{@"propertyName": @"color", @"operator": @1, @"propertyValue": @"red"}
        ]
    };
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:json];
    XCTAssertEqual(adapter.itemsCount, 1);
}

#pragma mark - geoRadiusCount

- (void)test_geoRadiusCount_withNilGeoRadius_returnsZero {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{}];
    XCTAssertEqual(adapter.geoRadiusCount, 0);
}

- (void)test_geoRadiusCount_withGeoRadius_returnsCount {
    NSDictionary *json = @{
        @"geoRadius": @[
            @{@"lat": @12.9, @"lng": @77.6, @"rad": @500}
        ]
    };
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:json];
    XCTAssertEqual(adapter.geoRadiusCount, 1);
}

#pragma mark - propertyAtIndex

- (void)test_propertyAtIndex_returnsCorrectCondition {
    NSDictionary *json = @{
        @"eventProperties": @[
            @{@"propertyName": @"age", @"operator": @1, @"propertyValue": @30}
        ]
    };
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:json];
    CTTriggerCondition *cond = [adapter propertyAtIndex:0];
    XCTAssertNotNil(cond);
    XCTAssertEqualObjects(cond.propertyName, @"age");
    XCTAssertEqual(cond.op, CTTriggerOperatorEquals);
    XCTAssertEqualObjects(cond.value.numberValue, @30);
}

- (void)test_propertyAtIndex_nilProperties_returnsNil {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{}];
    XCTAssertNil([adapter propertyAtIndex:0]);
}

#pragma mark - geoRadiusAtIndex

- (void)test_geoRadiusAtIndex_returnsLatLonRadius {
    NSDictionary *json = @{
        @"geoRadius": @[
            @{@"lat": @12.9716, @"lng": @77.5946, @"rad": @1000}
        ]
    };
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:json];
    CTTriggerRadius *geo = [adapter geoRadiusAtIndex:0];
    XCTAssertNotNil(geo);
    XCTAssertEqualObjects(geo.latitude, @12.9716);
    XCTAssertEqualObjects(geo.longitude, @77.5946);
    XCTAssertEqualObjects(geo.radius, @1000);
}

- (void)test_geoRadiusAtIndex_nilGeoRadius_returnsNil {
    CTTriggerAdapter *adapter = [[CTTriggerAdapter alloc] initWithJSON:@{}];
    XCTAssertNil([adapter geoRadiusAtIndex:0]);
}

@end
