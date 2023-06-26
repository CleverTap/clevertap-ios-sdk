//
//  CTValidationResultStackTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 27/04/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTValidationResultStack.h"
//#import <objc/runtime.h>

@interface CTValidationResultStackTest : XCTestCase

@property (nonatomic, strong) CTValidationResultStack *classObject;
@property (nonatomic, strong) CleverTapInstanceConfig *classConfig;

@end

@interface CTValidationResultStack (Tests)
@property (nonatomic, strong) NSMutableArray<CTValidationResult *> *pendingValidationResults;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@end

@implementation CTValidationResultStackTest

- (void)setUp {
    [super setUp];
    self.classConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    self.classObject = [[CTValidationResultStack alloc] initWithConfig:self.classConfig];
}

- (void)tearDown {
    self.classObject = nil;
    [super tearDown];
}

- (void)test_initWithConfig {
    XCTAssertNotNil(self.classObject);
    XCTAssertEqual(self.classConfig, self.classObject.config);
    XCTAssertNotNil(self.classObject.pendingValidationResults);
    XCTAssertTrue(self.classObject.pendingValidationResults.count == 0);
}

-(void)test_pushValidationResults_withSingleValue {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.object = @"testObject";
    NSArray<CTValidationResult *> *results = @[result];
       
    [self.classObject pushValidationResults:results];
       
    XCTAssertEqual(self.classObject.pendingValidationResults.count, 1);
    XCTAssertTrue([self.classObject.pendingValidationResults containsObject:result]);
}

-(void)test_pushValidationResults_withMultipleValues {
    CTValidationResult *result1 = [[CTValidationResult alloc] init];
    result1.object = @"testObject1";
    CTValidationResult *result2 = [[CTValidationResult alloc] init];
    result2.object = @"testObject2";
    
    NSArray<CTValidationResult *> *results = @[result1,result2];
       
    [self.classObject pushValidationResults:results];
       
    XCTAssertEqual(self.classObject.pendingValidationResults.count, 2);
    XCTAssertTrue([self.classObject.pendingValidationResults containsObject:result1]);
    XCTAssertTrue([self.classObject.pendingValidationResults containsObject:result2]);
}

-(void)test_pushValidationResults_withMaxInputs {
    NSMutableArray<CTValidationResult *> *results = [NSMutableArray array];
    for (int i = 0; i<51; i++) {
        CTValidationResult *result = [[CTValidationResult alloc] init];
        result.object = @"testObject";
        [results addObject:result];
    }
       
    [self.classObject pushValidationResults:results];
       
    XCTAssertFalse([self.classObject.pendingValidationResults containsObject:results[0]]);
}

-(void)test_pushValidationResults_withNilInput {
    NSArray<CTValidationResult *> *results = nil;
    [self.classObject pushValidationResults:results];
        
    XCTAssertEqual(self.classObject.pendingValidationResults.count, 0);
}

-(void)test_pushValidationResults_withEmptyInput {
    NSArray<CTValidationResult *> *results = @[];
    [self.classObject pushValidationResults:results];
        
    XCTAssertEqual(self.classObject.pendingValidationResults.count, 0);
}

-(void)test_pushValidationResult {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.object = @"testObject";
       
    [self.classObject pushValidationResult:result];
       
    XCTAssertTrue([self.classObject.pendingValidationResults containsObject:result]);
}

-(void)test_popValidationResult {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    result.object = @"testObject";
    [self.classObject pushValidationResult:result];
    CTValidationResult *popedResult = [self.classObject popValidationResult];
       
    XCTAssertFalse([self.classObject.pendingValidationResults containsObject:popedResult]);
}

@end
