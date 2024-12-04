//
//  CTEventDatabase.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 25/10/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CleverTapInstanceConfig.h"
#import "CleverTapEventDetail.h"

@interface CTEventDatabase : NSObject

+ (instancetype)sharedInstanceWithConfig:(CleverTapInstanceConfig *)config;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

- (BOOL)createTable;

- (NSInteger)getDatabaseVersion;

- (BOOL)insertData:(NSString *)eventName
          deviceID:(NSString *)deviceID;

- (BOOL)updateEvent:(NSString *)eventName
        forDeviceID:(NSString *)deviceID;

- (BOOL)eventExists:(NSString *)eventName
        forDeviceID:(NSString *)deviceID;

- (NSInteger)getCountForEventName:(NSString *)eventName
                         deviceID:(NSString *)deviceID;

- (NSInteger)getFirstTimestampForEventName:(NSString *)eventName
                                  deviceID:(NSString *)deviceID;

- (NSInteger)getLastTimestampForEventName:(NSString *)eventName
                                 deviceID:(NSString *)deviceID;

- (CleverTapEventDetail *)getEventDetailForEventName:(NSString *)eventName
                                            deviceID:(NSString *)deviceID;

- (NSArray<CleverTapEventDetail *> *)getAllEventsForDeviceID:(NSString *)deviceID;

- (BOOL)deleteTable;

- (BOOL)deleteLeastRecentlyUsedRows:(NSInteger)maxRowLimit
              numberOfRowsToCleanup:(NSInteger)numberOfRowsToCleanup;

@end
