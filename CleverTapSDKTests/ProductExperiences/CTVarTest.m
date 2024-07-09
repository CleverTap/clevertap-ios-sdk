//
//  CTVarTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 10.04.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTPreferences.h"
#import "CTVariables.h"
#import "CTVarCache.h"
#import "CTVarCacheMock.h"
#import "CTConstants.h"
#import "CTVariables+Tests.h"
#import "CTFileDownloaderMock.h"
#import "CTFileDownloader+Tests.h"
#import "CTFileDownloadTestHelper.h"

@interface CTVarDelegateImpl : NSObject <CTVarDelegate>

typedef void(^Callback)(CTVar *);
@property Callback callback;
@property Callback fileReadyCallback;

@end

@implementation CTVarDelegateImpl

- (void)valueDidChange:(CTVar *)variable {
    if ([self callback]) {
        self.callback(variable);
    }
}

- (void)fileIsReady:(CTVar *)var {
    if ([self fileReadyCallback]) {
        self.fileReadyCallback(var);
    }
}

@end

@interface CTVarTest : XCTestCase

@property(strong, nonatomic) CTVariables *variables;
@property (nonatomic, strong) CTFileDownloaderMock *fileDownloader;
@property (nonatomic, strong) CTFileDownloadTestHelper *fileDownloadHelper;

@end

@implementation CTVarTest

- (void)setUp {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    config.useCustomCleverTapId = YES;
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"test"];
    self.fileDownloader = [[CTFileDownloaderMock alloc] initWithConfig:config];
    CTVarCacheMock *varCache = [[CTVarCacheMock alloc] initWithConfig:config deviceInfo:deviceInfo fileDownloader:self.fileDownloader];
    self.variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo varCache:varCache];
    
    self.fileDownloadHelper = [CTFileDownloadTestHelper new];
    [self.fileDownloadHelper addHTTPStub];
}

- (void)tearDown {
    self.variables = nil;
    [self.fileDownloadHelper removeStub];
    [self removeFiles];
}

- (void)testVariableName {
    CTVar *var1 = [self.variables define:@"<var>&</var>" with:@"<var>&</var>" kind:CT_KIND_STRING];
    CTVar *var2 = [self.variables define:@"[var]" with:@"[var]" kind:CT_KIND_STRING];
    CTVar *var3 = [self.variables define:@" " with:@" " kind:CT_KIND_STRING];
    
    CTVar *var4 = [self.variables define:@".group.var." with:@"value1" kind:CT_KIND_STRING];
    CTVar *var5 = [self.variables define:@"" with:@"" kind:CT_KIND_STRING];
    
    XCTAssertEqualObjects(@"<var>&</var>", var1.name);
    XCTAssertEqualObjects(@"[var]", var2.name);
    XCTAssertEqualObjects(@" ", var3.name);
    
    XCTAssertNil(var4);
    XCTAssertNil(var5);
}

- (void)testCTVarDelegate {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"delegate"];
    CTVarDelegateImpl *del = [[CTVarDelegateImpl alloc] init];
    __block CTVar *varFromDelegate = nil;
    [del setCallback:^(CTVar * variable) {
        varFromDelegate = variable;
        [expect fulfill];
    }];
    [var1 setDelegate:del];
    
    NSDictionary *diffs = @{
        @"var1": @2,
    };
    [self.variables handleVariablesResponse:diffs];
    
    [self waitForExpectations:@[expect] timeout:DISPATCH_TIME_NOW + 5.0];
    XCTAssertEqual(@"var1", varFromDelegate.name);
    XCTAssertEqual(@2, varFromDelegate.value);
}

- (void)testCTVarDelegateOnError {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"delegate"];
    CTVarDelegateImpl *del = [[CTVarDelegateImpl alloc] init];
    __block CTVar *varFromDelegate = nil;
    [del setCallback:^(CTVar * variable) {
        varFromDelegate = variable;
        [expect fulfill];
    }];
    [var1 setDelegate:del];

    [self.variables handleVariablesError];
    
    [self waitForExpectations:@[expect] timeout:DISPATCH_TIME_NOW + 5.0];
    XCTAssertEqual(@"var1", varFromDelegate.name);
    XCTAssertEqual(@1, varFromDelegate.value);
}

- (void)testCTVarDelegateAfterStart {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"delegate"];
    CTVarDelegateImpl *del = [[CTVarDelegateImpl alloc] init];
    __block CTVar *varFromDelegate = nil;
    [del setCallback:^(CTVar * variable) {
        varFromDelegate = variable;
        [expect fulfill];
    }];

    NSDictionary *diffs = @{
        @"var1": @2,
    };
    [self.variables handleVariablesResponse:diffs];
    
    // Set delegate after handling response
    [var1 setDelegate:del];
    
    [self waitForExpectations:@[expect] timeout:DISPATCH_TIME_NOW + 5.0];
    XCTAssertEqual(@"var1", varFromDelegate.name);
    XCTAssertEqual(@2, varFromDelegate.value);
}

