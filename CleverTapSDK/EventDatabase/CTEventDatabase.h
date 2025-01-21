//
//  CTEventDatabase.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 25/10/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CleverTapEventDetail.h"
#import "CTClock.h"
#import "CTDispatchQueueManager.h"

@interface CTEventDatabase : NSObject

+ (instancetype)sharedInstanceWithDispatchQueueManager:(CTDispatchQueueManager*)dispatchQueueManager;

- (void)databaseVersionWithCompletion:(void (^)(NSInteger version))completion;

- (void)insertEvent:(NSString *)eventName
normalizedEventName:(NSString *)normalizedEventName
           deviceID:(NSString *)deviceID
         completion:(void (^)(BOOL success))completion;

- (void)updateEvent:(NSString *)normalizedEventName
        forDeviceID:(NSString *)deviceID
         completion:(void (^)(BOOL success))completion;

- (void)upsertEvent:(NSString *)eventName
normalizedEventName:(NSString *)normalizedEventName
           deviceID:(NSString *)deviceID;

- (void)eventExists:(NSString *)normalizedEventName
        forDeviceID:(NSString *)deviceID
         completion:(void (^)(BOOL exists))completion;

- (NSInteger)getEventCount:(NSString *)normalizedEventName
                  deviceID:(NSString *)deviceID;

- (CleverTapEventDetail *)getEventDetail:(NSString *)normalizedEventName
                                deviceID:(NSString *)deviceID;

- (NSArray<CleverTapEventDetail *> *)getAllEventsForDeviceID:(NSString *)deviceID;

- (void)deleteAllRowsWithCompletion:(void (^)(BOOL success))completion;

- (void)deleteLeastRecentlyUsedRows:(NSInteger)maxRowLimit
              numberOfRowsToCleanup:(NSInteger)numberOfRowsToCleanup
                         completion:(void (^)(BOOL success))completion;

@end
