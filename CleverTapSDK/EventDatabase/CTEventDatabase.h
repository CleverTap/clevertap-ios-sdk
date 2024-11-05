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

@interface CTEventDatabase : NSObject

+ (instancetype)sharedInstanceWithConfig:(CleverTapInstanceConfig *)config;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

- (BOOL)createTable;

- (BOOL)insertData:(NSString *)eventName
          deviceID:(NSString *)deviceID;

- (BOOL)updateEvent:(NSString *)eventName
        forDeviceID:(NSString *)deviceID;

- (BOOL)eventExists:(NSString *)eventName
        forDeviceID:(NSString *)deviceID;

@end
