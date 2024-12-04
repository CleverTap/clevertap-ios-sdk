//
//  CTEventDatabase.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 25/10/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTEventDatabase.h"
#import "CTConstants.h"

@interface CTEventDatabase()

@property (nonatomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CTEventDatabase {
    sqlite3 *_eventDatabase;
    dispatch_queue_t _databaseQueue;
}

+ (instancetype)sharedInstanceWithConfig:(CleverTapInstanceConfig *)config {
    static CTEventDatabase *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithConfig:config];
    });
    return sharedInstance;
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    if (self = [super init]) {
        _config = config;
        _databaseQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.clevertap.eventDatabaseQueue:%@", _config.accountId] UTF8String], DISPATCH_QUEUE_CONCURRENT);
        [self openDatabase];
        
        // Perform cleanup/deletion of rows on instance creation if total row count
        // exceeds mac threshold limit.
        NSInteger maxRowLimit = CLTAP_EVENT_DB_MAX_ROW_LIMIT;
        NSInteger numberOfRowsToCleanup = CLTAP_EVENT_DB_ROWS_TO_CLEANUP;
        [self deleteLeastRecentlyUsedRows:maxRowLimit numberOfRowsToCleanup:numberOfRowsToCleanup];
    }
    return self;
}

- (NSString *)databasePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"CleverTap-Events.db"];
}

- (BOOL)openDatabase {
    NSString *databasePath = [self databasePath];
    
    if (sqlite3_open([databasePath UTF8String], &_eventDatabase) == SQLITE_OK) {
        return YES;
    } else {
        CleverTapLogInternal(self.config.logLevel, @"%@ Failed to open database - CleverTap-Events.db", self);
        return NO;
    }
}

- (void)closeDatabase {
    if (_eventDatabase) {
        sqlite3_close(_eventDatabase);
        _eventDatabase = NULL;
    }
}

- (BOOL)createTable {
    __block BOOL success = NO;
    
    dispatch_sync(_databaseQueue, ^{
        char *errMsg;
        const char *createTableSQL = "CREATE TABLE IF NOT EXISTS CTUserEventLogs (eventName TEXT, count INTEGER, firstTs INTEGER, lastTs INTEGER, deviceID TEXT, PRIMARY KEY (eventName, deviceID))";
        if (sqlite3_exec(self->_eventDatabase, createTableSQL, NULL, NULL, &errMsg) == SQLITE_OK) {
            success = YES;
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ Create Table SQL error: %s", self, errMsg);
            sqlite3_free(errMsg);
        }
    });
    
    return success;
}

- (BOOL)insertData:(NSString *)eventName
          deviceID:(NSString *)deviceID {
    BOOL eventExists = [self eventExists:eventName forDeviceID:deviceID];
    if (eventExists) {
        CleverTapLogInternal(self.config.logLevel, @"%@ Insert SQL - Event name: %@ and DeviceID: %@ already exists.", self, eventName, deviceID);
        return NO;
    }
    
    __block BOOL success = NO;
    // For new event, set count as 1
    NSInteger count = 1;
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    
    dispatch_sync(_databaseQueue, ^{
        char *errMsg;
        NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO CTUserEventLogs (eventName, count, firstTs, lastTs, deviceID) VALUES ('%@', %ld, %ld, %ld, '%@')", eventName, (long)count, (long)currentTs, (long)currentTs, deviceID];
        if (sqlite3_exec(_eventDatabase, [insertSQL UTF8String], NULL, NULL, &errMsg) == SQLITE_OK) {
            success = YES;
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ Insert Table SQL error: %s", self, errMsg);
            sqlite3_free(errMsg);
        }
    });
    
    return success;
}

