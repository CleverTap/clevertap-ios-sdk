//
//  CTProductConfigControllerTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 12/06/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CTProductConfigController.h"
#import "CleverTapInstanceConfig.h"
#import "CTPreferences.h"
#import "CTUtils.h"

@interface CTProductConfigController (Tests)
@property (atomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, weak) id<CTProductConfigDelegate> _Nullable delegate;
@property (atomic, copy) NSString *guid;
@property (nonatomic, strong) NSMutableDictionary *activeConfig;
@property (nonatomic, strong) NSDictionary *fetchedConfig;
@property (nonatomic, strong) NSDictionary *defaultConfig;
@property (nonatomic, assign) BOOL activateFetchedConfig;
@property (nonatomic, strong) NSOperationQueue *commandQueue;

- (void)_updateProductConfig:(NSArray<NSDictionary*> *)productConfig isNew:(BOOL)isNew;
- (void)_updateActiveProductConfig:(BOOL)activated;
- (void)_unarchiveDataSync:(BOOL)sync;
- (void)_archiveData:(NSArray*)data sync:(BOOL)sync;
- (NSString*)dataArchiveFileName;
- (void)notifyInitUpdate;
- (void)notifyFetchUpdate;
- (void)notifyActivateUpdate;
@end

@interface CTProductConfigControllerTests : XCTestCase
@property (nonatomic, strong) CTProductConfigController *controller;
@property (nonatomic, strong) id mockConfig;
@property (nonatomic, strong) id mockDelegate;
@property (nonatomic, strong) NSString *testGuid;
@end

@implementation CTProductConfigControllerTests

- (void)setUp {
   [super setUp];
   
   self.mockConfig = OCMClassMock([CleverTapInstanceConfig class]);
   OCMStub([self.mockConfig accountId]).andReturn(@"test-account-id");
   OCMStub([self.mockConfig logLevel]).andReturn(CleverTapLogOff);
   
   self.mockDelegate = OCMProtocolMock(@protocol(CTProductConfigDelegate));
   self.testGuid = @"test-guid-123";
   
   id mockPreferences = OCMClassMock([CTPreferences class]);
   OCMStub([mockPreferences unarchiveFromFile:[OCMArg any] ofTypes:[OCMArg any] removeFile:YES]).andReturn(nil);
   OCMStub([mockPreferences archiveObject:[OCMArg any] forFileName:[OCMArg any] config:[OCMArg any]]);
   
   id mockUtils = OCMClassMock([CTUtils class]);
   OCMStub([mockUtils runSyncMainQueue:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
       void (^block)(void);
       [invocation getArgument:&block atIndex:2];
       block();
   });
    self.controller = [[CTProductConfigController alloc] initWithConfig:self.mockConfig
                                                                   guid:self.testGuid
                                                               delegate:self.mockDelegate];
}

