//
//  CTVarCacheTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTVariables.h"
#import "CTVarCache.h"
#import <OCMock/OCMock.h>
#import "CTUtils.h"
#import "CTPreferences.h"
#import "CTVarCache+Tests.h"
#import "CTVarCacheMock.h"
#import "CTVariables+Tests.h"
#import "CTConstants.h"
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import "CTRequestFactory.h"


@interface CTVarCacheTest : XCTestCase

@end

CleverTapInstanceConfig *config;
CTDeviceInfo *deviceInfo;
CTVariables *variables;

@implementation CTVarCacheTest

- (void)setUp {
    config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    config.useCustomCleverTapId = YES;
    deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"test"];
    CTVarCacheMock *varCache = [[CTVarCacheMock alloc] initWithConfig:config deviceInfo:deviceInfo];
    variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo varCache:varCache];
//    variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo];
}

- (void)tearDown {
    variables = nil;
}

- (void)testVarCacheFetchesNameComponents {
    NSString *component1 = @"first";
    NSString *component2 = @"second";
    NSString *component3 = @"third";
    NSArray *nameComponents = [[variables varCache] getNameComponents:[NSString stringWithFormat:@"%@.%@.%@",component1,component2,component3]];
    XCTAssertNotNil(nameComponents);
    
    BOOL expression = [nameComponents containsObject:component1] && [nameComponents containsObject:component2] && [nameComponents containsObject:component3];
    XCTAssertTrue(expression);
    
    XCTAssertTrue(nameComponents.count == 3);
}

// TODO: check test
- (void)testTraverse {
    // Create a dictionary for testing purposes
    NSDictionary *dictionary = @{
        @"key1": @"value1",
        @"key2": @{
            @"nestedKey1": @"nestedValue1",
            @"nestedKey2": @"nestedValue2"
        }
    };
    
    // Test that the method returns the correct value when the key exists in the dictionary
    id result = [variables.varCache traverse:dictionary withKey:@"key1" autoInsert:NO];
    XCTAssertEqualObjects(result, @"value1");
    
    // Test that the method returns nil when the key does not exist in the dictionary
    result = [variables.varCache traverse:dictionary withKey:@"key3" autoInsert:NO];
    XCTAssertNil(result);
    
    // Test that the method returns nil when the value for the key is NSNull
    NSDictionary *dictionaryWithNull = @{
        @"key1": [NSNull null]
    };
    result = [variables.varCache traverse:dictionaryWithNull withKey:@"key1" autoInsert:NO];
    XCTAssertNil(result);
}

- (void)testTraverseWithAutoInsert {
    NSDictionary *dictionary = @{
        @"key1": @"value1",
        @"key2": @{
            @"nestedKey1": @"nestedValue1",
            @"nestedKey2": @"nestedValue2"
        }
    };
    
    // Test that the method creates a new dictionary and adds it to the collection when autoInsert is true and the key does not exist
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    [variables.varCache traverse:mutableDictionary withKey:@"newKey" autoInsert:YES];
    XCTAssertTrue([mutableDictionary objectForKey:@"newKey"] != nil);
    XCTAssertTrue([[mutableDictionary objectForKey:@"newKey"] isKindOfClass:[NSMutableDictionary class]]);
    
    // Test that the method does not create a new dictionary when autoInsert is false and the key does not exist
    [variables.varCache traverse:mutableDictionary withKey:@"newKey2" autoInsert:NO];
    XCTAssertNil([mutableDictionary objectForKey:@"newKey2"]);
}


// TODO: check test
- (void)testVarCacheResgitersVars {
    CTVar *varMock = OCMPartialMock([variables define:@"test" with:@"test" kind:CT_KIND_STRING]);
    [variables.varCache registerVariable:varMock];
    
    XCTAssertEqual(variables.varCache.vars[varMock.name], varMock);
}

// TODO: check test
- (void)testVarCacheGetVarsForName {
    NSString *varName = @"test";
    CTVar *var = [variables define:varName with:@"test" kind:CT_KIND_STRING];
    CTVar *varResult = [variables.varCache getVariable:varName];

    XCTAssertEqual(varResult, var);
}

