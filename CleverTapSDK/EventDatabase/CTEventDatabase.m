//
//  CTEventDatabase.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 25/10/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTEventDatabase.h"
#import "CTConstants.h"
#import "CTSystemClock.h"

@interface CTEventDatabase()

@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@property (nonatomic, strong) id <CTClock> clock;

@end

@implementation CTEventDatabase {
    sqlite3 *_eventDatabase;
}

+ (instancetype)sharedInstanceWithDispatchQueueManager:(CTDispatchQueueManager*)dispatchQueueManager {
    static CTEventDatabase *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithDispatchQueueManager:dispatchQueueManager
                                                              clock:[[CTSystemClock alloc] init]];
    });
    return sharedInstance;
}

- (instancetype)initWithDispatchQueueManager:(CTDispatchQueueManager*)dispatchQueueManager
                                       clock:(id<CTClock>)clock {
    if (self = [super init]) {
        _dispatchQueueManager = dispatchQueueManager;
        _clock = clock;
        [self openDatabase];
        
        // Perform cleanup/deletion of rows on instance creation if total row count
        // exceeds mac threshold limit.
        NSInteger maxRowLimit = CLTAP_EVENT_DB_MAX_ROW_LIMIT;
        NSInteger numberOfRowsToCleanup = CLTAP_EVENT_DB_ROWS_TO_CLEANUP;
        [self deleteLeastRecentlyUsedRows:maxRowLimit numberOfRowsToCleanup:numberOfRowsToCleanup completion:nil];
    }
    return self;
}

- (void)databaseVersionWithCompletion:(void (^)(NSInteger version))completion {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }
    
    const char *querySQL = "PRAGMA user_version;";
    __block NSInteger version = 0;

    [self.dispatchQueueManager runSerialAsync:^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                version = sqlite3_column_int(statement, 0);
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"SQL prepare query error: %s", sqlite3_errmsg(self->_eventDatabase));
        }
        
        if (completion) {
            completion(version);
        }
    }];
}

- (void)insertEvent:(NSString *)eventName
normalizedEventName:(NSString *)normalizedEventName
           deviceID:(NSString *)deviceID
         completion:(void (^)(BOOL success))completion {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }
    
    __block BOOL success = NO;
    // For new event, set count as 1
    NSInteger count = 1;
    NSInteger currentTs = [[self.clock timeIntervalSince1970] integerValue];
    const char *insertSQL = "INSERT INTO CTUserEventLogs (eventName, normalizedEventName, count, firstTs, lastTs, deviceID) VALUES (?, ?, ?, ?, ?, ?)";
    
    [self.dispatchQueueManager runSerialAsync:^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, insertSQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [normalizedEventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, 3, (int)count);
            sqlite3_bind_int(statement, 4, (int)currentTs);
            sqlite3_bind_int(statement, 5, (int)currentTs);
            sqlite3_bind_text(statement, 6, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            int result = sqlite3_step(statement);
            if (result == SQLITE_DONE) {
                success = YES;
            } else {
                CleverTapLogStaticInternal(@"Insert Table SQL error: %s", sqlite3_errmsg(self->_eventDatabase));
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"Failed to prepare insert statement: %s", sqlite3_errmsg(self->_eventDatabase));
        }
        
        if (completion) {
            completion(success);
        }
    }];
}

- (void)updateEvent:(NSString *)normalizedEventName
        forDeviceID:(NSString *)deviceID
         completion:(void (^)(BOOL success))completion {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }
    
    NSInteger currentTs = [[self.clock timeIntervalSince1970] integerValue];
    const char *updateSQL =
            "UPDATE CTUserEventLogs SET count = count + 1, lastTs = ? WHERE normalizedEventName = ? AND deviceID = ?";
    __block BOOL success = NO;

    [self.dispatchQueueManager runSerialAsync:^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, updateSQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, (int)currentTs);
            sqlite3_bind_text(statement, 2, [normalizedEventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            int result = sqlite3_step(statement);
            if (result == SQLITE_DONE) {
                success = YES;
            } else {
                CleverTapLogStaticInternal(@"Update Table SQL error: %s", sqlite3_errmsg(self->_eventDatabase));
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"Failed to prepare update statement: %s", sqlite3_errmsg(self->_eventDatabase));
        }
        
        if (completion) {
            completion(success);
        }
    }];
}

- (void)upsertEvent:(NSString *)eventName
normalizedEventName:(NSString *)normalizedEventName
           deviceID:(NSString *)deviceID {
    [self.dispatchQueueManager runSerialAsync:^{
        [self eventExists:normalizedEventName forDeviceID:deviceID completion:^(BOOL exists) {
            if (!exists) {
                [self insertEvent:eventName normalizedEventName:normalizedEventName deviceID:deviceID completion:nil];
            } else {
                [self updateEvent:normalizedEventName forDeviceID:deviceID completion:nil];
            }
        }];
    }];
}