- (void)tearDown {
   self.controller = nil;
   self.mockConfig = nil;
   self.mockDelegate = nil;
   [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInitWithConfig {
   
   
   
   
   XCTAssertNotNil(self.controller);
   XCTAssertTrue(self.controller.isInitialized);
   XCTAssertEqual(self.controller.config, self.mockConfig);
   XCTAssertEqualObjects(self.controller.guid, self.testGuid);
   XCTAssertEqual(self.controller.delegate, self.mockDelegate);
   
   OCMVerify([self.mockDelegate productConfigDidInitialize]);
}

#pragma mark - Product Config Update Tests

- (void)testUpdateProductConfig {
   
   
   
   NSDictionary *config1 = [NSDictionary dictionaryWithObjectsAndKeys:@"key1", @"n", @"value1", @"v", nil];
   NSDictionary *config2 = [NSDictionary dictionaryWithObjectsAndKeys:@"key2", @"n", @123, @"v", nil];
   NSDictionary *config3 = [NSDictionary dictionaryWithObjectsAndKeys:@"key3", @"n", @YES, @"v", nil];
   NSArray *productConfig = [NSArray arrayWithObjects:config1, config2, config3, nil];
   
   
   [self.controller updateProductConfig:productConfig];
   
   
   XCTAssertNotNil(self.controller.fetchedConfig);
   XCTAssertEqualObjects(self.controller.fetchedConfig[@"key1"], @"value1");
   XCTAssertEqualObjects(self.controller.fetchedConfig[@"key2"], @123);
   XCTAssertEqualObjects(self.controller.fetchedConfig[@"key3"], @YES);
}

- (void)testUpdateProductConfigWithInvalidData {
   
   
   
   NSDictionary *config1 = [NSDictionary dictionaryWithObjectsAndKeys:@"key1", @"n", @"value1", @"v", nil];
   NSDictionary *config2 = [NSDictionary dictionaryWithObjectsAndKeys:@"data", @"invalid", nil];
   NSDictionary *config3 = [NSDictionary dictionaryWithObjectsAndKeys:@"key2", @"n", @"value2", @"v", nil];
   NSArray *productConfig = [NSArray arrayWithObjects:config1, config2, config3, nil];
   
   
   [self.controller updateProductConfig:productConfig];
   
   
   XCTAssertNotNil(self.controller.fetchedConfig);
   XCTAssertEqualObjects(self.controller.fetchedConfig[@"key1"], @"value1");
   XCTAssertEqualObjects(self.controller.fetchedConfig[@"key2"], @"value2");
   XCTAssertNil(self.controller.fetchedConfig[@"invalid"]);
}

- (void)testUpdateProductConfigWithActivateFetchedConfig {
   
   
   self.controller.activateFetchedConfig = YES;
   
   NSDictionary *config1 = [NSDictionary dictionaryWithObjectsAndKeys:@"key1", @"n", @"value1", @"v", nil];
   NSArray *productConfig = [NSArray arrayWithObjects:config1, nil];
   
   
   [self.controller updateProductConfig:productConfig];
   
   XCTAssertNotNil(self.controller.activeConfig);
}

#pragma mark - Active Config Tests

- (void)testUpdateActiveProductConfigWithDefaultsOnly {
   
   
   
   NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:@"default_value", @"default_key", nil];
   [self.controller setDefaults:defaults];
   
   
   [self.controller _updateActiveProductConfig:NO];
   
   
   XCTAssertNotNil(self.controller.activeConfig);
   CleverTapConfigValue *value = self.controller.activeConfig[@"default_key"];
   XCTAssertNotNil(value);
}

- (void)testUpdateActiveProductConfigWithFetchedConfig {
   NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:@"default_value", @"default_key", nil];
   [self.controller setDefaults:defaults];
   
   NSDictionary *config1 = [NSDictionary dictionaryWithObjectsAndKeys:@"fetched_key", @"n", @"fetched_value", @"v", nil];
   NSArray *productConfig = [NSArray arrayWithObjects:config1, nil];
   [self.controller _updateProductConfig:productConfig isNew:NO];
   
   
   [self.controller _updateActiveProductConfig:YES];
   
   
   XCTAssertNotNil(self.controller.activeConfig);
   XCTAssertNotNil(self.controller.activeConfig[@"default_key"]);
   XCTAssertNotNil(self.controller.activeConfig[@"fetched_key"]);
}

- (void)testUpdateActiveProductConfigWithDifferentDataTypes {
   
   
   
   NSDate *testDate = [NSDate date];
   NSData *testData = [@"data_value" dataUsingEncoding:NSUTF8StringEncoding];
   NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string_value", @"string_key",
                            @123, @"number_key",
                            testDate, @"date_key",
                            testData, @"data_key",
                            nil];
   [self.controller setDefaults:defaults];
   
   
   [self.controller _updateActiveProductConfig:NO];
   
   
   XCTAssertNotNil(self.controller.activeConfig);
   XCTAssertNotNil(self.controller.activeConfig[@"string_key"]);
   XCTAssertNotNil(self.controller.activeConfig[@"number_key"]);
   XCTAssertNotNil(self.controller.activeConfig[@"date_key"]);
   XCTAssertNotNil(self.controller.activeConfig[@"data_key"]);
}