- (BOOL)updateEvent:(NSString *)eventName
        forDeviceID:(NSString *)deviceID {
    BOOL eventExists = [self eventExists:eventName forDeviceID:deviceID];
    if (!eventExists) {
        CleverTapLogInternal(self.config.logLevel, @"%@ Update SQL - Event name: %@ and DeviceID: %@ doesn't exists.", self, eventName, deviceID);
        return NO;
    }
    
    NSInteger currentTs = (NSInteger)[[NSDate date] timeIntervalSince1970];
    NSString *updateSQL = [NSString stringWithFormat:
                               @"UPDATE CTUserEventLogs SET count = count + 1, lastTs = %ld WHERE eventName = '%@' AND deviceID = '%@';",
                               (long)currentTs, eventName, deviceID];
    __block BOOL success = NO;

    dispatch_sync(_databaseQueue, ^{
        char *errMsg;
        int result = sqlite3_exec(_eventDatabase, [updateSQL UTF8String], NULL, NULL, &errMsg);

        if (result == SQLITE_OK) {
            success = YES;
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ Update Table SQL error: %s", self, errMsg);
        }
    });

    return success;
}

- (BOOL)eventExists:(NSString *)eventName 
        forDeviceID:(NSString *)deviceID {
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?"];
    __block BOOL exists = NO;
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_eventDatabase, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                // Check if the count is greater than 0
                int count = sqlite3_column_int(statement, 0);
                if (count > 0) {
                    exists = YES;
                }
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ SQL check query error: %s", self, sqlite3_errmsg(_eventDatabase));
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
    });
    
    return exists;
}

- (void)dealloc {
    dispatch_sync(_databaseQueue, ^{
        [self closeDatabase];
    });
}

- (NSInteger)getCountForEventName:(NSString *)eventName
                         deviceID:(NSString *)deviceID {
    const char *querySQL = "SELECT count FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?;";
    __block NSInteger count = 0;

    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                count = sqlite3_column_int(statement, 0);
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ No event found with eventName: %@ and deviceID: %@", self, eventName, deviceID);
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
    });

    return count;
}

- (NSInteger)getFirstTimestampForEventName:(NSString *)eventName
                                  deviceID:(NSString *)deviceID {
    const char *querySQL = "SELECT firstTs FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?;";
    __block NSInteger firstTs = 0;

    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                firstTs = sqlite3_column_int(statement, 0);
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ No event found with eventName: %@ and deviceID: %@", self, eventName, deviceID);
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
    });

    return firstTs;
}

- (NSInteger)getLastTimestampForEventName:(NSString *)eventName
                                 deviceID:(NSString *)deviceID {
    const char *querySQL = "SELECT lastTs FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?;";
    __block NSInteger lastTs = 0;

    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                lastTs = sqlite3_column_int(statement, 0);
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ No event found with eventName: %@ and deviceID: %@", self, eventName, deviceID);
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
    });

    return lastTs;
}

- (CleverTapEventDetail *)getEventDetailForEventName:(NSString *)eventName
                                           deviceID:(NSString *)deviceID {
    NSString *querySQL = @"SELECT eventName, count, firstTs, lastTs FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?;";
    __block CleverTapEventDetail *eventDetail = nil;
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                const char *eventName = (const char *)sqlite3_column_text(statement, 0);
                NSInteger count = sqlite3_column_int(statement, 1);
                NSInteger firstTs = sqlite3_column_int(statement, 2);
                NSInteger lastTs = sqlite3_column_int(statement, 3);
                
                eventDetail = [[CleverTapEventDetail alloc] init];
                eventDetail.count = count;
                eventDetail.firstTime = firstTs;
                eventDetail.lastTime = lastTs;
                eventDetail.eventName = [NSString stringWithUTF8String:eventName];
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ No event found with eventName: %@ and deviceID: %@", self, eventName, deviceID);
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
    });
    
    return eventDetail;
}

- (NSArray<CleverTapEventDetail *> *)getAllEventsForDeviceID:(NSString *)deviceID {
    NSString *querySQL = @"SELECT eventName, count, firstTs, lastTs FROM CTUserEventLogs WHERE deviceID = ?;";
    __block NSMutableArray *eventDataArray = [NSMutableArray array];
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                const char *eventName = (const char *)sqlite3_column_text(statement, 0);
                NSInteger count = sqlite3_column_int(statement, 1);
                NSInteger firstTs = sqlite3_column_int(statement, 2);
                NSInteger lastTs = sqlite3_column_int(statement, 3);
                
                CleverTapEventDetail *ed = [[CleverTapEventDetail alloc] init];
                ed.count = count;
                ed.firstTime = firstTs;
                ed.lastTime = lastTs;
                ed.eventName = [NSString stringWithUTF8String:eventName];
                
                // Adding the CleverTapEventDetail to the result array
                [eventDataArray addObject:ed];
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
    });
    
    return [eventDataArray copy];
}

