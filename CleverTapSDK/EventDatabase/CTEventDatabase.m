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

@end