#pragma mark - API Tests

- (void)testActivate {
   
   
   
   
   [self.controller activate];
   
   
   OCMVerify([self.mockDelegate productConfigDidActivate]);
}

- (void)testFetchAndActivate {
   
   
   
   
   [self.controller fetchAndActivate];
   
   
   XCTAssertTrue(self.controller.activateFetchedConfig);
}

- (void)testReset {
   NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
   [self.controller setDefaults:defaults];
   
   NSDictionary *config1 = [NSDictionary dictionaryWithObjectsAndKeys:@"key2", @"n", @"value2", @"v", nil];
   NSArray *productConfig = [NSArray arrayWithObjects:config1, nil];
   [self.controller updateProductConfig:productConfig];
   
   
   [self.controller reset];
   
   
   XCTAssertEqual(self.controller.defaultConfig.count, 0);
   XCTAssertEqual(self.controller.activeConfig.count, 0);
   XCTAssertEqual(self.controller.fetchedConfig.count, 0);
}

- (void)testSetDefaults {
   
   
   
   NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:@"default_value", @"default_key", nil];
   
   
   [self.controller setDefaults:defaults];
   
   
   XCTAssertEqualObjects(self.controller.defaultConfig, defaults);
}

- (void)testGetExistingKey {
   NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:@"test_value", @"test_key", nil];
   [self.controller setDefaults:defaults];
   [self.controller activate];
   
   
   CleverTapConfigValue *value = [self.controller get:@"test_key"];
   
   
   XCTAssertNotNil(value);
}

- (void)testGetNonExistentKey {
   CleverTapConfigValue *value = [self.controller get:@"non_existent_key"];
   XCTAssertNotNil(value);
}

- (void)testGetWithNilKey {
   CleverTapConfigValue *value = [self.controller get:nil];
   XCTAssertNotNil(value);
}

#pragma mark - Delegate Tests

- (void)testNotifyInitUpdate {
   OCMStub([self.mockDelegate productConfigDidInitialize]);
   [self.controller notifyInitUpdate];
   OCMVerify([self.mockDelegate productConfigDidInitialize]);
}

- (void)testNotifyFetchUpdate {
   [self.controller notifyFetchUpdate];
   OCMVerify([self.mockDelegate productConfigDidFetch]);
}

- (void)testNotifyActivateUpdate {
   [self.controller notifyActivateUpdate];
   OCMVerify([self.mockDelegate productConfigDidActivate]);
}

- (void)testDelegateMethodsWithNilDelegate {
   XCTAssertNoThrow([self.controller notifyInitUpdate]);
   XCTAssertNoThrow([self.controller notifyFetchUpdate]);
   XCTAssertNoThrow([self.controller notifyActivateUpdate]);
}

#pragma mark - Storage Tests

- (void)testDataArchiveFileName {
   
   
   
   
   NSString *fileName = [self.controller dataArchiveFileName];
   
   
   NSString *expectedFileName = [NSString stringWithFormat:@"clevertap-%@-%@-product-config.plist", @"test-account-id", self.testGuid];
   XCTAssertEqualObjects(fileName, expectedFileName);
}

- (void)testDescription {
   
   
   
   
   NSString *description = [self.controller description];
   
   
   NSString *expectedDescription = [NSString stringWithFormat:@"CleverTap.%@.CTProductConfigController", @"test-account-id"];
   XCTAssertEqualObjects(description, expectedDescription);
}

#pragma mark - Archive

