//
//  CTVarCacheTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 01/03/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTVarCache.h"
#import <OCMock/OCMock.h>
#import "CTUtils.h"
#import "CTPreferences.h"
#import "CTVarCache+Tests.h"
#import "CTConstants.h"
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>

@interface CTVarTests : XCTestCase

@end

CTVarCache *varCache;

@implementation CTVarTests

- (void)setUp {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    config.useCustomCleverTapId = YES;
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc]initWithConfig:config andCleverTapID:@"test"];
    varCache = [[CTVarCache alloc]initWithConfig:config deviceInfo:deviceInfo];
}

- (void)tearDown {
    varCache = nil;
}

- (void)testVarCacheNotNil {
    XCTAssertNotNil(varCache);
}

- (void)testVarCacheFetchesNameComponents {
    NSString *component1 = @"Primary";
    NSString *component2 = @"Secondary";
    NSString *component3 = @"Tertiary";
    NSArray *nameComponents = [varCache getNameComponents:[NSString stringWithFormat:@"%@.%@.%@",component1,component2,component3]];
    XCTAssertNotNil(nameComponents);
    
    BOOL expression = [nameComponents containsObject:component1] && [nameComponents containsObject:component2] && [nameComponents containsObject:component3];
    XCTAssertTrue(expression);
    
    XCTAssertTrue(nameComponents.count == 3);
}

- (void)testVarCacheResgitersVars {
    CTVar *varMock = OCMPartialMock([varCache define:@"test" with:@"test" kind:CT_KIND_STRING]);
    [varCache registerVariable:varMock];
    
    XCTAssertEqual(varCache.vars[varMock.name], varMock);
}

- (void)testVarCacheGetVarsForName {
    NSString *varName = @"test";
    CTVar *var = [varCache define:varName with:@"test" kind:CT_KIND_STRING];
    CTVar *varResult = [varCache getVariable:varName];
    
    XCTAssertEqual(varResult, var);
}

- (void)testVarCacheSavesDiffs {
    id varCacheMock = OCMPartialMock(varCache);
    [varCacheMock define:@"Title" with:@"Hello" kind:CT_KIND_STRING];
    
    NSDictionary *updatedVarsFromServer = @{
        @"Title": @"TitleUpdated",
    };
    NSString *varsJson = [CTUtils dictionaryToJsonString:updatedVarsFromServer];
    [varCacheMock applyVariableDiffs:updatedVarsFromServer];
    OCMVerify([varCacheMock saveDiffs]);
    XCTAssertTrue([varCacheMock hasReceivedDiffs]);
    
    NSString *fileName = [varCacheMock getArchiveFileName];
    NSString *filePath = [CTPreferences filePathfromFileName:fileName];
    NSData *diffsData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    
    // TODO: fix only available check
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:diffsData error:&error];
    XCTAssertNil(error);
    unarchiver.requiresSecureCoding = NO;
    NSDictionary *loadedVars = (NSDictionary *) [unarchiver decodeObjectForKey:CLEVERTAP_DEFAULTS_VARIABLES_KEY];
    XCTAssertTrue([updatedVarsFromServer isEqualToDictionary:loadedVars]);
    
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

- (void)testVarCacheLoadsDiffs {
    NSString *varName = @"Title";
    NSString *initialVarValue = @"Hello";
    NSString *updatedVarValue = @"TitleUpdated";
    CTVarCache *varCacheMock = OCMPartialMock(varCache);
    [varCacheMock define:varName with:initialVarValue kind:CT_KIND_STRING];
    
    NSDictionary *updatedVarsFromServer = @{
        varName: updatedVarValue,
    };
    NSString *varsJson = [CTUtils dictionaryToJsonString:updatedVarsFromServer];
    [varCacheMock applyVariableDiffs:updatedVarsFromServer];
    OCMVerify([varCacheMock saveDiffs]);
    XCTAssertTrue([varCacheMock hasReceivedDiffs]);
    
    [varCacheMock setSilent:YES];
    [varCacheMock loadDiffs];
    CTVar *loadedVar = varCacheMock.vars[varName];
    XCTAssertEqualObjects(loadedVar.value, updatedVarValue);
    
    NSString *fileName = [varCacheMock getArchiveFileName];
    NSString *filePath = [CTPreferences filePathfromFileName:fileName];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

- (void)testVarValues {
    NSNumber *varValue = [NSNumber numberWithDouble:6.67345983745897];
    CTVar *var = [varCache define:@"MyNumber" with:varValue kind:CT_KIND_FLOAT];
    
    XCTAssertEqualObjects(var.stringValue,varValue.stringValue);
    XCTAssertEqual(var.floatValue,varValue.floatValue);
    XCTAssertEqual(var.intValue,varValue.intValue);
    XCTAssertEqual(var.integerValue,varValue.integerValue);
    XCTAssertEqual(var.doubleValue,varValue.doubleValue);
    XCTAssertEqual(var.boolValue,varValue.boolValue);
    XCTAssertEqual(var.longValue,varValue.longValue);
    XCTAssertEqual(var.longLongValue,varValue.longLongValue);
    XCTAssertEqual(var.unsignedIntValue,varValue.unsignedIntValue);
    XCTAssertEqual(var.unsignedLongValue,varValue.unsignedLongValue);
    XCTAssertEqual(var.unsignedIntegerValue,varValue.unsignedIntegerValue);
    XCTAssertEqual(var.shortValue,varValue.shortValue);
    XCTAssertEqual(var.unsignedShortValue,varValue.unsignedShortValue);
    XCTAssertEqual(var.unsignedLongLongValue,varValue.unsignedLongLongValue);
    XCTAssertEqual(var.cgFloatValue,varValue.doubleValue);
    
    CTVar *mapVar = [varCache define:@"MyMap" with:@{@"MyMapNumber":varValue} kind:CT_KIND_DICTIONARY];
    XCTAssertTrue([[mapVar objectForKey:@"MyMapNumber"]isKindOfClass:[varValue class]]);
    XCTAssertTrue([mapVar.value isKindOfClass:[NSDictionary class]]);
    XCTAssertTrue([mapVar.defaultValue isKindOfClass:[NSDictionary class]]);
}

@end
