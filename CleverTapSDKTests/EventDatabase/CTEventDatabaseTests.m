//
//  CTEventDatabaseTests.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 05/11/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTEventDatabase.h"
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
    self.eventDatabase = [[CTEventDatabase alloc] initWithClock:mockClock];
    self.normalizedEventName = [CTUtils getNormalizedName:kEventName];
}

- (void)tearDown {
    [super tearDown];
    
    [self.eventDatabase deleteAllRows];
}

- (void)testGetDatabaseVersion {
    NSInteger dbVersion = [self.eventDatabase databaseVersion];
    XCTAssertEqual(dbVersion, 1);
}

- (void)testInsertEventName {
    BOOL insertSuccess = [self.eventDatabase insertEvent:kEventName
                                     normalizedEventName:self.normalizedEventName
                                                deviceID:kDeviceID];
    XCTAssertTrue(insertSuccess);
}

- (void)testInsertEventNameAgain {
    BOOL insertSuccess = [self.eventDatabase insertEvent:kEventName 
                                     normalizedEventName:self.normalizedEventName
                                                deviceID:kDeviceID];
    XCTAssertTrue(insertSuccess);
    
    // Insert same eventName and deviceID again
    BOOL insertSuccessAgain = [self.eventDatabase insertEvent:kEventName 
                                          normalizedEventName:self.normalizedEventName
                                                     deviceID:kDeviceID];
    XCTAssertFalse(insertSuccessAgain);
}

- (void)testEventNameExists {
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    BOOL eventExists = [self.eventDatabase eventExists:self.normalizedEventName forDeviceID:kDeviceID];
    XCTAssertTrue(eventExists);
    
    NSString *normalizedEventName = [CTUtils getNormalizedName:@"TesT   EveNT"];
    eventExists = [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID];
    XCTAssertTrue(eventExists);
    
    normalizedEventName = [CTUtils getNormalizedName:@"TEST EVENT"];
    eventExists = [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID];
    XCTAssertTrue(eventExists);
}

- (void)testEventNameNotExists {
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    NSString *normalizedEventName = [CTUtils getNormalizedName:@"TesT   EveNT 1"];
    BOOL eventExists = [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID];
    XCTAssertFalse(eventExists);
    
    normalizedEventName = [CTUtils getNormalizedName:@"Test.Event"];
    eventExists = [self.eventDatabase eventExists:normalizedEventName forDeviceID:kDeviceID];
    XCTAssertFalse(eventExists);
}

- (void)testUpdateEventSuccess {
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    BOOL updateSuccess = [self.eventDatabase updateEvent:self.normalizedEventName forDeviceID:kDeviceID];
    XCTAssertTrue(updateSuccess);
}

- (void)testUpsertEventSuccessWhenInsert {
    BOOL upsertSuccess = [self.eventDatabase upsertEvent:kEventName
                                     normalizedEventName:self.normalizedEventName
                                                deviceID:kDeviceID];
    XCTAssertTrue(upsertSuccess);
}

- (void)testUpsertEventSuccessWhenUpdate {
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];

    BOOL upsertSuccess = [self.eventDatabase upsertEvent:kEventName
                                     normalizedEventName:self.normalizedEventName
                                                deviceID:kDeviceID];
    XCTAssertTrue(upsertSuccess);
    
    NSInteger eventCount = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 2);
}