- (void)testArchiveDataSync {
    
    BOOL sync = YES;
    id mockPreferences = OCMClassMock([CTPreferences class]);
    NSArray *testData = @[@"test1", @"test2", @"test3"];
    
    [self.controller _archiveData:testData sync:sync];
    
    
    OCMVerify([mockPreferences archiveObject:testData
                                 forFileName:[OCMArg any]
                                      config:[OCMArg any]]);
}

- (void)testArchiveDataAsync {
    
    BOOL sync = NO;
    XCTestExpectation *archiveExpectation = [self expectationWithDescription:@"Archive operation completed"];
    
    id mockPreferences = OCMClassMock([CTPreferences class]);
    OCMStub([mockPreferences archiveObject:[OCMArg any]
                               forFileName:[OCMArg any]
                                    config:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            [archiveExpectation fulfill];
        });
    
    NSArray *testData = @[@"test1", @"test2", @"test3"];
    
    
    [self.controller _archiveData:testData sync:sync];
    
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    OCMVerify([mockPreferences archiveObject:testData
                                 forFileName:[OCMArg any]
                                      config:[OCMArg any]]);
}

- (void)testArchiveDataUsesCorrectFilePath {
    
    
    NSString *expectedFilePath = @"expected/path/file.plist";
    id mockObject = OCMPartialMock(self.controller);
    OCMStub([mockObject dataArchiveFileName]).andReturn(expectedFilePath);
    
    id mockPreferences = OCMClassMock([CTPreferences class]);
    
    NSArray *testData = @[@"test1", @"test2", @"test3"];
    
    
    [self.controller _archiveData:testData sync:YES];
    
    
    OCMVerify([mockPreferences archiveObject:testData
                                 forFileName:expectedFilePath
                                      config:[OCMArg any]]);
}

- (void)testArchiveDataWithNilData {
    
    NSArray *nilData = nil;
    id mockPreferences = OCMClassMock([CTPreferences class]);
    
    
    
    XCTAssertNoThrow([self.controller _archiveData:nilData sync:YES]);
    
    OCMVerify([mockPreferences archiveObject:nilData
                                 forFileName:[OCMArg any]
                                      config:[OCMArg any]]);
}

- (void)testArchiveDataWithEmptyData {
    
    NSArray *emptyData = @[];
    id mockPreferences = OCMClassMock([CTPreferences class]);
    
    
    
    [self.controller _archiveData:emptyData sync:YES];
    
    
    OCMVerify([mockPreferences archiveObject:emptyData
                                 forFileName:[OCMArg any]
                                      config:[OCMArg any]]);
}

- (void)testUnarchiveDataSyncWithValidData {
    
    BOOL sync = YES;
    NSString *expectedFilePath = @"test/path/file.plist";
    NSSet *expectedAllowedClasses = [NSSet setWithObjects:[NSArray class], [NSDictionary class], nil];
    
    id mockController = OCMPartialMock(self.controller);
    OCMStub([mockController dataArchiveFileName]).andReturn(expectedFilePath);
    
    NSArray *mockData = @[@{@"key1": @"value1"}, @{@"key2": @"value2"}];
    
    id mockPreferences = OCMClassMock([CTPreferences class]);
    OCMStub([mockPreferences unarchiveFromFile:expectedFilePath
                                       ofTypes:expectedAllowedClasses
                                    removeFile:YES]).andReturn(mockData);
    
    OCMExpect([mockController _updateProductConfig:mockData isNew:NO]);
    
    
    [mockController _unarchiveDataSync:sync];
    
    
    OCMVerifyAll(mockController);
    OCMVerify([mockPreferences unarchiveFromFile:expectedFilePath
                                         ofTypes:expectedAllowedClasses
                                      removeFile:YES]);
}

- (void)testUnarchiveDataSyncWithNilData {
    
    BOOL sync = YES;
    
    id mockController = OCMPartialMock(self.controller);
    id mockPreferences = OCMClassMock([CTPreferences class]);
    OCMStub([mockPreferences unarchiveFromFile:[OCMArg any]
                                       ofTypes:[OCMArg any]
                                    removeFile:YES]).andReturn(nil);
    
    [[mockController reject] _updateProductConfig:[OCMArg any] isNew:NO];
    [mockController _unarchiveDataSync:sync];
    
    OCMVerifyAll(mockController);
}

