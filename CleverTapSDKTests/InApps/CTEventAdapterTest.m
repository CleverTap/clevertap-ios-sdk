//
//  CTEventAdapterTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 27.11.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTEventAdapter.h"
#import "CTConstants.h"

@interface CTEventAdapterTest : XCTestCase

@end

@implementation CTEventAdapterTest

- (void)testPropertyValueNamed {
    NSString *value = @"value";
    NSDictionary *eventProperties = @{
        @"prop1": value
    };
    CTEventAdapter *eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@"prop1"] stringValue]);
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@" prop 1 "] stringValue]);
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@"Prop1"] stringValue]);
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@"Prop 1"] stringValue]);
    XCTAssertNil([eventAdapter propertyValueNamed:@"Prop 1 1"]);
    
    eventProperties = @{
        @"prop 1": value
    };
    eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@"prop1"] stringValue]);
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@" prop 1 "] stringValue]);
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@"Prop1"] stringValue]);
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@"Prop 1"] stringValue]);
    
    eventProperties = @{
        @"prop 1": @"value1",
        @"prop1": value,
        @"Prop 1": @"value2"
    };
    eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(value, [[eventAdapter propertyValueNamed:@"prop1"] stringValue]);
    XCTAssertEqualObjects(eventProperties[@"Prop 1"], [[eventAdapter propertyValueNamed:@"Prop 1"] stringValue]);
    // The dictionary is unordered - the order is not the same as defined in code
    NSString *firstPropertyKey = eventAdapter.eventProperties.allKeys[0];
    NSString *expectedValue = eventAdapter.eventProperties[firstPropertyKey];
    XCTAssertEqualObjects(expectedValue, [[eventAdapter propertyValueNamed:@" prop  1"] stringValue]);
    
    eventProperties = @{
        @"prop 1": @"value1",
        @"prop  1": @"value2",
        @"Prop 1": @"value3",
    };
    eventAdapter = [self eventAdapterWithProperties:eventProperties];
    // The dictionary is unordered - the order is not the same as defined in code
    firstPropertyKey = eventAdapter.eventProperties.allKeys[0];
    expectedValue = eventAdapter.eventProperties[firstPropertyKey];
    XCTAssertEqualObjects(expectedValue, [[eventAdapter propertyValueNamed:@"prop1"] stringValue]);
}

- (void)testSystemPropertyValueNamed {
    NSDictionary *eventProperties = @{
        CLTAP_PROP_WZRK_ID: @"wzrk_id value",
        CLTAP_APP_VERSION: @"Version value",
        CLTAP_SDK_VERSION: @"SDK Version value"
    };
    CTEventAdapter *eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(@"wzrk_id value", [[eventAdapter propertyValueNamed:CLTAP_PROP_CAMPAIGN_ID] stringValue]);
    XCTAssertEqualObjects(@"Version value", [[eventAdapter propertyValueNamed:@"CT App Version"] stringValue]);
    XCTAssertEqualObjects(@"SDK Version value", [[eventAdapter propertyValueNamed:@"CT SDK Version"] stringValue]);
    
    eventProperties = @{
        CLTAP_PROP_CAMPAIGN_ID: @"Campaign id value",
    };
    eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(@"Campaign id value", [[eventAdapter propertyValueNamed:CLTAP_PROP_WZRK_ID] stringValue]);
    
    eventProperties = @{
        CLTAP_PROP_VARIANT: @"Variant value"
    };
    eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(@"Variant value", [[eventAdapter propertyValueNamed:CLTAP_PROP_WZRK_PIVOT] stringValue]);
    
    eventProperties = @{
        CLTAP_PROP_WZRK_PIVOT: @"wzrk_pivot value",
    };
    eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(@"wzrk_pivot value", [[eventAdapter propertyValueNamed:CLTAP_PROP_VARIANT] stringValue]);
}

