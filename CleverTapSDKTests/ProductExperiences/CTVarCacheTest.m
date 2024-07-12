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
#import "CTUtils.h"
#import "CTPreferences.h"
#import "CTVarCache+Tests.h"
#import "CTVarCacheMock.h"
#import "CTVariables+Tests.h"
#import "CTConstants.h"
#import "CTFileDownloaderMock.h"
#import "CTFileDownloader+Tests.h"
#import "CTFileDownloadTestHelper.h"

@interface CTVarCacheTest : XCTestCase

@property (nonatomic, strong) CTFileDownloaderMock *fileDownloader;
@property (nonatomic, strong) CTFileDownloadTestHelper *fileDownloadHelper;

@end

CTVariables *variables;

@implementation CTVarCacheTest

- (void)setUp {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    config.useCustomCleverTapId = YES;
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"test"];
    self.fileDownloader = [[CTFileDownloaderMock alloc] initWithConfig:config];
    CTVarCacheMock *varCache = [[CTVarCacheMock alloc] initWithConfig:config deviceInfo:deviceInfo fileDownloader:self.fileDownloader];
    variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo varCache:varCache];
    
    self.fileDownloadHelper = [CTFileDownloadTestHelper new];
    [self.fileDownloadHelper addHTTPStub];
}

- (void)tearDown {
    variables = nil;
    [self.fileDownloadHelper removeStub];
    [self.fileDownloadHelper cleanUpFiles:self.fileDownloader forTest:self];
}

#pragma mark Name Components
- (void)testNameComponents {
    NSString *name = @"";
    NSArray *components = [[variables varCache] getNameComponents:name];
    XCTAssertEqual(1, [components count]);
    XCTAssertEqual(name, components[0]);
    
    NSString *name1 = @"my var 1";
    NSArray *components1 = [[variables varCache] getNameComponents:name1];
    XCTAssertEqual(1, [components1 count]);
    XCTAssertEqual(name1, components1[0]);
    
    NSString *name2 = @"   ";
    NSArray *components2 = [[variables varCache] getNameComponents:name2];
    XCTAssertEqual(1, [components2 count]);
    XCTAssertEqual(name2, components2[0]);
    
    NSString *name3 = @"var 2.var4. var 5 ";
    NSArray *components3 = [[variables varCache] getNameComponents:name3];
    XCTAssertEqual(3, [components3 count]);
    XCTAssertEqualObjects((@[@"var 2", @"var4", @" var 5 "]), components3);
    
    NSString *name4 = @"<var>&</var>";
    NSArray *components4 = [[variables varCache] getNameComponents:name4];
    XCTAssertEqual(1, [components4 count]);
    XCTAssertEqual(name4, components4[0]);
    
    NSString *name5 = @"var[0]";
    NSArray *components5 = [[variables varCache] getNameComponents:name5];
    XCTAssertEqual(1, [components5 count]);
    XCTAssertEqual(name5, components5[0]);
    
    NSString *component1 = @"first";
    NSString *component2 = @"second";
    NSString *component3 = @"third";
    NSArray *nameComponents = [[variables varCache] getNameComponents:[NSString stringWithFormat:@"%@.%@.%@",component1,component2,component3]];
    XCTAssertNotNil(nameComponents);
    XCTAssertEqualObjects((@[component1, component2, component3]), nameComponents);
    XCTAssertTrue(nameComponents.count == 3);
}

#pragma mark Traverse
- (void)testTraverse {
    NSDictionary *dictionary = @{
        @"key1": @"value1",
        @"key2": @{
            @"nestedKey1": @"nestedValue1",
            @"nestedKey2": @"nestedValue2"
        }
    };
    
    // Returns the correct value when the key exists in the dictionary
    id result = [variables.varCache traverse:dictionary withKey:@"key1" autoInsert:NO];
    XCTAssertEqualObjects(result, @"value1");
    
    // Returns nil when the key does not exist in the dictionary
    result = [variables.varCache traverse:dictionary withKey:@"key3" autoInsert:NO];
    XCTAssertNil(result);
    
    // Returns nil when the value for the key is NSNull
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
    
    // Creates a new dictionary and adds it to the collection when autoInsert is true and the key does not exist
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    [variables.varCache traverse:mutableDictionary withKey:@"newKey" autoInsert:YES];
    XCTAssertTrue([mutableDictionary objectForKey:@"newKey"] != nil);
    XCTAssertTrue([[mutableDictionary objectForKey:@"newKey"] isKindOfClass:[NSMutableDictionary class]]);
    
    // Does not create a new dictionary when autoInsert is false and the key does not exist
    [variables.varCache traverse:mutableDictionary withKey:@"newKey2" autoInsert:NO];
    XCTAssertNil([mutableDictionary objectForKey:@"newKey2"]);
}