- (void)testUnarchiveDataAsyncWithValidData {
    
    BOOL sync = NO;
    XCTestExpectation *unarchiveExpectation = [self expectationWithDescription:@"Unarchive operation completed"];
    
    id mockController = OCMPartialMock(self.controller);
    NSArray *mockData = @[@{@"key1": @"value1"}, @{@"key2": @"value2"}];
    id mockPreferences = OCMClassMock([CTPreferences class]);
    OCMStub([mockPreferences unarchiveFromFile:[OCMArg any]
                                       ofTypes:[OCMArg any]
                                    removeFile:YES]).andReturn(mockData);
    
    OCMStub([mockController _updateProductConfig:mockData isNew:NO])
        .andDo(^(NSInvocation *invocation) {
            [unarchiveExpectation fulfill];
        });
    
    
    [mockController _unarchiveDataSync:sync];
    
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    OCMVerify([mockController _updateProductConfig:mockData isNew:NO]);
}

- (void)testUnarchiveDataUsesCorrectAllowedClasses {
    
    
    NSSet *expectedAllowedClasses = [NSSet setWithObjects:[NSArray class], [NSDictionary class], nil];
    
    id mockPreferences = OCMClassMock([CTPreferences class]);
    OCMExpect([mockPreferences unarchiveFromFile:[OCMArg any]
                                         ofTypes:expectedAllowedClasses
                                      removeFile:YES]).andReturn(nil);
    
    
    [self.controller _unarchiveDataSync:YES];
    
    
    OCMVerifyAll(mockPreferences);
}

- (void)testUnarchiveDataRemovesFile {
    
    
    id mockPreferences = OCMClassMock([CTPreferences class]);
    OCMExpect([mockPreferences unarchiveFromFile:[OCMArg any]
                                         ofTypes:[OCMArg any]
                                      removeFile:YES]).andReturn(nil);
    
    
    [self.controller _unarchiveDataSync:YES];
    
    
    OCMVerifyAll(mockPreferences);
}

- (void)testUnarchiveDataAsyncUsesOperationQueue {
    
    BOOL sync = NO;
    id mockQueue = OCMClassMock([NSOperationQueue class]);
    
    id mockController = OCMPartialMock(self.controller);
    [mockController setValue:mockQueue forKey:@"_commandQueue"];
    
    OCMExpect([mockQueue setSuspended:NO]);
    OCMExpect([mockQueue addOperation:[OCMArg isKindOfClass:[NSBlockOperation class]]]);
    [mockController _unarchiveDataSync:sync];
    OCMVerifyAll(mockQueue);
}

- (void)testUnarchiveDataUsesCorrectFilePath {
    
    NSString *expectedFilePath = @"custom/archive/path.dat";
    
    id mockController = OCMPartialMock(self.controller);
    OCMStub([mockController dataArchiveFileName]).andReturn(expectedFilePath);
    
    id mockPreferences = OCMClassMock([CTPreferences class]);
    OCMExpect([mockPreferences unarchiveFromFile:expectedFilePath
                                         ofTypes:[OCMArg any]
                                      removeFile:YES]).andReturn(nil);
    
    
    [mockController _unarchiveDataSync:YES];
    
    
    OCMVerifyAll(mockPreferences);
}

- (void)testUpdateProductConfigWithEmptyArray {
   [self.controller updateProductConfig:[NSArray array]];
   XCTAssertNotNil(self.controller.fetchedConfig);
   XCTAssertEqual(self.controller.fetchedConfig.count, 0);
}

- (void)testUpdateProductConfigWithNilArray {
   XCTAssertNoThrow([self.controller updateProductConfig:nil]);
}

@end