- (void)eventExists:(NSString *)normalizedEventName
        forDeviceID:(NSString *)deviceID
         completion:(void (^)(BOOL exists))completion {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }

    const char *query = "SELECT COUNT(*) FROM CTUserEventLogs WHERE normalizedEventName = ? AND deviceID = ?";
    __block BOOL exists = NO;
    
    [self.dispatchQueueManager runSerialAsync:^{
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(self->_eventDatabase, query, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [normalizedEventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                // Check if the count is greater than 0
                int count = sqlite3_column_int(statement, 0);
                if (count > 0) {
                    exists = YES;
                }
            } else {
                CleverTapLogStaticInternal(@"SQL check query error: %s", sqlite3_errmsg(self->_eventDatabase));
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"SQL prepare query error: %s", sqlite3_errmsg(self->_eventDatabase));
        }

        if (completion) {
            completion(exists);
        }
    }];
}

- (void)dealloc {
    [self.dispatchQueueManager runSerialAsync:^{
        [self closeDatabase];
    }];
}

- (NSInteger)getEventCount:(NSString *)normalizedEventName
                  deviceID:(NSString *)deviceID {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return -1;
    }

    const char *querySQL = "SELECT count FROM CTUserEventLogs WHERE normalizedEventName = ? AND deviceID = ?";
    __block NSInteger count = -1;
    void (^taskBlock)(void) = ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [normalizedEventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                count = sqlite3_column_int(statement, 0);
            } else {
                count = 0;
                CleverTapLogStaticInternal(@"No event found with eventName: %@ and deviceID: %@", normalizedEventName, deviceID);
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"SQL prepare query error: %s", sqlite3_errmsg(self->_eventDatabase));
        }
    };

    if ([self.dispatchQueueManager inSerialQueue]) {
        // If already on the serial queue, execute directly without semaphore
        taskBlock();
    } else {
        // Otherwise, use semaphore for synchronous execution
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self.dispatchQueueManager runSerialAsync:^{
            taskBlock();
            dispatch_semaphore_signal(semaphore);
        }];
        if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3)) != 0) {
            CleverTapLogStaticInternal(@"Timeout occurred while getting event count.");
            return -1;
        }
    }

    return count;
}

- (CleverTapEventDetail *)getEventDetail:(NSString *)normalizedEventName
                                deviceID:(NSString *)deviceID {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return nil;
    }

    const char *querySQL = "SELECT eventName, normalizedEventName, count, firstTs, lastTs, deviceID FROM CTUserEventLogs WHERE normalizedEventName = ? AND deviceID = ?";
    __block CleverTapEventDetail *eventDetail = nil;
    void (^taskBlock)(void) = ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [normalizedEventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                const char *eventName = (const char *)sqlite3_column_text(statement, 0);
                const char *normalizedEventName = (const char *)sqlite3_column_text(statement, 1);
                NSInteger count = sqlite3_column_int(statement, 2);
                NSInteger firstTs = sqlite3_column_int(statement, 3);
                NSInteger lastTs = sqlite3_column_int(statement, 4);
                const char *deviceID = (const char *)sqlite3_column_text(statement, 5);
                
                eventDetail = [[CleverTapEventDetail alloc] init];
                eventDetail.eventName = eventName ? [NSString stringWithUTF8String:eventName] : nil;
                eventDetail.normalizedEventName = [NSString stringWithUTF8String:normalizedEventName];
                eventDetail.count = count;
                eventDetail.firstTime = firstTs;
                eventDetail.lastTime = lastTs;
                eventDetail.deviceID = [NSString stringWithUTF8String:deviceID];
                
            } else {
                CleverTapLogStaticInternal(@"No event found with eventName: %@ and deviceID: %@", normalizedEventName, deviceID);
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"SQL prepare query error: %s", sqlite3_errmsg(self->_eventDatabase));
        }
    };
    
    if ([self.dispatchQueueManager inSerialQueue]) {
        // If already on the serial queue, execute directly without semaphore
        taskBlock();
    } else {
        // Otherwise, use semaphore for synchronous execution
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self.dispatchQueueManager runSerialAsync:^{
            taskBlock();
            dispatch_semaphore_signal(semaphore);
        }];
        if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3)) != 0) {
            CleverTapLogStaticInternal(@"Timeout occurred while getting event detail.");
            return nil;
        }
    }

    return eventDetail;
}