#pragma mark Register Variables
- (void)testRegisterVars {
    CTVar *var = [variables define:@"test" with:@"test" kind:CT_KIND_STRING];
    XCTAssertEqual(variables.varCache.vars[var.name], var);
}

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

#pragma mark Get Merged Value
- (void)testGetMergedValue {
    NSString *varName = @"var1";
    [variables define:varName with:@"value1" kind:CT_KIND_STRING];
    NSString *value = [variables.varCache getMergedValue:varName];
    
    XCTAssertEqualObjects(@"value1", value);
}

- (void)testGetMergedValueWithGroup {
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

- (void)testGetMergedValueWithGroups {
    [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_STRING];
    [variables define:@"group1.group2.var3" with:@NO kind:CT_KIND_BOOLEAN];
    [variables define:@"group1" with:@{
        @"var2": @2,
        @"group2": @{
            @"var4": @4,
        }
    } kind:CT_KIND_DICTIONARY];
    
    [variables define:@"var5" with:@"value5" kind:CT_KIND_STRING];
    
    XCTAssertEqualObjects(@"value1", [variables.varCache getMergedValue:@"group1.var1"]);
    XCTAssertEqualObjects(@2, [variables.varCache getMergedValue:@"group1.var2"]);
    XCTAssertEqualObjects(@NO, [variables.varCache getMergedValue:@"group1.group2.var3"]);
    XCTAssertEqualObjects(@4, [variables.varCache getMergedValue:@"group1.group2.var4"]);
    
    XCTAssertEqualObjects(@"value5", [variables.varCache getMergedValue:@"var5"]);
}

#pragma mark Get Variable
- (void)testGetVariable {
    NSString *varName = @"var";
    CTVar *var = [variables define:varName with:@"value" kind:CT_KIND_STRING];
    CTVar *varResult = [variables.varCache getVariable:varName];
    
    XCTAssertEqual(varResult, var);
}

- (void)testGetVariableGroup {
    NSString *varName = @"group.var";
    CTVar *var = [variables define:varName with:@"value" kind:CT_KIND_STRING];
    CTVar *varResult = [variables.varCache getVariable:varName];
    CTVar *varGroupResult = [variables.varCache getVariable:@"group"];

    XCTAssertEqual(varResult, var);
    XCTAssertNil(varGroupResult);
    
    CTVar *varDict = [variables define:@"dict" with:@{} kind:CT_KIND_DICTIONARY];
    CTVar *varDictResult = [variables.varCache getVariable:@"dict"];
    XCTAssertEqual(varDictResult, varDict);
}

#pragma mark Merge Variable
- (void)testMergeVariable {
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

#pragma mark Apply Diffs
- (void)testApplyDiffs {
    CTVar *var1 = [variables define:@"var1" with:@1 kind:CT_KIND_INT];
    CTVar *group1_var1 = [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_STRING];
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
    
    XCTAssertEqualObjects(@2, var1.value);
    XCTAssertEqualObjects(@"value2", group1_var1.value);
    XCTAssertEqualObjects(@YES, var3.value);
    XCTAssertEqualObjects(@"value22", [variables.varCache getMergedValue:@"group1.var22"]);
}

- (void)testApplyDiffsDefaultValue {
    CTVar *var1 = [variables define:@"var1" with:@1 kind:CT_KIND_INT];
    CTVar *group1_var1 = [variables define:@"group1.var1" with:@"value1" kind:CT_KIND_STRING];
    CTVar *var3 = [variables define:@"group1.group2.var3" with:@NO kind:CT_KIND_BOOLEAN];
    
    NSDictionary *diffs = @{
        @"group1": @{
            @"var22": @"value22",
        }
    };
    
    [variables.varCache applyVariableDiffs:diffs];
    
    XCTAssertEqualObjects(@1, var1.value);
    XCTAssertEqualObjects(@"value1", group1_var1.value);
    XCTAssertEqualObjects(@NO, var3.value);
    XCTAssertEqualObjects(@"value22", [variables.varCache getMergedValue:@"group1.var22"]);
}

- (void)testApplyDiffsGroup {
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
    
    XCTAssertEqualObjects(@1, var1.value);
    XCTAssertEqualObjects(group1_group2_value, group1_group2.value);
    XCTAssertEqualObjects(@"value3", [variables.varCache getMergedValue:@"group1.group2.var3"]);
}

#pragma mark Save Diffs
- (void)testLoadSaveSpecialCharacters {
    CTVar *var1 = [variables define:@"<var>&</var>" with:@"<var>&</var>" kind:CT_KIND_STRING];
    CTVar *var2 = [variables define:@"[var]" with:@"[var]" kind:CT_KIND_STRING];
    CTVar *var3 = [variables define:@" " with:@" " kind:CT_KIND_STRING];
    
    CTVar *var4 = [variables define:@"<<" with:@"<<" kind:CT_KIND_STRING];
    CTVar *var5 = [variables define:@"and&" with:@"and&" kind:CT_KIND_STRING];
    CTVar *var6 = [variables define:@"'a" with:@"'a" kind:CT_KIND_STRING];
    
    CTVarCacheMock *varCache = (CTVarCacheMock *)variables.varCache;

    NSDictionary *diffs = @{
        @"<var>&</var>": @"<var2>&</var2>",
        @"[var]": @"[var2]",
        @" ": @"   ",
        @"<<": @"<<<",
        @"and&": @"b&",
        @"'a": @"'b"
    };
    
    [varCache applyVariableDiffs:diffs];
    // Call original saveDiffs and write to file
    [varCache originalSaveDiffs];
    [varCache loadDiffs];
    
    XCTAssertEqualObjects(@"<var2>&</var2>", var1.stringValue);
    XCTAssertEqualObjects(@"[var2]", var2.stringValue);
    XCTAssertEqualObjects(@"   ", var3.stringValue);
    XCTAssertEqualObjects(@"<<<", var4.stringValue);
    XCTAssertEqualObjects(@"b&", var5.stringValue);
    XCTAssertEqualObjects(@"'b", var6.stringValue);
    
    [self deleteSavedFile:[variables.varCache dataArchiveFileName]];
}

- (void)testSavesDiffs {
    CTVarCacheMock *varCache = (CTVarCacheMock *)variables.varCache;
    [variables define:@"var1" with:@"value" kind:CT_KIND_STRING];
    
    NSDictionary *diff = @{
        @"var1": @"new value",
    };
    [variables handleVariablesResponse:diff];
    
    XCTAssertEqual(1, varCache.saveCount);
    XCTAssertTrue([varCache hasVarsRequestCompleted]);
    
    // Call original saveDiffs and write to file
    [varCache originalSaveDiffs];
    
    NSString *fileName = [varCache dataArchiveFileName];
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
    XCTAssertTrue([diff isEqualToDictionary:loadedVars]);
    
    [self deleteSavedFile:fileName];
}

- (void)testLoadsDiffs {
    NSString *varName = @"var1";
    NSString *initialValue = @"value";
    NSString *overriddenValue = @"overridden";
    CTVarCacheMock *varCache = (CTVarCacheMock *)variables.varCache;

    [variables define:varName with:initialValue kind:CT_KIND_STRING];
    
    NSDictionary *diff = @{
        varName: overriddenValue,
    };
    [variables handleVariablesResponse:diff];
    XCTAssertEqual(1, varCache.saveCount);
    XCTAssertTrue([varCache hasVarsRequestCompleted]);
    
    // Call original saveDiffs and write to file
    [varCache originalSaveDiffs];
    
    [varCache loadDiffs];
    CTVar *loadedVar = varCache.vars[varName];
    XCTAssertEqualObjects(loadedVar.value, overriddenValue);
    
    [self deleteSavedFile:[varCache dataArchiveFileName]];
}

- (void)deleteSavedFile:(NSString *)fileName {
    NSString *filePath = [CTPreferences filePathfromFileName:fileName];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

#pragma mark - File type vars tests

- (void)testRegisterFileVars {
    CTVar *var = [variables define:@"test" with:nil kind:CT_KIND_FILE];
    XCTAssertEqual(variables.varCache.vars[var.name], var);
}

- (void)testGetFileVariable {
    NSString *varName = @"var";
    CTVar *var = [variables define:varName with:nil kind:CT_KIND_FILE];
    CTVar *varResult = [variables.varCache getVariable:varName];
    
    XCTAssertEqual(varResult, var);
}

- (void)testFileVarApplyDiffs {
    NSArray *urls = [self.fileDownloadHelper generateFileURLStrings:2];
    
    // Register Vars
    CTVar *var1 = [variables define:@"var1" with:nil kind:CT_KIND_FILE];
    CTVar *group1_var1 = [variables define:@"group1.var1" with:nil kind:CT_KIND_FILE];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for download completion"];
    self.fileDownloader.downloadCompletion = ^(NSDictionary<NSString *, id> * _Nonnull status) {
        XCTAssertNotNil([status objectForKey:urls[0]]);
        XCTAssertNotNil([status objectForKey:urls[1]]);
        [expectation fulfill];
    };
    
    // Apply diffs
    NSDictionary *diffs = @{
        @"var1": urls[0],
        @"group1": @{
            @"var1": urls[1]
        }
    };
    // File vars value should be nil when not downloaded/present
    XCTAssertEqualObjects(nil, var1.value);
    XCTAssertEqualObjects(nil, group1_var1.value);
    
    [variables.varCache applyVariableDiffs:diffs];
    [self waitForExpectations:@[expectation] timeout:2.0];

    // File var value should be file downloaded path
    NSString *expValue1 = [self.fileDownloader fileDownloadPath:urls[0]];
    NSString *expValue2 = [self.fileDownloader fileDownloadPath:urls[1]];
    XCTAssertEqualObjects(expValue1, var1.value);
    XCTAssertEqualObjects(expValue2, group1_var1.value);
}

- (void)testFileVariableValues {
    NSString *url = [self.fileDownloadHelper generateFileURLString];
    
    // Register Vars
    CTVar *var1 = [variables define:@"var1" with:nil kind:CT_KIND_FILE];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for download completion"];
    self.fileDownloader.downloadCompletion = ^(NSDictionary<NSString *, id> * _Nonnull status) {
        [expectation fulfill];
    };
    
    // Apply diffs
    NSDictionary *diffs = @{
        @"var1": url
    };
    [variables.varCache applyVariableDiffs:diffs];
    [self waitForExpectations:@[expectation] timeout:2.0];
    
    NSString *expValue1 = [self.fileDownloader fileDownloadPath:url];
    XCTAssertEqualObjects(url, var1.fileURL);
    XCTAssertEqualObjects(expValue1, var1.value);
    XCTAssertEqualObjects(expValue1, var1.stringValue);
    XCTAssertEqualObjects(expValue1, var1.fileValue);
}

- (void)testApplyVariableValuesNil {
    NSString *url = [self.fileDownloadHelper generateFileURLString];

    // Register Vars
    CTVar *var1 = [variables define:@"var1" with:nil kind:CT_KIND_FILE];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for download completion"];
    self.fileDownloader.downloadCompletion = ^(NSDictionary<NSString *, id> * _Nonnull status) {
        [expectation fulfill];
    };
    
    // Apply diffs with var1 override
    NSDictionary *diffs = @{
        @"var1": url
    };
    [variables.varCache applyVariableDiffs:diffs];
    [self waitForExpectations:@[expectation] timeout:2.0];
    
    NSString *expValue1 = [self.fileDownloader fileDownloadPath:url];
    XCTAssertEqualObjects(url, var1.fileURL);
    XCTAssertEqualObjects(expValue1, var1.value);
    XCTAssertEqualObjects(expValue1, var1.stringValue);
    XCTAssertEqualObjects(expValue1, var1.fileValue);
    
    // Apply diffs with no override
    NSDictionary *diffsNil = @{
    };
    [variables.varCache applyVariableDiffs:diffsNil];
    XCTAssertNil(var1.fileURL);
    XCTAssertNil(var1.value);
    XCTAssertNil(var1.stringValue);
    XCTAssertNil(var1.fileValue);
}

- (void)testDefineFileVarAfterResponse {
    NSString *url = [self.fileDownloadHelper generateFileURLString];
    // Apply diffs with var1 override
    NSDictionary *diffs = @{
        @"var1": url
    };
    [variables handleVariablesResponse:diffs];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for download completion"];
    self.fileDownloader.downloadCompletion = ^(NSDictionary<NSString *, id> * _Nonnull status) {
        [expectation fulfill];
    };
    // Define the variable after the initial response and applied diffs
    CTVar *var1 = [variables define:@"var1" with:nil kind:CT_KIND_FILE];
    [self waitForExpectations:@[expectation] timeout:2.0];

    NSString *expValue1 = [self.fileDownloader fileDownloadPath:url];
    XCTAssertEqualObjects(url, var1.fileURL);
    XCTAssertEqualObjects(expValue1, var1.value);
    XCTAssertEqualObjects(expValue1, var1.stringValue);
    XCTAssertEqualObjects(expValue1, var1.fileValue);
}

- (void)testFileVarUpdated {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for download completion"];
    NSString *url = [self.fileDownloadHelper generateFileURLString];
    variables.varCache.merged = [NSMutableDictionary dictionaryWithDictionary:@{
        @"var1": url
    }];
    CTVar *var1 = [variables define:@"var1" with:nil kind:CT_KIND_FILE];
    [var1 onFileIsReady:^{
        NSString *expValue1 = [self.fileDownloader fileDownloadPath:url];
        XCTAssertEqualObjects(url, var1.fileURL);
        XCTAssertEqualObjects(expValue1, var1.value);
        XCTAssertEqualObjects(expValue1, var1.stringValue);
        XCTAssertEqualObjects(expValue1, var1.fileValue);
        [expectation fulfill];
    }];
    [variables.varCache fileVarUpdated:var1];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

@end