- (void)testOnValueChangedNoDiff {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"delegate"];
    [var1 onValueChanged:^{
        [expect fulfill];
    }];

    [self.variables handleVariablesResponse:@{}];
    
    [self waitForExpectations:@[expect] timeout:DISPATCH_TIME_NOW + 5.0];
    XCTAssertEqualObjects(@1, var1.value);
}

- (void)testOnValueChangedDiff {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"delegate"];
    [var1 onValueChanged:^{
        [expect fulfill];
    }];

    NSDictionary *diffs = @{
        @"var1": @2,
    };
    [self.variables handleVariablesResponse:diffs];
    
    [self waitForExpectations:@[expect] timeout:DISPATCH_TIME_NOW + 5.0];
    XCTAssertEqual(@2, var1.value);
}

- (void)testOnValueChangedOnError {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"delegate"];
    [var1 onValueChanged:^{
        [expect fulfill];
    }];
    [self.variables handleVariablesError];
    
    [self waitForExpectations:@[expect] timeout:DISPATCH_TIME_NOW + 5.0];
    XCTAssertEqual(@1, var1.value);
}

- (void)testHadStarted {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    XCTAssertFalse(var1.hadStarted);
    self.variables.varCache.hasVarsRequestCompleted = @YES;
    [self.variables.varCache applyVariableDiffs:@{}];
    XCTAssertTrue(var1.hadStarted);
}

- (void)testHasChanged {
    CTVar *var1 = [self.variables define:@"var1" with:@1 kind:CT_KIND_INT];
    self.variables.varCache.hasVarsRequestCompleted = @YES;
    [self.variables.varCache applyVariableDiffs:@{}];
    XCTAssertFalse(var1.hasChanged);
    
    NSDictionary *diffs = @{
        @"var1": @2,
    };
    [self.variables.varCache applyVariableDiffs:diffs];
    XCTAssertTrue(var1.hasChanged);
}

- (void)testVarValues {
    NSNumber *varValue = [NSNumber numberWithDouble:6.67345983745897];
    CTVar *var = [self.variables define:@"varNumber" with:varValue kind:CT_KIND_FLOAT];
    
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
    
    CTVar *groupVar = [self.variables define:@"group" with:@{@"number":varValue} kind:CT_KIND_DICTIONARY];
    XCTAssertTrue([[groupVar objectForKey:@"number"] isKindOfClass:[varValue class]]);
    XCTAssertTrue([groupVar.value isKindOfClass:[NSDictionary class]]);
    XCTAssertTrue([groupVar.defaultValue isKindOfClass:[NSDictionary class]]);
}

#pragma mark - File type vars tests

- (void)testDefineFileVariable {
    CTVar *var = [self.variables define:@"fileVar" with:nil kind:CT_KIND_FILE];
    
    XCTAssertEqualObjects(@"fileVar", var.name);
    XCTAssertEqualObjects(CT_KIND_FILE, var.kind);
    XCTAssertNil(var.value);
    XCTAssertNil(var.stringValue);
    XCTAssertNil(var.fileValue);
}

- (void)testCTVarDelegateFileIsReady {
    // Register File var
    CTVar *var1 = [self.variables define:@"var1" with:nil kind:CT_KIND_FILE];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"delegate"];
    CTVarDelegateImpl *del = [[CTVarDelegateImpl alloc] init];
    __block CTVar *varFromDelegate = nil;
    [del setFileReadyCallback:^(CTVar * variable) {
        varFromDelegate = variable;
        [expect fulfill];
    }];
    [var1 setDelegate:del];
    
    // Apply diffs
    NSArray *urls = [self.fileDownloadHelper generateFileURLStrings:1];
    NSDictionary *diffs = @{
        @"var1": urls[0],
    };
    [self.variables handleVariablesResponse:diffs];
    
    [self waitForExpectations:@[expect] timeout:DISPATCH_TIME_NOW + 5.0];
    
    NSString *expValue = [self.fileDownloader fileDownloadPath:urls[0]];
    XCTAssertEqualObjects(@"var1", varFromDelegate.name);
    XCTAssertEqualObjects(expValue, varFromDelegate.value);
}

- (void)removeFiles {
    [CTPreferences removeObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
    [CTPreferences removeObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Wait for cleanup"];
    self.fileDownloader.removeAllAssetsCompletion = ^(NSDictionary<NSString *,id> * _Nonnull status) {
        [expectation1 fulfill];
    };
    // Clear all files
    [self.fileDownloader clearFileAssets:NO];
    [self waitForExpectations:@[expectation1] timeout:2.0];
}

@end