- (NSArray<CleverTapEventDetail *> *)getAllEventsForDeviceID:(NSString *)deviceID {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return nil;
    }

    const char *querySQL = "SELECT eventName, normalizedEventName, count, firstTs, lastTs, deviceID FROM CTUserEventLogs WHERE deviceID = ?";
    __block NSMutableArray *eventDataArray = [NSMutableArray array];
    void (^taskBlock)(void) = ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *eventName = (const char *)sqlite3_column_text(statement, 0);
                const char *normalizedEventName = (const char *)sqlite3_column_text(statement, 1);
                NSInteger count = sqlite3_column_int(statement, 2);
                NSInteger firstTs = sqlite3_column_int(statement, 3);
                NSInteger lastTs = sqlite3_column_int(statement, 4);
                const char *deviceID = (const char *)sqlite3_column_text(statement, 5);
                
                CleverTapEventDetail *ed = [[CleverTapEventDetail alloc] init];
                ed.count = count;
                ed.firstTime = firstTs;
                ed.lastTime = lastTs;
                ed.eventName = eventName ? [NSString stringWithUTF8String:eventName] : nil;
                ed.normalizedEventName = [NSString stringWithUTF8String:normalizedEventName];
                ed.deviceID = [NSString stringWithUTF8String:deviceID];
                
                // Adding the CleverTapEventDetail to the result array
                [eventDataArray addObject:ed];
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"SQL prepare query error: %s", sqlite3_errmsg(self->_eventDatabase));
        }
    };
    
    if ([self.dispatchQueueManager inSerialQueue]) {
        // If already on the serial queue, execute directly without semaphore
        taskBlock();
    } else {
        // Otherwise, use semaphore for synchronous execution
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self.dispatchQueueManager runSerialAsync:^{
            taskBlock();
            dispatch_semaphore_signal(semaphore);
        }];
        if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3)) != 0) {
            CleverTapLogStaticInternal(@"Timeout occurred while getting all event details.");
            return nil;
        }
    }
    return [eventDataArray copy];
}

- (void)deleteAllRowsWithCompletion:(void (^)(BOOL success))completion {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }

    const char *querySQL = "DELETE FROM CTUserEventLogs";
    __block BOOL success = NO;

    [self.dispatchQueueManager runSerialAsync:^{
        char *errMsg = NULL;
        int result = sqlite3_exec(self->_eventDatabase, querySQL, NULL, NULL, &errMsg);
        
        if (result == SQLITE_OK) {
            success = YES;
        } else {
            CleverTapLogStaticInternal(@"SQL Error deleting all rows from CTUserEventLogs: %s", errMsg);
            sqlite3_free(errMsg);
        }
        
        if (completion) {
            completion(success);
        }
    }];
}

- (void)deleteLeastRecentlyUsedRows:(NSInteger)maxRowLimit
              numberOfRowsToCleanup:(NSInteger)numberOfRowsToCleanup
                         completion:(void (^)(BOOL success))completion {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }
    
    __block BOOL success = NO;
    
    [self.dispatchQueueManager runSerialAsync:^{
        // Begin a transaction to ensure atomicity
        sqlite3_exec(self->_eventDatabase, "BEGIN TRANSACTION;", NULL, NULL, NULL);
        
        // Create an index on the `lastTs` column if it doesn't exist which will improve performance
        // while deletion when table is large
        const char *createIndexSQL = "CREATE INDEX IF NOT EXISTS idx_lastTs ON CTUserEventLogs(lastTs);";
        char *errMsg = NULL;
        int indexResult = sqlite3_exec(self->_eventDatabase, createIndexSQL, NULL, NULL, &errMsg);
        
        if (indexResult != SQLITE_OK) {
            CleverTapLogStaticInternal(@"Failed to create index on lastTs: %s", errMsg);
            sqlite3_free(errMsg);
            sqlite3_exec(self->_eventDatabase, "ROLLBACK;", NULL, NULL, NULL);  // Rollback transaction if index creation fails
            return;
        }
        
        NSString *countQuerySQL = @"SELECT COUNT(*) FROM CTUserEventLogs;";
        sqlite3_stmt *countStatement;
        if (sqlite3_prepare_v2(self->_eventDatabase, [countQuerySQL UTF8String], -1, &countStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(countStatement) == SQLITE_ROW) {
                NSInteger currentRowCount = sqlite3_column_int(countStatement, 0);
                if (currentRowCount > maxRowLimit) {
                    // Calculate the number of rows to delete
                    NSInteger rowsToDelete = currentRowCount - (maxRowLimit - numberOfRowsToCleanup);
                    
                    // Delete the least recently used rows based on lastTs
                    const char *deleteSQL = "DELETE FROM CTUserEventLogs WHERE (normalizedEventName, deviceID) IN (SELECT normalizedEventName, deviceID FROM CTUserEventLogs ORDER BY lastTs ASC LIMIT ?);";
                    sqlite3_stmt *deleteStatement;
                    if (sqlite3_prepare_v2(self->_eventDatabase, deleteSQL, -1, &deleteStatement, NULL) == SQLITE_OK) {
                        sqlite3_bind_int(deleteStatement, 1, (int)rowsToDelete);
                        
                        int result = sqlite3_step(deleteStatement);
                        if (result == SQLITE_DONE) {
                            success = YES;
                        } else {
                            CleverTapLogStaticInternal(@"SQL Error deleting rows: %s", sqlite3_errmsg(self->_eventDatabase));
                        }

                        sqlite3_finalize(deleteStatement);
                    } else {
                        CleverTapLogStaticInternal(@"SQL prepare query error: %s", sqlite3_errmsg(self->_eventDatabase));
                    }
                } else {
                    success = YES;
                }
            } else {
                CleverTapLogStaticInternal(@"Failed to count rows in CTUserEventLogs");
            }
            sqlite3_finalize(countStatement);
        } else {
            CleverTapLogStaticInternal(@"SQL prepare query error: %s", sqlite3_errmsg(self->_eventDatabase));
        }
        
        // Commit or rollback the transaction based on success
        if (success) {
            sqlite3_exec(self->_eventDatabase, "COMMIT;", NULL, NULL, NULL);
        } else {
            sqlite3_exec(self->_eventDatabase, "ROLLBACK;", NULL, NULL, NULL);
        }
        
        if (completion) {
            completion(success);
        }
    }];
}

