//
//  CTEventDatabaseTests.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 05/11/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTEventDatabase+Tests.h"
#import "CTUtils.h"
#import "CTClockMock.h"

static NSString *kEventName = @"Test Event";
static NSString *kDeviceID = @"Test Device";

@interface CTEventDatabaseTests : XCTestCase

@property (nonatomic, strong) CTEventDatabase *eventDatabase;
@property (nonatomic, strong) NSString *normalizedEventName;
@property (nonatomic, strong) CTClockMock *mockClock;

@end

@implementation CTEventDatabaseTests

- (void)setUp {
    [super setUp];
    
    CTClockMock *mockClock = [[CTClockMock alloc] initWithCurrentDate:[NSDate date]];
    self.mockClock = mockClock;
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken" accountRegion:@"testRegion"];
    CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:config];
    self.eventDatabase = [[CTEventDatabase alloc] initWithDispatchQueueManager:queueManager clock:mockClock];
    self.normalizedEventName = [CTUtils getNormalizedName:kEventName];
}

- (void)tearDown {
    [super tearDown];
    
    XCTestExpectation *deleteExpectation = [self expectationWithDescription:@"Delete all rows"];
    [self.eventDatabase deleteAllRowsWithCompletion:^(BOOL success) {
        [deleteExpectation fulfill];
    }];
    [self waitForExpectations:@[deleteExpectation] timeout:2.0];
}

