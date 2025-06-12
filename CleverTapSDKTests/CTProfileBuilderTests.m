//
//  CTProfileBuilderTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 12/06/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTProfileBuilder.h"
#import "CTValidationResult.h"
#import "CTValidator.h"
#import "CTLocalDataStore.h"
#import "CTKnownProfileFields.h"
#import "CTProfileBuilder+Tests.h"

@interface CTProfileBuilderTests : XCTestCase
@property (nonatomic, strong) CTLocalDataStore *mockDataStore;
@end

@implementation CTProfileBuilderTests

- (void)setUp {
    [super setUp];
    self.mockDataStore = [[CTLocalDataStore alloc] init];
}

- (void)tearDown {
    self.mockDataStore = nil;
    [super tearDown];
}

#pragma mark - Profile Building Tests

- (void)testBuildProfileWithValidData {
    NSDictionary *profile = @{
        @"Name": @"John Doe",
        @"Email": @"john@example.com",
        @"Age": @30,
        @"customField": @"customValue"
    };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Profile build completion"];
    
    [CTProfileBuilder build:profile completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(customFields);
        XCTAssertNotNil(systemFields);
        XCTAssertNotNil(errors);
        
        XCTAssertTrue(customFields.count > 0 || systemFields.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildProfileWithEmptyProfile {
    NSDictionary *profile = @{};
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Profile build completion"];
    
    [CTProfileBuilder build:profile completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(systemFields);
        XCTAssertNotNil(errors);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildProfileWithInvalidKey {
    NSDictionary *profile = @{
        @"": @"value",
        @"validKey": @"validValue"
    };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Profile build completion"];
    
    [CTProfileBuilder build:profile completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        BOOL hasInvalidKeyError = NO;
        for (CTValidationResult *error in errors) {
            if ([error errorCode] == 512) {
                hasInvalidKeyError = YES;
                break;
            }
        }
        XCTAssertTrue(hasInvalidKeyError);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Remove Value Tests

- (void)testBuildRemoveValueForValidKey {
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove value completion"];
    
    [CTProfileBuilder buildRemoveValueForKey:key completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(customFields);
        XCTAssertNil(systemFields);
        XCTAssertNotNil(errors);
        
        NSDictionary *keyDict = customFields[key];
        XCTAssertNotNil(keyDict);
        XCTAssertTrue([keyDict[@"$delete"] boolValue]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildRemoveValueForEmptyKey {
    NSString *key = @"";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove value completion"];
    
    [CTProfileBuilder buildRemoveValueForKey:key completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(systemFields);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Multi-Value Tests

- (void)testBuildSetMultiValues {
    NSArray *values = @[@"value1", @"value2", @"value3"];
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set multi-value completion"];
    
    [CTProfileBuilder buildSetMultiValues:values forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(customFields);
        XCTAssertNotNil(updatedMultiValue);
        XCTAssertNotNil(errors);
        
        NSDictionary *keyDict = customFields[key];
        XCTAssertNotNil(keyDict);
        XCTAssertNotNil(keyDict[@"$set"]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildAddMultiValue {
    NSString *value = @"newValue";
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Add multi-value completion"];
    
    [CTProfileBuilder buildAddMultiValue:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(customFields);
        XCTAssertNotNil(updatedMultiValue);
        XCTAssertNotNil(errors);
        
        NSDictionary *keyDict = customFields[key];
        XCTAssertNotNil(keyDict);
        XCTAssertNotNil(keyDict[@"$add"]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildAddMultiValueWithEmptyValue {
    NSString *value = @"";
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Add multi-value completion"];
    
    [CTProfileBuilder buildAddMultiValue:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(updatedMultiValue);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildAddMultiValues {
    NSArray *values = @[@"value1", @"value2"];
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Add multi-values completion"];
    
    [CTProfileBuilder buildAddMultiValues:values forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(customFields);
        XCTAssertNotNil(updatedMultiValue);
        XCTAssertNotNil(errors);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildRemoveMultiValue {
    NSString *value = @"valueToRemove";
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove multi-value completion"];
    
    [CTProfileBuilder buildRemoveMultiValue:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(errors);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildRemoveMultiValueWithEmptyValue {
    NSString *value = @"";
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove multi-value completion"];
    
    [CTProfileBuilder buildRemoveMultiValue:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(updatedMultiValue);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildRemoveMultiValues {
    NSArray *values = @[@"value1", @"value2"];
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove multi-values completion"];
    
    [CTProfileBuilder buildRemoveMultiValues:values forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(errors);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleMultiValuesWithNilKey {
    NSArray *values = @[@"value1"];
    NSString *key = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handle multi-values completion"];
    
    [CTProfileBuilder buildAddMultiValues:values forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(updatedMultiValue);
        XCTAssertNotNil(errors);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testHandleMultiValuesWithEmptyValues {
    NSArray *values = @[];
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Handle multi-values completion"];
    
    [CTProfileBuilder buildAddMultiValues:values forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(customFields);
        XCTAssertNil(updatedMultiValue);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Increment/Decrement Tests

- (void)testBuildIncrementValueBy {
    NSNumber *value = @5;
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Increment value completion"];
    
    [CTProfileBuilder buildIncrementValueBy:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *operatorDict, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(operatorDict);
        XCTAssertNil(errors);
        
        NSDictionary *keyDict = operatorDict[key];
        XCTAssertNotNil(keyDict);
        XCTAssertNotNil(keyDict[@"$incr"]);
        XCTAssertEqualObjects(keyDict[@"$incr"], value);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildDecrementValueBy {
    NSNumber *value = @3;
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Decrement value completion"];
    
    [CTProfileBuilder buildDecrementValueBy:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *operatorDict, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(operatorDict);
        XCTAssertNil(errors);
        
        NSDictionary *keyDict = operatorDict[key];
        XCTAssertNotNil(keyDict);
        XCTAssertNotNil(keyDict[@"$decr"]);
        XCTAssertEqualObjects(keyDict[@"$decr"], value);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildIncrementWithEmptyKey {
    NSNumber *value = @5;
    NSString *key = @"";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Increment value completion"];
    
    [CTProfileBuilder buildIncrementValueBy:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *operatorDict, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(operatorDict);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildIncrementWithZeroValue {
    NSNumber *value = @0;
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Increment value completion"];
    
    [CTProfileBuilder buildIncrementValueBy:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *operatorDict, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(operatorDict);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildIncrementWithNegativeValue {
    NSNumber *value = @(-5);
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Increment value completion"];
    
    [CTProfileBuilder buildIncrementValueBy:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *operatorDict, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(operatorDict);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testBuildDecrementWithNegativeValue {
    NSNumber *value = @(-3);
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Decrement value completion"];
    
    [CTProfileBuilder buildDecrementValueBy:value forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *operatorDict, NSArray<CTValidationResult *> *errors) {
        XCTAssertNil(operatorDict);
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - Utility Tests

- (void)testGetJSONKeyWithValidKey {
    NSDictionary *jsonObject = @{@"key1": @"value1", @"key2": @"value2"};
    
    id result = [CTProfileBuilder getJSONKey:jsonObject forKey:@"key1" withDefault:@"default"];
    XCTAssertEqualObjects(result, @"value1");
}

- (void)testGetJSONKeyWithInvalidKey {
    NSDictionary *jsonObject = @{@"key1": @"value1", @"key2": @"value2"};
    
    id result = [CTProfileBuilder getJSONKey:jsonObject forKey:@"nonexistent" withDefault:@"default"];
    XCTAssertEqualObjects(result, @"default");
}

- (void)testGetJSONKeyWithNilObject {
    id result = [CTProfileBuilder getJSONKey:nil forKey:@"key1" withDefault:@"default"];
    XCTAssertEqualObjects(result, @"default");
}

#pragma mark - Edge Cases

- (void)testBuildProfileWithMixedValidInvalidData {
    NSDictionary *profile = @{
        @"validKey": @"validValue",
        @"": @"invalidKey",
        @"anotherValidKey": @123
    };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Profile build completion"];
    
    [CTProfileBuilder build:profile completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(errors);
        XCTAssertTrue(errors.count > 0);
        
        XCTAssertTrue(customFields.count > 0 || systemFields.count > 0);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testMultiValueWithNonStringValues {
    NSArray *values = @[@123, @456.78, @YES];
    NSString *key = @"testKey";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Multi-value with non-string completion"];
    
    [CTProfileBuilder buildSetMultiValues:values forKey:key localDataStore:self.mockDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult *> *errors) {
        XCTAssertNotNil(errors);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
