//
//  CTProfileDeleteOperationTests.m
//  CleverTapSDKTests
//
//  Covers CTDeleteOperationHandler's handling of deletes that target a field inside an
//  array element - the path exercised by profileRemoveValueForKey with an "items[0].key"
//  style path.
//
//  CTProfileChangeTrackerTest only exercises the utility classes (CTArrayMergeUtils,
//  CTJsonComparisonUtils, CTNumberOperationUtils, CTProfileOperationUtils), so the
//  delete handler itself had no coverage before this.
//

#import <XCTest/XCTest.h>
#import "CTLocalDataStore.h"
#import "CTLocalDataStore+Tests.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"
#import "CTDispatchQueueManager.h"

@interface CTProfileDeleteOperationTests : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTLocalDataStore *dataStore;
@end

@implementation CTProfileDeleteOperationTests

- (void)setUp {
    [super setUp];
    // Each test gets its own accountId, so each gets its own profileFileName. Without
    // this the tests share one file on disk and the async persistence kicked off by
    // setProfileFieldWithKey: races tearDown's file removal and the next test's archive.
    NSString *uniqueAccountId = [NSString stringWithFormat:@"profileDelete%@",
                                 [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:uniqueAccountId
                                                        accountToken:@"testToken"
                                                       accountRegion:@"testRegion"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:@"profileDeleteDevice"];
    CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:self.config];
    self.dataStore = [[CTLocalDataStore alloc] initWithConfig:self.config
                                               profileValues:[NSMutableDictionary new]
                                               andDeviceInfo:deviceInfo
                                        dispatchQueueManager:queueManager];
}

- (void)tearDown {
    // Let any in-flight background persistence finish before removing the file,
    // otherwise the write races the delete.
    [self drainBackgroundQueue];
    [CTPreferences unarchiveFromFile:[self.dataStore profileFileName]
                             ofTypes:[NSSet setWithObject:[NSDictionary class]]
                          removeFile:YES];
    self.dataStore = nil;
    self.config = nil;
    [super tearDown];
}

- (void)drainBackgroundQueue {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Drain datastore background queue"];
    dispatch_async(self.dataStore.backgroundQueue, ^{
        [self.dataStore runOnBackgroundQueue:^{
            [expectation fulfill];
        }];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Deleting a field inside an array element

- (void)test_deleteFieldFromArrayElement_appliesAndRecordsChange {
    [self drainBackgroundQueue];

    [self.dataStore setProfileFieldWithKey:@"items" andValue:@[ @{ @"a": @1, @"b": @2 } ]];

    NSDictionary *changes = [self.dataStore processProfileTree:@"items[0].a"
                                                         value:kCLTAP_DELETE_MARKER
                                                       command:CTProfileOperationDelete];

    NSArray *stored = [self.dataStore getProfileFieldForKey:@"items"];
    XCTAssertEqual(stored.count, 1u, @"The element itself must survive a field level delete");
    XCTAssertNil(stored[0][@"a"], @"'a' should have been deleted from the array element");
    XCTAssertEqualObjects(stored[0][@"b"], @2, @"Sibling keys must be untouched");
    XCTAssertGreaterThan(changes.count, 0u, @"A real deletion must be recorded");
}

// The next two pin deliberate Android parity rather than ideal behaviour. Android's
// DeleteOperationHandler.deleteFromArrayElements sets arrayModified unconditionally once
// it enters the object/object branch, so a no-op or refused delete still reports an
// array level change. iOS matches that on purpose. If Android is ever fixed, these two
// expectations flip on both platforms together.

- (void)test_deleteAbsentFieldFromArrayElement_leavesDataIntact {
    [self drainBackgroundQueue];

    [self.dataStore setProfileFieldWithKey:@"items" andValue:@[ @{ @"a": @1 } ]];

    NSDictionary *changes = [self.dataStore processProfileTree:@"items[0].doesNotExist"
                                                         value:kCLTAP_DELETE_MARKER
                                                       command:CTProfileOperationDelete];

    NSArray *stored = [self.dataStore getProfileFieldForKey:@"items"];
    XCTAssertEqual(stored.count, 1u, @"The element must survive");
    XCTAssertEqualObjects(stored[0][@"a"], @1, @"Nothing should have been removed");
    XCTAssertGreaterThan(changes.count, 0u,
                         @"Android parity: a no-op delete still records an array level change");
}

- (void)test_deleteNonLeafFieldFromArrayElement_isRefused {
    [self drainBackgroundQueue];

    [self.dataStore setProfileFieldWithKey:@"items" andValue:@[ @{ @"nested": @{ @"x": @1 } } ]];

    NSDictionary *changes = [self.dataStore processProfileTree:@"items[0].nested"
                                                         value:kCLTAP_DELETE_MARKER
                                                       command:CTProfileOperationDelete];

    NSArray *stored = [self.dataStore getProfileFieldForKey:@"items"];
    XCTAssertNotNil(stored[0][@"nested"],
                    @"deleteValue: refuses non leaf values, the backend can only delete leaves");
    XCTAssertEqualObjects(stored[0][@"nested"][@"x"], @1, @"The nested object must be untouched");
    XCTAssertGreaterThan(changes.count, 0u,
                         @"Android parity: a refused delete still records an array level change");
}

@end