#pragma mark Register Variables
- (void)testRegisterVariableWithGroup {
    [variables define:@"group.var1" with:@"value1" kind:CT_KIND_STRING];
    [variables define:@"group" with:@{
        @"var2": @"value2"
    } kind:CT_KIND_DICTIONARY];
    
    NSDictionary *expectedGroupDefaultValue = @{ @"var2": @"value2" };
    NSDictionary *expectedGroupValue = @{ @"var1": @"value1", @"var2": @"value2" };
    
    CTVarCache *varCache = variables.varCache;
    XCTAssertEqual(2, varCache.vars.count);
    XCTAssertEqualObjects(@"value1", [varCache getVariable:@"group.var1"].defaultValue);
    XCTAssertEqualObjects(@"value1", [varCache getVariable:@"group.var1"].value);
    XCTAssertEqualObjects(expectedGroupDefaultValue, [varCache getVariable:@"group"].defaultValue);
    XCTAssertEqualObjects(expectedGroupValue, [varCache getVariable:@"group"].value);
}

- (void)testRegisterVariableWithNestedGroup {
    [variables define:@"group1.var1" with:@1 kind:CT_KIND_INT];
    [variables define:@"group1.group2.var3" with:@NO kind:CT_KIND_BOOLEAN];
    NSDictionary *group1DefaultValue = @{
        @"var2": @2,
        @"group2": @{
            @"var4": @4,
        }
    };
    [variables define:@"group1" with:group1DefaultValue kind:CT_KIND_DICTIONARY];
    
    NSDictionary *expectedGroup1Value = @{
        @"var1": @1,
        @"var2": @2,
        @"group2": @{
            @"var4": @4,
            @"var3": @NO,
        }
    };
    
    CTVarCache *varCache = variables.varCache;
    XCTAssertEqual(3, varCache.vars.count);
    XCTAssertEqualObjects(@1, [varCache getVariable:@"group1.var1"].value);
    XCTAssertEqualObjects(@NO, [varCache getVariable:@"group1.group2.var3"].value);
    
    XCTAssertEqualObjects(group1DefaultValue, [varCache getVariable:@"group1"].defaultValue);
    XCTAssertEqualObjects(expectedGroup1Value, [varCache getVariable:@"group1"].value);
}

#pragma mark GetMergedValue
- (void)testVarCacheGetMergedValue {
    NSString *varName = @"var1";
    [variables define:varName with:@"value1" kind:CT_KIND_STRING];
    NSString *value = [variables.varCache getMergedValue:varName];

    XCTAssertEqual(@"value1", value);
}

- (void)testVarCacheGetMergedValueWithGroup {
    [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_STRING];
    [variables define:@"group1.group2.var3" with:@NO kind:CT_KIND_BOOLEAN];
    [variables define:@"group1" with:@{
        @"var2": @2,
        @"group2": @{
            @"var4": @4,
        }
    } kind:CT_KIND_DICTIONARY];
    
    NSDictionary *expectedGroup1Value = @{
        @"var1": @"value1",
        @"var2": @2,
        @"group2": @{
            @"var4": @4,
            @"var3": @NO,
        }
    };

    XCTAssertEqualObjects(expectedGroup1Value, [variables.varCache getMergedValue:@"group1"]);
}

- (void)testVarCacheGetMergedValueWithGroups {
    [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_STRING];
    [variables define:@"group1.group2.var3" with:@NO kind:CT_KIND_BOOLEAN];
    [variables define:@"group1" with:@{
        @"var2": @2,
        @"group2": @{
            @"var4": @4,
        }
    } kind:CT_KIND_DICTIONARY];
    
    [variables define:@"var5" with:@"value5" kind:CT_KIND_STRING];

    XCTAssertEqual(@"value1", [variables.varCache getMergedValue:@"group1.var1"]);
    XCTAssertEqual(@2, [variables.varCache getMergedValue:@"group1.var2"]);
    XCTAssertEqual(@NO, [variables.varCache getMergedValue:@"group1.group2.var3"]);
    XCTAssertEqual(@4, [variables.varCache getMergedValue:@"group1.group2.var4"]);
    
    XCTAssertEqual(@"value5", [variables.varCache getMergedValue:@"var5"]);
}

