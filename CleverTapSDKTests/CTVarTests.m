//
//  CTVarCacheTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 01/03/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTVariables.h"
#import "CTVarCache.h"
#import <OCMock/OCMock.h>
#import "CTUtils.h"
#import "CTPreferences.h"
#import "CTVarCache+Tests.h"
#import "CTConstants.h"
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import "CTRequestFactory.h"

@interface CTVarTests : XCTestCase

@end

CleverTapInstanceConfig *config;
CTDeviceInfo *deviceInfo;
CTVariables *variables;

@implementation CTVarTests

- (void)setUp {
    config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    config.useCustomCleverTapId = YES;
    deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"test"];
    variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo];
}

- (void)tearDown {
    variables = nil;
}

- (void)testVarCacheNotNil {
    XCTAssertNotNil(variables);
}

- (void)testVarCacheFetchesNameComponents {
    NSString *component1 = @"Primary";
    NSString *component2 = @"Secondary";
    NSString *component3 = @"Tertiary";
    NSArray *nameComponents = [[variables varCache] getNameComponents:[NSString stringWithFormat:@"%@.%@.%@",component1,component2,component3]];
    XCTAssertNotNil(nameComponents);
    
    BOOL expression = [nameComponents containsObject:component1] && [nameComponents containsObject:component2] && [nameComponents containsObject:component3];
    XCTAssertTrue(expression);
    
    XCTAssertTrue(nameComponents.count == 3);
}

- (void)testVarCacheResgitersVars {
    CTVar *varMock = OCMPartialMock([variables define:@"test" with:@"test" kind:CT_KIND_STRING]);
    [variables.varCache registerVariable:varMock];
    
    XCTAssertEqual(variables.varCache.vars[varMock.name], varMock);
}

- (void)testVarCacheGetVarsForName {
    NSString *varName = @"test";
    CTVar *var = [variables define:varName with:@"test" kind:CT_KIND_STRING];
    CTVar *varResult = [variables getVariable:varName];

    XCTAssertEqual(varResult, var);
}

- (void)testVarCacheSavesDiffs {
    id variablesMock = OCMPartialMock(variables);
    [variablesMock define:@"Title" with:@"Hello" kind:CT_KIND_STRING];
    
    NSDictionary *updatedVarsFromServer = @{
        @"Title": @"TitleUpdated",
    };
    id varCacheMock = OCMPartialMock(variables.varCache);
    [varCacheMock applyVariableDiffs:updatedVarsFromServer];
    OCMVerify([varCacheMock saveDiffs]);
    XCTAssertTrue([varCacheMock hasReceivedDiffs]);
    
    NSString *fileName = [varCacheMock getArchiveFileName];
    NSString *filePath = [CTPreferences filePathfromFileName:fileName];
    NSData *diffsData = [NSData dataWithContentsOfFile:filePath];
    NSKeyedUnarchiver *unarchiver;
    NSError *error = nil;
    if (@available(iOS 12.0, *)) {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:diffsData error:&error];
        XCTAssertNil(error);
        unarchiver.requiresSecureCoding = NO;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:diffsData];
#pragma clang diagnostic pop
    }
    NSDictionary *loadedVars = (NSDictionary *) [unarchiver decodeObjectForKey:CLEVERTAP_DEFAULTS_VARIABLES_KEY];
    XCTAssertTrue([updatedVarsFromServer isEqualToDictionary:loadedVars]);
    
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

- (void)testVarCacheLoadsDiffs {
    NSString *varName = @"Title";
    NSString *initialVarValue = @"Hello";
    NSString *updatedVarValue = @"TitleUpdated";
    CTVariables *variablesMock = OCMPartialMock(variables);
    CTVarCache *varCacheMock = OCMPartialMock(variables.varCache);
    [variablesMock define:varName with:initialVarValue kind:CT_KIND_STRING];
    
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
    CTVar *var = [variables define:@"MyNumber" with:varValue kind:CT_KIND_FLOAT];
    
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
    XCTAssertEqual(var.charValue,varValue.charValue);
    XCTAssertEqual(var.unsignedCharValue,varValue.unsignedCharValue);
    
    CTVar *mapVar = [variables define:@"MyMap" with:@{@"MyMapNumber":varValue} kind:CT_KIND_DICTIONARY];
    XCTAssertTrue([[mapVar objectForKey:@"MyMapNumber"]isKindOfClass:[varValue class]]);
    XCTAssertTrue([mapVar.value isKindOfClass:[NSDictionary class]]);
    XCTAssertTrue([mapVar.defaultValue isKindOfClass:[NSDictionary class]]);
}

- (void)testSyncVarsPayload {
    NSString *varName = @"Title";
    NSString *varValue = @"Hello";

    CTVariables *variablesMock = OCMPartialMock(variables);
    CTVar *definedVar = [variablesMock define:varName with:varValue kind:CT_KIND_STRING];
    
    NSDictionary *payload = [variables varsPayload];
    
    XCTAssertEqualObjects(payload[@"type"],@"varsPayload");
    NSDictionary *vars = [payload objectForKey:@"vars"];
    NSDictionary *titleMap = [vars objectForKey:varName];
    XCTAssertEqualObjects(titleMap[@"defaultValue"],varValue);
    XCTAssertEqualObjects(titleMap[@"type"],definedVar.kind);
}

- (void)testVariablesFlatten {
    
    NSString *varName = @"EmployeeMap";
    NSDictionary *employeeMap = @{
        @"Team": @{
            @"TeamName": @"Testing",
            @"Designation": @"Tester"
        },
        @"Name": @"Niko",
        @"EmployeeID": @123
    };
    NSDictionary *flattenedEmployeeMap = @{
        @"EmployeeMap.Team.TeamName": @{ @"defaultValue": @"Testing" },
        @"EmployeeMap.Team.Designation": @{ @"defaultValue": @"Tester" },
        @"EmployeeMap.Name": @{ @"defaultValue": @"Niko" },
        @"EmployeeMap.EmployeeID": @{ @"defaultValue": @123 }
    };
    NSDictionary *result = [variables flatten:employeeMap varName:varName];
    XCTAssertEqualObjects(result,flattenedEmployeeMap);
}

- (void)testVariablesUnflatten {
    NSDictionary *flattenedEmployeeMap = @{
        @"EmployeeMap.Team.TeamName": @{ @"defaultValue": @"Testing" },
        @"EmployeeMap.Team.Designation": @{ @"defaultValue": @"Tester" },
        @"EmployeeMap.Name": @{ @"defaultValue": @"Niko" },
        @"EmployeeMap.EmployeeID": @{ @"defaultValue": @123 }
    };
    NSDictionary *unflattenedEmployeeMap = @{
        @"EmployeeMap": @{
            @"Team": @{
                @"TeamName": @{ @"defaultValue": @"Testing" },
                @"Designation": @{ @"defaultValue": @"Tester" }
            },
            @"Name": @{ @"defaultValue": @"Niko" },
            @"EmployeeID": @{ @"defaultValue": @123 }
        }
    };
    NSDictionary *result = [variables unflatten:flattenedEmployeeMap];
    XCTAssertEqualObjects(result,unflattenedEmployeeMap);
}

@end
