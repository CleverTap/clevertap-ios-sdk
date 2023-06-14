//
//  NSDictionaryExtensionsTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 9.06.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NSDictionary+Extensions.h"

@interface NSDictionaryExtensionsTest : XCTestCase
@end

@implementation NSDictionaryExtensionsTest

- (void)testTransformNumberValuesWithBlock {
    NSDictionary<NSString *, id> *originalDictionary = @{@"key1": @1, @"key2": @2, @"key3": @3};
    
    NSDictionary<NSString *, id> *transformedDictionary = [originalDictionary dictionaryWithTransformUsingBlock:^id(id value) {
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *numberValue = (NSNumber *)value;
            return @(numberValue.integerValue * 2);
        }
        return value;
    }];
    
    NSDictionary<NSString *, id> *expectedDictionary = @{@"key1": @2, @"key2": @4, @"key3": @6};
    
    XCTAssertNotEqualObjects(originalDictionary, transformedDictionary, @"Transformation should not change original dictionary.");
    XCTAssertEqualObjects(transformedDictionary, expectedDictionary, @"Transformed dictionary should match the expected dictionary.");
}

- (void)testTransformValuesWithBlock {
    NSDictionary *originalDictionary = @{
        @"str": @"str",
        @"dict": @{
            @"test": @123,
        }
    };
    
    NSDictionary *transformedDictionary = [originalDictionary dictionaryWithTransformUsingBlock:^id(id value) {
        if ([value isKindOfClass:[NSString class]]) {
            value = @"mod";
            return value;
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            value = @{ @"mod": @"mod" };
            return value;
        }
        return value;
    }];
    
    NSDictionary *expectedDictionary = @{
        @"str": @"mod",
        @"dict": @{
            @"mod": @"mod"
        }
    };
    
    XCTAssertNotEqualObjects(originalDictionary, transformedDictionary, @"Transformation should not change original dictionary.");
    XCTAssertEqualObjects(transformedDictionary, expectedDictionary, @"Transformed dictionary should match the expected dictionary.");
}

- (void)testTransformMutableValuesWithBlock {
    NSDictionary *originalDictionary = @{
        @"mstr": [[NSMutableString alloc] initWithString:@"mstr"],
        @"mdict": [@{
            @"test": @123,
        } mutableCopy]
    };
    
    NSDictionary *transformedDictionary = [originalDictionary dictionaryWithTransformUsingBlock:^id(id value) {
        if ([value isKindOfClass:[NSMutableString class]]) {
            [value appendString:@"mod"];
            return value;
        } else if ([value isKindOfClass:[NSMutableDictionary class]]) {
            value[@"mod"] = @"mod";
            return value;
        }
        return value;
    }];
    
    NSDictionary *expectedDictionary = @{
        @"mstr": @"mstrmod",
        @"mdict": @{
            @"test": @123,
            @"mod": @"mod"
        }
    };
    
    XCTAssertEqualObjects(originalDictionary, transformedDictionary,
                          @"Transformation should change original dictionary since its values are mutable and transformation does not deep copy.");
    XCTAssertEqualObjects(transformedDictionary, expectedDictionary, @"Transformed dictionary should match the expected dictionary.");
}

- (void)testRemoveNullValues {
    NSDictionary<NSString *, id> *originalDictionary = @{@"key1": @"value1",
                                                        @"key2": [NSNull null],
                                                        @"key3": @"value3",
                                                        @"key4": [NSNull null]};
    
    NSDictionary<NSString *, id> *expectedDictionary = @{@"key1": @"value1",
                                                         @"key3": @"value3"};
    
    NSDictionary<NSString *, id> *transformedDictionary = [originalDictionary dictionaryRemovingNullValues];
    
    XCTAssertEqualObjects(transformedDictionary, expectedDictionary, @"Transformed dictionary should match the expected dictionary.");
}

@end