- (void)testSystemPropertyValueNamedNormalized {
    NSDictionary *eventProperties = @{
        CLTAP_PROP_WZRK_ID: @"wzrk_id value",
        CLTAP_APP_VERSION: @"Version value",
    };
    CTEventAdapter *eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(@"wzrk_id value", [[eventAdapter propertyValueNamed:CLTAP_PROP_CAMPAIGN_ID] stringValue]);
    XCTAssertEqualObjects(@"Version value", [[eventAdapter propertyValueNamed:@"CT App Version"] stringValue]);
    // The system property names must be exact match
    XCTAssertNil([eventAdapter propertyValueNamed:CLTAP_PROP_CAMPAIGN_ID.lowercaseString]);
    XCTAssertNil([eventAdapter propertyValueNamed:@"CT App Version".lowercaseString]);
    XCTAssertNil([eventAdapter propertyValueNamed:@"CTApp Version"]);
    
    // The property name is normalized if it matches the system property name evaluated
    eventProperties = @{
        // CLTAP_PROP_WZRK_ID @"wzrk_id"
        @"wzrk_ID": @"wzrk_id value",
        // CLTAP_APP_VERSION @"Version"
        @"version": @"Version value"
    };
    eventAdapter = [self eventAdapterWithProperties:eventProperties];
    XCTAssertEqualObjects(@"wzrk_id value", [[eventAdapter propertyValueNamed:CLTAP_PROP_CAMPAIGN_ID] stringValue]);
    XCTAssertEqualObjects(@"Version value", [[eventAdapter propertyValueNamed:@"CT App Version"] stringValue]);
}
    
- (void)testItemValueNamed {
    NSArray *items = @[
        @{
            @"productName": @"product 1",
            @"price": @5.99
        },
        @{
            @"productName": @"product 2",
            @"price": @5.50
        }];
    CTEventAdapter *eventAdapter = [self eventAdapterWithItems:items];
    XCTAssertEqualObjects((@[@"product 1", @"product 2"]), [[eventAdapter itemValueNamed:@"productName"] arrayValue]);
    XCTAssertEqualObjects((@[@5.99, @5.50]), [[eventAdapter itemValueNamed:@"price"] arrayValue]);
    XCTAssertNil([eventAdapter itemValueNamed:@"none"]);
    
    // Nil Items
    CTEventAdapter *eventAdapterNilItems = [self eventAdapterWithItems:nil];
    XCTAssertNil([eventAdapterNilItems itemValueNamed:@"none"]);
}

- (void)testItemValueNamedNormalized {
    NSArray *items = @[
        @{
            @"productName": @"product 1"
        },
        @{
            @"productName": @"product 2"
        }];
    NSArray *expectedProductNames = @[@"product 1", @"product 2"];
    
    CTEventAdapter *eventAdapter = [self eventAdapterWithItems:items];
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"productName"] arrayValue]);
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"ProductName"] arrayValue]);
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"product Name"] arrayValue]);
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"Product Name"] arrayValue]);
}

- (void)testItemValueNamedNormalizedItem {
    NSArray *items = @[
        @{
            @"product Name": @"product 1"
        },
        @{
            @"ProductName": @"product 2"
        },
        @{
            @"Product Name": @"product 3"
        },
        @{
            @"product name": @"product 4"
        },
        @{
            @"product_name": @"product 5"
        }];
    NSArray *expectedProductNames = @[@"product 1", @"product 2", @"product 3", @"product 4"];
    
    CTEventAdapter *eventAdapter = [self eventAdapterWithItems:items];
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"productName"] arrayValue]);
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"ProductName"] arrayValue]);
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"product Name"] arrayValue]);
    XCTAssertEqualObjects(expectedProductNames, [[eventAdapter itemValueNamed:@"Product Name"] arrayValue]);
    
    XCTAssertEqualObjects((@[@"product 5"]), [[eventAdapter itemValueNamed:@"product_name"] arrayValue]);
    XCTAssertEqualObjects((@[@"product 5"]), [[eventAdapter itemValueNamed:@"Product_Name"] arrayValue]);
}

- (CTEventAdapter *)eventAdapterWithProperties:(NSDictionary *)eventProperties {
    return [[CTEventAdapter alloc] initWithEventName:@"event" eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];
}

- (CTEventAdapter *)eventAdapterWithItems:(NSArray *)items {
    return [[CTEventAdapter alloc] initWithEventName:@"event" eventProperties:@{} location:kCLLocationCoordinate2DInvalid andItems:items];
}

@end
