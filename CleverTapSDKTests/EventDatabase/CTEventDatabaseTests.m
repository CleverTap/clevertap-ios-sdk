//
//  CTEventDatabaseTests.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 05/11/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTEventDatabase.h"
#import "CleverTapInstanceConfig.h"

static NSString *kEventName = @"Test Event";
static NSString *kDeviceID = @"Test Device";

@interface CTEventDatabaseTests : XCTestCase

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTEventDatabase *eventDatabase;

@end

@implementation CTEventDatabaseTests

- (void)setUp {
    [super setUp];
    
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    self.eventDatabase = [CTEventDatabase sharedInstanceWithConfig:self.config];
    [self.eventDatabase createTable];
    
}

- (void)tearDown {
    [super tearDown];
    
    [self.eventDatabase deleteTable];
}

- (void)testInsertEventName {
    BOOL insertSuccess = [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    XCTAssertTrue(insertSuccess);
}

- (void)testInsertEventNameAgain {
    BOOL insertSuccess = [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    XCTAssertTrue(insertSuccess);
    
    // Insert same eventName and deviceID again
    BOOL insertSuccessAgain = [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    XCTAssertFalse(insertSuccessAgain);
}

- (void)testEventNameExists {
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    BOOL eventExists = [self.eventDatabase eventExists:kEventName forDeviceID:kDeviceID];
    XCTAssertTrue(eventExists);
}

- (void)testEventNameNotExists {
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    BOOL eventExists = [self.eventDatabase eventExists:@"Test Event 1" forDeviceID:kDeviceID];
    XCTAssertFalse(eventExists);
}

- (void)testUpdateEventSuccess {
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    BOOL updateSuccess = [self.eventDatabase updateEvent:kEventName forDeviceID:kDeviceID];
    XCTAssertTrue(updateSuccess);
}

- (void)testUpdateEventFailure {
    BOOL updateSuccess = [self.eventDatabase updateEvent:kEventName forDeviceID:kDeviceID];
    XCTAssertFalse(updateSuccess);
}

- (void)testGetCountForEventName {
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    [self.eventDatabase updateEvent:kEventName forDeviceID:kDeviceID];
    
    // count should be 2.
    NSInteger eventCount = [self.eventDatabase getCountForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 2);
}

- (void)testGetCountForEventNameNotExists {
    // count should be 0.
    NSInteger eventCount = [self.eventDatabase getCountForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 0);
}

- (void)testFirstTimestampForEventName {
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    NSInteger firstTs = [self.eventDatabase getFirstTimestampForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(firstTs, currentTs);
}

- (void)testLastTimestampForEventName {
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    NSInteger lastTs = [self.eventDatabase getLastTimestampForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(lastTs, currentTs);
}

- (void)testLastTimestampForEventNameUpdated {
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    NSInteger lastTs = [self.eventDatabase getLastTimestampForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(lastTs, currentTs);
    
    NSInteger newCurrentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    NSInteger newLastTs = [self.eventDatabase getLastTimestampForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(newLastTs, newCurrentTs);
    
}

- (void)testDeleteTableSuccess {
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    NSInteger eventCount = [self.eventDatabase getCountForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCount, 1);
    
    // Delete table.
    BOOL deleteSuccess = [self.eventDatabase deleteTable];
    XCTAssertTrue(deleteSuccess);
    NSInteger eventCountAfterDelete = [self.eventDatabase getCountForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqual(eventCountAfterDelete, 0);
    
}

- (void)testEventDetailsForDeviceID {
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    
    CleverTapEventDetail *eventDetail = [self.eventDatabase getEventDetailForEventName:kEventName deviceID:kDeviceID];
    XCTAssertEqualObjects(eventDetail.eventName, kEventName);
    XCTAssertEqual(eventDetail.firstTime, currentTs);
    XCTAssertEqual(eventDetail.lastTime, currentTs);
    XCTAssertEqual(eventDetail.count, 1);
}

- (void)testAllEventsForDeviceID {
    [self.eventDatabase insertData:kEventName deviceID:kDeviceID];
    [self.eventDatabase insertData:@"Test Event 1" deviceID:kDeviceID];
    [self.eventDatabase insertData:@"Test Event 2" deviceID:@"Test Device 1"];
    
    NSArray<CleverTapEventDetail *>*  allEvents = [self.eventDatabase getAllEventsForDeviceID:kDeviceID];
    XCTAssertEqualObjects(allEvents[0].eventName, kEventName);
    XCTAssertEqualObjects(allEvents[1].eventName, @"Test Event 1");
    XCTAssertEqual(allEvents.count, 2);
    
    allEvents = [self.eventDatabase getAllEventsForDeviceID:@"Test Device 1"];
    XCTAssertEqualObjects(allEvents[0].eventName, @"Test Event 2");
    XCTAssertEqual(allEvents.count, 1);
}

- (void)testLeastRecentlyUsedRowsDeleted {
    int maxRow = 10;
    int numberOfRowsToCleanup = 2;
    int totalRowCount = 13;
    for (int i = 0; i < totalRowCount; i++) {
        NSString *eventName = [NSString stringWithFormat:@"Test Event %d", i];
        [self.eventDatabase insertData:eventName deviceID:kDeviceID];
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
        [self.eventDatabase insertData:eventName deviceID:kDeviceID];
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