- (BOOL)deleteTable {
    NSString *querySQL = [NSString stringWithFormat:@"DROP TABLE IF EXISTS CTUserEventLogs;"];
    __block BOOL success = NO;

    dispatch_sync(_databaseQueue, ^{
        char *errMsg = NULL;
        int result = sqlite3_exec(_eventDatabase, [querySQL UTF8String], NULL, NULL, &errMsg);
        
        if (result == SQLITE_OK) {
            success = YES;
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL Error deleting table CTUserEventLogs: %s", self, errMsg);
            success = NO;
        }
    });

    return success;
}

- (BOOL)deleteLeastRecentlyUsedRows:(NSInteger)maxRowLimit
              numberOfRowsToCleanup:(NSInteger)numberOfRowsToCleanup {
    if (!_eventDatabase) {
        CleverTapLogInternal(self.config.logLevel, @"%@ Event database is not open, cannot execute SQL.", self);
        return NO;
    }
    
    __block BOOL success = NO;
    
    dispatch_sync(_databaseQueue, ^{
        // Begin a transaction to ensure atomicity
        sqlite3_exec(_eventDatabase, "BEGIN TRANSACTION;", NULL, NULL, NULL);
        
        // Create an index on the `lastTs` column if it doesn't exist which will improve performance
        // while deletion when table is large
        const char *createIndexSQL = "CREATE INDEX IF NOT EXISTS idx_lastTs ON CTUserEventLogs(lastTs);";
        char *errMsg = NULL;
        int indexResult = sqlite3_exec(_eventDatabase, createIndexSQL, NULL, NULL, &errMsg);
        
        if (indexResult != SQLITE_OK) {
            CleverTapLogInternal(self.config.logLevel, @"%@ Failed to create index on lastTs: %s", self, errMsg);
            sqlite3_free(errMsg);
            sqlite3_exec(_eventDatabase, "ROLLBACK;", NULL, NULL, NULL);  // Rollback transaction if index creation fails
            return;
        }
        
        NSString *countQuerySQL = @"SELECT COUNT(*) FROM CTUserEventLogs;";
        sqlite3_stmt *countStatement;
        if (sqlite3_prepare_v2(_eventDatabase, [countQuerySQL UTF8String], -1, &countStatement, NULL) == SQLITE_OK) {
            if (sqlite3_step(countStatement) == SQLITE_ROW) {
                NSInteger currentRowCount = sqlite3_column_int(countStatement, 0);
                if (currentRowCount > maxRowLimit) {
                    // Calculate the number of rows to delete
                    NSInteger rowsToDelete = currentRowCount - (maxRowLimit - numberOfRowsToCleanup);
                    
                    // Delete the least recently used rows based on lastTs
                    const char *deleteSQL = "DELETE FROM CTUserEventLogs WHERE (eventName, deviceID) IN (SELECT eventName, deviceID FROM CTUserEventLogs ORDER BY lastTs ASC LIMIT ?);";
                    sqlite3_stmt *deleteStatement;
                    if (sqlite3_prepare_v2(_eventDatabase, deleteSQL, -1, &deleteStatement, NULL) == SQLITE_OK) {
                        sqlite3_bind_int(deleteStatement, 1, (int)rowsToDelete);
                        
                        int result = sqlite3_step(deleteStatement);
                        if (result == SQLITE_DONE) {
                            success = YES;
                        } else {
                            CleverTapLogInternal(self.config.logLevel, @"%@ SQL Error deleting rows: %s", self, sqlite3_errmsg(_eventDatabase));
                        }

                        sqlite3_finalize(deleteStatement);
                    } else {
                        CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
                    }
                }
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ Failed to count rows in CTUserEventLogs", self);
            }
            sqlite3_finalize(countStatement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
        
        // Commit or rollback the transaction based on success
        if (success) {
            sqlite3_exec(_eventDatabase, "COMMIT;", NULL, NULL, NULL);
        } else {
            sqlite3_exec(_eventDatabase, "ROLLBACK;", NULL, NULL, NULL);
        }
    });
    
    return success;
}

@end
