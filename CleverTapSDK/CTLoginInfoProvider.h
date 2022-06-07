//
//  CTLoginInfoProvider.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTDeviceInfo.h"
#import "CleverTapInstanceConfig.h"

@interface CTLoginInfoProvider : NSObject

- (void)cacheGUID:(NSString *)guid forKey:(NSString *)key andIdentifier:(NSString *)identifier;
- (BOOL)deviceIsMultiUser;
- (NSDictionary *)getCachedGUIDs;
- (void)setCachedGUIDs:(NSDictionary *)cache;
- (NSString *)getCachedIdentities;
- (NSString *)getGUIDforKey:(NSString *)key andIdentifier:(NSString *)identifier;
- (BOOL)isAnonymousDevice;
- (BOOL)isLegacyProfileLoggedIn;
- (void)setCachedIdentities:(NSString *)cache;
- (instancetype)initWithDeviceInfo:(CTDeviceInfo*)deviceInfo config:(CleverTapInstanceConfig*)config;
- (void)removeValueFromCachedGUIDForKey:(NSString *)key andGuid:(NSString*)guid;

@end