- (void)testGetDatabaseVersion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Database version"];
    [self.eventDatabase databaseVersionWithCompletion:^(NSInteger currentVersion) {
        XCTAssertEqual(currentVersion, 1);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testInsertEventName {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Insert event"];
    [self.eventDatabase insertEvent:kEventName
                 normalizedEventName:self.normalizedEventName
                            deviceID:kDeviceID
                          completion:^(BOOL success) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testEventNameExists {
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Event exists"];
    [self.eventDatabase eventExists:self.normalizedEventName forDeviceID:kDeviceID completion:^(BOOL exists) {
        XCTAssertTrue(exists);
        [expectation fulfill];
    }];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Event exists 1"];
    NSString *normalizedEventName = [CTUtils getNormalizedName:@"TesT   EveNT"];
    [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID completion:^(BOOL exists) {
        XCTAssertTrue(exists);
        [expectation1 fulfill];
    }];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Event exists 2"];
    normalizedEventName = [CTUtils getNormalizedName:@"TEST EVENT"];
    [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID completion:^(BOOL exists) {
        XCTAssertTrue(exists);
        [expectation2 fulfill];
    }];
    [self waitForExpectations:@[expectation, expectation1, expectation2] timeout:2.0];
}

- (void)testEventNameNotExists {
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Event exists"];
    NSString *normalizedEventName = [CTUtils getNormalizedName:@"TesT   EveNT 1"];
    [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID completion:^(BOOL exists) {
        XCTAssertFalse(exists);
        [expectation fulfill];
    }];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Event exists 1"];
    normalizedEventName = [CTUtils getNormalizedName:@"Test.Event"];
    [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID completion:^(BOOL exists) {
        XCTAssertFalse(exists);
        [expectation1 fulfill];
    }];
    [self waitForExpectations:@[expectation, expectation1] timeout:2.0];
}

- (void)testUpdateEventSuccess {
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Update event"];
    [self.eventDatabase updateEvent:self.normalizedEventName forDeviceID:kDeviceID completion:^(BOOL success) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testUpsertEventWhenUpdate {
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    NSInteger eventCount = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 1);

    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    eventCount = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 2);
}

- (void)testGetCountForEventName {
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    // count should be 2.
    NSInteger eventCount = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 2);
}

- (void)testGetCountForEventNameNotExists {
    // count should be 0.
    NSInteger eventCount = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 0);
}

- (void)testFirstTimestampForEventName {
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    NSInteger currentTs = [self.mockClock.currentDate timeIntervalSince1970];
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    CleverTapEventDetail *event = [self.eventDatabase getEventDetail:self.normalizedEventName deviceID:kDeviceID];
    NSInteger firstTs = event.firstTime;
    XCTAssertEqual(firstTs, currentTs);
}

- (void)testLastTimestampForEventName {
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    NSInteger currentTs = [self.mockClock.currentDate timeIntervalSince1970];
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    CleverTapEventDetail *event = [self.eventDatabase getEventDetail:self.normalizedEventName deviceID:kDeviceID];
    NSInteger lastTs = event.lastTime;
    XCTAssertEqual(lastTs, currentTs);
}

- (void)testLastTimestampForEventNameUpdated {
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    NSInteger currentTs = [self.mockClock.currentDate timeIntervalSince1970];
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    CleverTapEventDetail *event = [self.eventDatabase getEventDetail:self.normalizedEventName deviceID:kDeviceID];
    NSInteger lastTs = event.lastTime;
    XCTAssertEqual(lastTs, currentTs);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    NSInteger newCurrentTs = [self.mockClock.currentDate timeIntervalSince1970];
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    CleverTapEventDetail *newEvent = [self.eventDatabase getEventDetail:self.normalizedEventName deviceID:kDeviceID];
    NSInteger newLastTs = newEvent.lastTime;
    XCTAssertEqual(newLastTs, newCurrentTs);
    
}

- (void)testDeleteAllRowsSuccess {
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    NSInteger eventCount = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 1);
    
    // Delete table.
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete all rows"];
    [self.eventDatabase deleteAllRowsWithCompletion:^(BOOL success) {
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    NSInteger eventCountAfterDelete = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCountAfterDelete, 0);
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testEventDetailsForDeviceID {
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    CleverTapEventDetail *eventDetail = [self.eventDatabase getEventDetail:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqualObjects(eventDetail.eventName, kEventName);
    XCTAssertEqualObjects(eventDetail.normalizedEventName, self.normalizedEventName);
    XCTAssertEqual(eventDetail.firstTime, currentTs);
    XCTAssertEqual(eventDetail.lastTime, currentTs);
    XCTAssertEqual(eventDetail.count, 1);
    XCTAssertEqualObjects(eventDetail.deviceID, kDeviceID);
}

- (void)testAllEventsForDeviceID {
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:kDeviceID];
    
    // Insert to same device id kDeviceID
    NSString *eventName = @"Test Event 1";
    NSString *normalizedName = [CTUtils getNormalizedName:eventName];
    
    [self.eventDatabase upsertEvent:eventName normalizedEventName:normalizedName deviceID:kDeviceID];
    
    // Insert to different device id
    [self.eventDatabase upsertEvent:kEventName normalizedEventName:self.normalizedEventName deviceID:@"Test Device 1"];
    
    NSArray<CleverTapEventDetail *>*  allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    XCTAssertEqualObjects(allEvents[0].eventName, kEventName);
    XCTAssertEqualObjects(allEvents[1].eventName, eventName);
    XCTAssertEqual(allEvents.count, 2);
    
    allEvents = [self.eventDatabase getAllEventsForDeviceID:@"Test Device 1"];
    XCTAssertEqualObjects(allEvents[0].eventName, kEventName);
    XCTAssertEqual(allEvents.count, 1);
}

- (void)testLeastRecentlyUsedRowsDeleted {
    int maxRow = 10;
    int numberOfRowsToCleanup = 2;
    int totalRowCount = 13;
    for (int i = 0; i < totalRowCount; i++) {
        NSString *eventName = [NSString stringWithFormat:@"Test Event %d", i];
        NSString *normalizedName = [CTUtils getNormalizedName:eventName];
        [self.eventDatabase upsertEvent:eventName normalizedEventName:normalizedName deviceID:kDeviceID];
    }
    NSArray<CleverTapEventDetail *>*  allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    XCTAssertEqual(allEvents.count, totalRowCount);
    
    // When deleteLeastRecentlyUsedRows is called using max row limit and numberOfRowsToCleanup
    // the deleted row count will be `totalRowCount - (maxRow - numberOfRowsToCleanup)`
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete rows"];
    [self.eventDatabase deleteLeastRecentlyUsedRows:maxRow numberOfRowsToCleanup:numberOfRowsToCleanup completion:^(BOOL success) {
        NSArray<CleverTapEventDetail *>* allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
        int deletedRowCount = totalRowCount - (maxRow - numberOfRowsToCleanup);
        XCTAssertEqual(allEvents.count, totalRowCount - deletedRowCount);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testLeastRecentlyUsedRowsNotDeleted {
    int maxRow = 10;
    int numberOfRowsToCleanup = 2;
    int totalRowCount = 7;
    for (int i = 0; i < totalRowCount; i++) {
        NSString *eventName = [NSString stringWithFormat:@"Test Event %d", i];
        NSString *normalizedName = [CTUtils getNormalizedName:eventName];
        [self.eventDatabase upsertEvent:eventName normalizedEventName:normalizedName deviceID:kDeviceID];
    }
    NSArray<CleverTapEventDetail *>*  allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    XCTAssertEqual(allEvents.count, totalRowCount);
    
    // Here any row will not be deleted as it is within limit.
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete rows"];
    [self.eventDatabase deleteLeastRecentlyUsedRows:maxRow numberOfRowsToCleanup:numberOfRowsToCleanup completion:^(BOOL success) {
        NSArray<CleverTapEventDetail *>* allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
        XCTAssertEqual(allEvents.count, totalRowCount);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (NSString *)databasePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"CleverTap-Events.db"];
}

@end
