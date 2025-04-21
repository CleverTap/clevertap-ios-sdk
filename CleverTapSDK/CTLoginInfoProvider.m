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
#import "CTEncryptionManager.h"

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
    
    // Get current cache
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    NSMutableDictionary *newCache = [NSMutableDictionary dictionaryWithDictionary:cache];
    
    // Check if a GUID already exists for this key and identifier (decrypted)
    NSString *keyPrefix = [NSString stringWithFormat:@"%@_", key];
    BOOL existingEntryFound = NO;
    NSString *existingCacheKey = nil;
    
    if (self.config.cryptManager) {
        for (NSString *cacheKey in cache.allKeys) {
            if ([cacheKey hasPrefix:keyPrefix]) {
                NSString *encryptedIdentifier = [cacheKey substringFromIndex:keyPrefix.length];
                NSString *decryptedIdentifier = encryptedIdentifier;
                @try {
                    
                    if (_config.encryptionLevel == CleverTapEncryptionMedium) {
                        NSString *partiallyDecryptedIdentifier = [self.config.cryptManager decryptString:encryptedIdentifier];
                        
                        decryptedIdentifier = [self.config.cryptManager decryptString:partiallyDecryptedIdentifier];
                    }
                        // If we found a match, update that entry instead of creating a new one
                    if ([decryptedIdentifier isEqualToString:identifier]) {
                        existingEntryFound = YES;
                        existingCacheKey = cacheKey;
                        break;
                    }
                    
                    
                } @catch (NSException *exception) {
                    // Continue to next key if decryption fails
                    continue;
                }
            }
        }
    }
    
    if (existingEntryFound && existingCacheKey) {
        // Update the existing entry
        newCache[existingCacheKey] = guid;
    } else {
        // Create a new entry with the newly encrypted identifier
        NSString *encryptedIdentifier = identifier;
        if (self.config.cryptManager) {
            encryptedIdentifier = [self.config.cryptManager encryptString:identifier];
        }
        NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, encryptedIdentifier];
        newCache[cacheKey] = guid;
    }
    
    [self setCachedGUIDs:newCache];
}

- (BOOL)deviceIsMultiUser {
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    return [cache count] > 1;
}

- (NSDictionary *)getCachedGUIDs {
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:[CTPreferences storageKeyWithSuffix:CLTAP_CachedGUIDSKey config: self.config]];
    if (!cachedGUIDS && self.config.isDefaultInstance) {
        cachedGUIDS = [CTPreferences getObjectForKey:CLTAP_CachedGUIDSKey];
    }
    return cachedGUIDS;
}

- (void)setCachedGUIDs:(NSDictionary *)cache {
    [CTPreferences putObject:cache forKey:[CTPreferences storageKeyWithSuffix:CLTAP_CachedGUIDSKey config: self.config]];
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
    if (!self.config.cryptManager) return nil;
    
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) return nil;
    
    NSString *keyPrefix = [NSString stringWithFormat:@"%@_", key];
    
    // Iterate through all cache keys
    for (NSString *cacheKey in cache.allKeys) {
        // Check if the current key starts with the correct prefix (e.g., "Email_")
        if ([cacheKey hasPrefix:keyPrefix]) {
            // Extract the encrypted part (everything after "Email_")
            NSString *encryptedIdentifier = [cacheKey substringFromIndex:keyPrefix.length];
            NSString *decryptedIdentifier = encryptedIdentifier;
            if (_config.encryptionLevel == CleverTapEncryptionMedium) {
                // Decrypt the encrypted identifier
                NSString *partiallyDecryptedIdentifier = [self.config.cryptManager decryptString:encryptedIdentifier];
                
                decryptedIdentifier = [self.config.cryptManager decryptString:partiallyDecryptedIdentifier];
            }
            // Check if the decrypted identifier matches our input identifier
            if ([decryptedIdentifier isEqualToString:identifier]) {
                return cache[cacheKey];
            }
        }
    }
    
    // No match found
    return nil;
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
