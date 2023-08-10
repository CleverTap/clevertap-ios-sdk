//
//  CTLoginInfoProvider.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "CTLoginInfoProvider.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTAES.h"

NSString *const kCachedGUIDS = @"CachedGUIDS";
NSString *const kCachedIdentities = @"CachedIdentities";

@interface CTLoginInfoProvider () {}
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@end

@implementation CTLoginInfoProvider

- (instancetype)initWithDeviceInfo:(CTDeviceInfo*)deviceInfo config:(CleverTapInstanceConfig*)config {
    if (self = [super init]) {
        self.deviceInfo = deviceInfo;
        self.config = config;
    }
    return self;
}

- (void)cacheGUID:(NSString *)guid forKey:(NSString *)key andIdentifier:(NSString *)identifier {
    if (!guid) guid = self.deviceInfo.deviceId;
    if (!guid || [self.deviceInfo isErrorDeviceID] || !key || !identifier) return;
    
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    NSMutableDictionary *newCache = [NSMutableDictionary dictionaryWithDictionary:cache];

    NSString *encryptedIdentifier = identifier;
    if (self.config.aesCrypt) {
        encryptedIdentifier = [self.config.aesCrypt getEncryptedString:identifier];
    }
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, encryptedIdentifier];
    newCache[cacheKey] = guid;
    [self setCachedGUIDs:newCache];
}

- (BOOL)deviceIsMultiUser {
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    return [cache count] > 1;
}

- (NSDictionary *)getCachedGUIDs {
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:[CTPreferences storageKeyWithSuffix:kCachedGUIDS config: self.config]];
    if (!cachedGUIDS && self.config.isDefaultInstance) {
        cachedGUIDS = [CTPreferences getObjectForKey:kCachedGUIDS];
    }
    return cachedGUIDS;
}

- (void)setCachedGUIDs:(NSDictionary *)cache {
    [CTPreferences putObject:cache forKey:[CTPreferences storageKeyWithSuffix:kCachedGUIDS config: self.config]];
}

- (NSString *)getCachedIdentities {
    NSString *cachedIdentities = [CTPreferences getObjectForKey:[CTPreferences storageKeyWithSuffix:kCachedIdentities config: self.config]];
    if (!cachedIdentities && self.config.isDefaultInstance) {
        cachedIdentities = [CTPreferences getObjectForKey:kCachedIdentities];
    }
    return cachedIdentities;
}

- (NSString *)getGUIDforKey:(NSString *)key andIdentifier:(NSString *)identifier {
    if (!key || !identifier) return nil;
    
    NSDictionary *cache = [self getCachedGUIDs];
    NSString *encryptedIdentifier = identifier;
    if (self.config.aesCrypt) {
        encryptedIdentifier = [self.config.aesCrypt getEncryptedString:identifier];
    }
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, encryptedIdentifier];
    if (!cache) return nil;
    else return cache[cacheKey];
}

- (BOOL)isAnonymousDevice {
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    return [cache count] <= 0;
}

- (BOOL)isLegacyProfileLoggedIn {
    // CHECK IF ITS A LEGACY USER
    NSDictionary *cachedGUIDs = [self getCachedGUIDs];
    NSString *cachedIdentities = [self getCachedIdentities];
    
    if (cachedGUIDs && cachedGUIDs.count > 0 && (!cachedIdentities || cachedIdentities.length == 0)) {
        // LEGACY USER FOUND
        return YES;
    }
    return NO;
}

- (void)setCachedIdentities:(NSString *)cache {
    [CTPreferences putObject:cache forKey:[CTPreferences storageKeyWithSuffix:kCachedIdentities config: self.config]];
}

- (void)removeValueFromCachedGUIDForKey:(NSString *)key andGuid:(NSString*)guid {
    
    NSMutableDictionary *cachedGUIDs = [[self getCachedGUIDs]mutableCopy];
    if (!cachedGUIDs || cachedGUIDs.count == 0) return;
    
    [cachedGUIDs enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull cachedKey, NSString*  _Nonnull value, BOOL * _Nonnull stop) {
        if ([cachedKey containsString:key] && [value isEqualToString:guid]) {
            [cachedGUIDs removeObjectForKey:cachedKey];
            [self setCachedGUIDs:cachedGUIDs];
            *stop = YES;
        }
    }];
}
@end