#pragma mark - Private methods

- (void)openDatabase {
    NSString *databasePath = [self databasePath];
    void (^taskBlock)(void) = ^{
        if (sqlite3_open_v2([databasePath UTF8String], &self->_eventDatabase, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, NULL) == SQLITE_OK) {
            // Create table, check and update the version if needed
            [self createTableWithCompletion:^(BOOL exists) {
                [self checkAndUpdateDatabaseVersion];
            }];
        } else {
            CleverTapLogStaticInternal(@"Failed to open database - CleverTap-Events.db");
        }
    };
    
    if ([self.dispatchQueueManager inSerialQueue]) {
        // If already on the serial queue, execute directly without semaphore
        taskBlock();
    } else {
        // Otherwise, use semaphore for synchronous execution
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self.dispatchQueueManager runSerialAsync:^{
            taskBlock();
            dispatch_semaphore_signal(semaphore);
        }];
        if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3)) != 0) {
            CleverTapLogStaticInternal(@"Timeout occurred while opening database.");
        }
    }
}

- (void)createTableWithCompletion:(void (^)(BOOL success))completion {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }
    
    __block BOOL success = NO;
    
    [self.dispatchQueueManager runSerialAsync:^{
        char *errMsg;
        const char *createTableSQL = "CREATE TABLE IF NOT EXISTS CTUserEventLogs (eventName TEXT, normalizedEventName TEXT, count INTEGER, firstTs INTEGER, lastTs INTEGER, deviceID TEXT, PRIMARY KEY (normalizedEventName, deviceID))";
        if (sqlite3_exec(self->_eventDatabase, createTableSQL, NULL, NULL, &errMsg) == SQLITE_OK) {
            success = YES;
            
            // Set the database version to the initial version, ie 1.
            [self setDatabaseVersion:CLTAP_DATABASE_VERSION];
        } else {
            CleverTapLogStaticInternal(@"Create Table SQL error: %s", errMsg);
            sqlite3_free(errMsg);
        }
        
        if (completion) {
            completion(success);
        }
    }];
}

- (void)closeDatabase {
    if (_eventDatabase) {
        sqlite3_close(_eventDatabase);
        _eventDatabase = NULL;
    }
}

- (void)setDatabaseVersion:(NSInteger)version {
    if (!_eventDatabase) {
        CleverTapLogStaticInternal(@"Event database is not open, cannot execute SQL.");
        return;
    }

    const char *updateSQL = "PRAGMA user_version = ?";
    
    [self.dispatchQueueManager runSerialAsync:^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, updateSQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, (int)version);
            
            int result = sqlite3_step(statement);
            if (result != SQLITE_DONE) {
                CleverTapLogStaticInternal(@"SQL Error: %s", sqlite3_errmsg(self->_eventDatabase));
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogStaticInternal(@"Failed to prepare update statement: %s", sqlite3_errmsg(self->_eventDatabase));
        }
   }];
}

- (void)checkAndUpdateDatabaseVersion {
    [self databaseVersionWithCompletion:^(NSInteger currentVersion) {
        if (currentVersion < CLTAP_DATABASE_VERSION) {
            // Handle version changes here in future.
            [self setDatabaseVersion:CLTAP_DATABASE_VERSION];
            CleverTapLogStaticInternal(@"Schema migration required. Current version: %ld, Target version: %ld", (long)currentVersion, (long)CLTAP_DATABASE_VERSION);
        }
    }];
}

- (NSString *)databasePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"CleverTap-Events.db"];
}

@end