#pragma mark Apply Diffs
- (void)testVarCacheApplyDiffs {
    CTVar *var1 = [variables define:@"var1" with:@1 kind:CT_KIND_INT];
    CTVar *group1_var1 = [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_INT];
    CTVar *var3 = [variables define:@"group1.group2.var3" with:@NO kind:CT_KIND_BOOLEAN];
    
    NSDictionary *diffs = @{
        @"var1": @2,
        @"group1": @{
            @"var1": @"value2",
            @"var22": @"value22",
            @"group2": @{
                @"var3": @YES,
            }
        }
    };
    
    [variables.varCache applyVariableDiffs:diffs];

    XCTAssertEqual(@2, var1.value);
    XCTAssertEqual(@"value2", group1_var1.value);
    XCTAssertEqual(@YES, var3.value);
    XCTAssertEqual(@"value22", [variables.varCache getMergedValue:@"group1.var22"]);
}

- (void)testVarCacheApplyDiffsDefaultValue {
    CTVar *var1 = [variables define:@"var1" with:@1 kind:CT_KIND_INT];
    CTVar *group1_var1 = [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_STRING];
    CTVar *var3 = [variables define:@"group1.group2.var3" with:@NO kind:CT_KIND_BOOLEAN];
    
    NSDictionary *diffs = @{
        @"group1": @{
            @"var22": @"value22",
        }
    };
    
    [variables.varCache applyVariableDiffs:diffs];

    XCTAssertEqual(@1, var1.value);
    XCTAssertEqual(@"value1", group1_var1.value);
    XCTAssertEqual(@NO, var3.value);
    XCTAssertEqual(@"value22", [variables.varCache getMergedValue:@"group1.var22"]);
}

- (void)testVarCacheApplyDiffsGroup {
    CTVar *var1 = [variables define:@"group1.group2.var1" with:@1 kind:CT_KIND_INT];
    CTVar *group1_group2 = [variables define:@"group1.group2" with:@{
        @"var2": @"value2"
    } kind:CT_KIND_DICTIONARY];
    
    NSDictionary *diffs = @{
        @"group1": @{
            @"group2": @{
                @"var3": @"value3"
            }
        }
    };

    [variables.varCache applyVariableDiffs:diffs];
    
    NSDictionary *group1_group2_value = @{
        @"var1": @1,
        @"var2": @"value2",
        @"var3": @"value3"
    };

    XCTAssertEqual(@1, var1.value);
    XCTAssertEqualObjects(group1_group2_value, group1_group2.value);
    XCTAssertEqual(@"value3", [variables.varCache getMergedValue:@"group1.group2.var3"]);
}

// TODO: test defining var later
- (void)testVarCacheMergeVariable {
    NSDictionary *diffs = @{
        @"var1": @2,
        @"group1": @{
            @"var1": @"value2",
            @"group2": @{
                @"var2": @YES,
            }
        }
    };
    // Apply diffs first, before defining the variable
    [variables.varCache applyVariableDiffs:diffs];
    
    CTVar *var1 = [variables define:@"var1" with:@1 kind:CT_KIND_INT];
    CTVar *group1_var1 = [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_STRING];
    CTVar *group1_group2 = [variables define:@"group1.group2" with:@{
        @"var2": @NO,
        @"var3": @3,
    } kind:CT_KIND_DICTIONARY];

    XCTAssertEqual(@2, var1.value);
    XCTAssertEqual(@"value2", group1_var1.value);
    XCTAssertEqualObjects((@{ @"var2": @YES, @"var3": @3 }), group1_group2.value);
}

- (void)testVarCacheMergeVariableNestedGroups {

}


- (void)testVarCacheSavesDiffs {
    
    variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo];
    
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

@end