- (void)testGetCountForEventName {
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    [self.eventDatabase updateEvent:self.normalizedEventName forDeviceID:kDeviceID];
    
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
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    NSInteger firstTs = [self.eventDatabase getFirstTimestamp:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(firstTs, currentTs);
}

- (void)testLastTimestampForEventName {
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    NSInteger currentTs = [self.mockClock.currentDate timeIntervalSince1970];
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    NSInteger lastTs = [self.eventDatabase getLastTimestamp:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(lastTs, currentTs);
}

- (void)testLastTimestampForEventNameUpdated {
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    NSInteger currentTs = [self.mockClock.currentDate timeIntervalSince1970];
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    NSInteger lastTs = [self.eventDatabase getLastTimestamp:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(lastTs, currentTs);
    
    self.mockClock.currentDate = [self.mockClock.currentDate dateByAddingTimeInterval:5 * 60];
    NSInteger newCurrentTs = [self.mockClock.currentDate timeIntervalSince1970];
    [self.eventDatabase updateEvent:self.normalizedEventName forDeviceID:kDeviceID];
    NSInteger newLastTs = [self.eventDatabase getLastTimestamp:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(newLastTs, newCurrentTs);
    
}

- (void)testDeleteAllRowsSuccess {
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    NSInteger eventCount = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 1);
    
    // Delete table.
    BOOL deleteSuccess = [self.eventDatabase deleteAllRows];
    XCTAssertTrue(deleteSuccess);
    NSInteger eventCountAfterDelete = [self.eventDatabase getEventCount:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCountAfterDelete, 0);
    
}

- (void)testEventDetailsForDeviceID {
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    CleverTapEventDetail *eventDetail = [self.eventDatabase getEventDetail:self.normalizedEventName deviceID:kDeviceID];
    XCTAssertEqualObjects(eventDetail.eventName, kEventName);
    XCTAssertEqualObjects(eventDetail.normalizedEventName, self.normalizedEventName);
    XCTAssertEqual(eventDetail.firstTime, currentTs);
    XCTAssertEqual(eventDetail.lastTime, currentTs);
    XCTAssertEqual(eventDetail.count, 1);
    XCTAssertEqualObjects(eventDetail.deviceID, kDeviceID);
}

- (void)testAllEventsForDeviceID {
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:kDeviceID];
    
    // Insert to same device id kDeviceID
    NSString *eventName = @"Test Event 1";
    NSString *normalizedName = [CTUtils getNormalizedName:eventName];
    [self.eventDatabase insertEvent:eventName
                normalizedEventName:normalizedName
                           deviceID:kDeviceID];
    
    // Insert to different device id
    [self.eventDatabase insertEvent:kEventName
                normalizedEventName:self.normalizedEventName
                           deviceID:@"Test Device 1"];
    
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
        [self.eventDatabase insertEvent:eventName
                    normalizedEventName:normalizedName
                               deviceID:kDeviceID];
    }
    NSArray<CleverTapEventDetail *>*  allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    XCTAssertEqual(allEvents.count, totalRowCount);
    
    // When deleteLeastRecentlyUsedRows is called using max row limit and numberOfRowsToCleanup
    // the deleted row count will be `totalRowCount - (maxRow - numberOfRowsToCleanup)`
    [self.eventDatabase deleteLeastRecentlyUsedRows:maxRow numberOfRowsToCleanup:numberOfRowsToCleanup];
    allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    int deletedRowCount = totalRowCount - (maxRow - numberOfRowsToCleanup);
    XCTAssertEqual(allEvents.count, totalRowCount - deletedRowCount);
}

- (void)testLeastRecentlyUsedRowsNotDeleted {
    int maxRow = 10;
    int numberOfRowsToCleanup = 2;
    int totalRowCount = 7;
    for (int i = 0; i < totalRowCount; i++) {
        NSString *eventName = [NSString stringWithFormat:@"Test Event %d", i];
        NSString *normalizedName = [CTUtils getNormalizedName:eventName];
        [self.eventDatabase insertEvent:eventName
                    normalizedEventName:normalizedName
                               deviceID:kDeviceID];
    }
    NSArray<CleverTapEventDetail *>*  allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    XCTAssertEqual(allEvents.count, totalRowCount);
    
    // Here any row will not be deleted as it is within limit.
    [self.eventDatabase deleteLeastRecentlyUsedRows:maxRow numberOfRowsToCleanup:numberOfRowsToCleanup];
    allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    XCTAssertEqual(allEvents.count, totalRowCount);
}

- (NSString *)databasePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"CleverTap-Events.db"];
}

@end
