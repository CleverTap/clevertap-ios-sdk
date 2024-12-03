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
    }
    return self;
}

- (BOOL)createTable {
    __block BOOL success = NO;
    
    dispatch_sync(_databaseQueue, ^{
        char *errMsg;
        const char *createTableSQL = "CREATE TABLE IF NOT EXISTS CTUserEventLogs (eventName TEXT, count INTEGER, firstTs INTEGER, lastTs INTEGER, deviceID TEXT, PRIMARY KEY (eventName, deviceID))";
        if (sqlite3_exec(self->_eventDatabase, createTableSQL, NULL, NULL, &errMsg) == SQLITE_OK) {
            success = YES;
            
            // Set the database version to the initial version, ie 1.
            [self setDatabaseVersion:CLTAP_DATABASE_VERSION];
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ Create Table SQL error: %s", self, errMsg);
            sqlite3_free(errMsg);
        }
    });
    
    return success;
}

- (NSInteger)getDatabaseVersion {
    const char *querySQL = "PRAGMA user_version;";
    __block NSInteger version = 0;

    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                version = sqlite3_column_int(statement, 0);
            }
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL prepare query error: %s", self, sqlite3_errmsg(_eventDatabase));
        }
    });

    return version;
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
    const char *insertSQL = "INSERT INTO CTUserEventLogs (eventName, count, firstTs, lastTs, deviceID) VALUES (?, ?, ?, ?, ?)";
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, insertSQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(statement, 2, (int)count);
            sqlite3_bind_int(statement, 3, (int)currentTs);
            sqlite3_bind_int(statement, 4, (int)currentTs);
            sqlite3_bind_text(statement, 5, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            int result = sqlite3_step(statement);
            if (result == SQLITE_DONE) {
                success = YES;
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ Insert Table SQL error: %s", self, sqlite3_errmsg(self->_eventDatabase));
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ Failed to prepare insert statement: %s", self, sqlite3_errmsg(self->_eventDatabase));
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
    const char *updateSQL =
            "UPDATE CTUserEventLogs SET count = count + 1, lastTs = ? WHERE eventName = ? AND deviceID = ?";
    __block BOOL success = NO;

    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, updateSQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, (int)currentTs);
            sqlite3_bind_text(statement, 2, [eventName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [deviceID UTF8String], -1, SQLITE_TRANSIENT);
            
            int result = sqlite3_step(statement);
            if (result == SQLITE_DONE) {
                success = YES;
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@ Update Table SQL error: %s", self, sqlite3_errmsg(self->_eventDatabase));
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ Failed to prepare update statement: %s", self, sqlite3_errmsg(self->_eventDatabase));
        }
    });

    return success;
}

- (BOOL)eventExists:(NSString *)eventName 
        forDeviceID:(NSString *)deviceID {
    const char *query = "SELECT COUNT(*) FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?";
    __block BOOL exists = NO;
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_eventDatabase, query, -1, &statement, NULL) == SQLITE_OK) {
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
    const char *querySQL = "SELECT count FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?";
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
    const char *querySQL = "SELECT firstTs FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?";
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
    const char *querySQL = "SELECT lastTs FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?";
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
    const char *querySQL = "SELECT eventName, count, firstTs, lastTs FROM CTUserEventLogs WHERE eventName = ? AND deviceID = ?";
    __block CleverTapEventDetail *eventDetail = nil;
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
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
    const char *querySQL = "SELECT eventName, count, firstTs, lastTs FROM CTUserEventLogs WHERE deviceID = ?";
    __block NSMutableArray *eventDataArray = [NSMutableArray array];
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_eventDatabase, querySQL, -1, &statement, NULL) == SQLITE_OK) {
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
    const char *querySQL = "DROP TABLE IF EXISTS CTUserEventLogs";
    __block BOOL success = NO;

    dispatch_sync(_databaseQueue, ^{
        char *errMsg = NULL;
        int result = sqlite3_exec(_eventDatabase, querySQL, NULL, NULL, &errMsg);
        
        if (result == SQLITE_OK) {
            success = YES;
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ SQL Error deleting table CTUserEventLogs: %s", self, errMsg);
            success = NO;
        }
    });

    return success;
}

#pragma mark - Private methods

- (BOOL)openDatabase {
    NSString *databasePath = [self databasePath];
    
    if (![self isDatabaseFileExists]) {
        // If the database file does not exist, create the schema for the first time
        if (![self createTable]) {
            CleverTapLogInternal(self.config.logLevel, @"%@ Failed to create database schema for the first time", self);
            return NO;
        }
    }
    
    if (sqlite3_open([databasePath UTF8String], &_eventDatabase) == SQLITE_OK) {
        // After opening, check and update the version if needed
        [self checkAndUpdateDatabaseVersion];
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

- (void)setDatabaseVersion:(NSInteger)version {
    const char *updateSQL = "PRAGMA user_version = ?";
    
    dispatch_sync(_databaseQueue, ^{
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_eventDatabase, updateSQL, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_int(statement, 1, (int)version);
            
            int result = sqlite3_step(statement);
            if (result != SQLITE_OK) {
                CleverTapLogInternal(self.config.logLevel, @"%@ SQL Error: %s", self, sqlite3_errmsg(self->_eventDatabase));
            }
            
            sqlite3_finalize(statement);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@ Failed to prepare update statement: %s", self, sqlite3_errmsg(self->_eventDatabase));
        }
   });
}

- (void)checkAndUpdateDatabaseVersion {
    NSInteger currentVersion = [self getDatabaseVersion];
    
    if (currentVersion < CLTAP_DATABASE_VERSION) {
        // Handle version changes here in future.
        [self setDatabaseVersion:CLTAP_DATABASE_VERSION];
        CleverTapLogInternal(self.config.logLevel, @"%@ Schema migration required. Current version: %ld, Target version: %ld", self, (long)currentVersion, (long)CLTAP_DATABASE_VERSION);
    }
}

- (NSString *)databasePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"CleverTap-Events.db"];
}

- (BOOL)isDatabaseFileExists {
    NSString *databasePath = [self databasePath];
    return [[NSFileManager defaultManager] fileExistsAtPath:databasePath];
}

@end
