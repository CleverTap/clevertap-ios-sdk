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
    
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    NSMutableDictionary *newCache = [NSMutableDictionary dictionaryWithDictionary:cache];
    
    NSString *keyPrefix = [NSString stringWithFormat:@"%@_", key];
    BOOL existingEntryFound = NO;
    NSString *existingCacheKey = nil;
    
    if (self.config.cryptManager) {
        for (NSString *cacheKey in cache.allKeys) {
            if ([cacheKey hasPrefix:keyPrefix]) {
                NSString *encryptedIdentifier = [cacheKey substringFromIndex:keyPrefix.length];
                NSString *decryptedIdentifier = encryptedIdentifier;
                
                if (_config.encryptionLevel == CleverTapEncryptionMedium || _config.encryptionLevel == CleverTapEncryptionHigh) {
                    
                    NSInteger maxIterations = 10;
                    NSInteger iterations = 0;
                    
                    while (iterations < maxIterations) {
                        NSString *attempt = [self.config.cryptManager decryptString:encryptedIdentifier];
                        if (!attempt) break;
                        
                        decryptedIdentifier = attempt;
                        iterations++;
                        
                        BOOL stillEncrypted = [decryptedIdentifier hasPrefix:AES_GCM_PREFIX] &&
                                              [decryptedIdentifier hasSuffix:AES_GCM_SUFFIX];
                        if (!stillEncrypted) break;
                        
                        encryptedIdentifier = decryptedIdentifier;
                    }
                }
                
                if ([decryptedIdentifier isEqualToString:identifier]) {
                    existingEntryFound = YES;
                    existingCacheKey = cacheKey;
                    break;
                }
            }
        }
    }
    
    if (existingEntryFound && existingCacheKey) {
        // Update the existing entry, preserving its existing (possibly multi-layered)
        // cache key as-is. The key's encryption state is whatever updateCachedGUIDS
        // left it in — we only update the GUID value, not the key.
        newCache[existingCacheKey] = guid;
    } else {
        // New entry: always write with a single encryptString at the current level.
        // updateCachedGUIDS owns the responsibility of re-keying on level transitions,
        // not this method.
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
    
    for (NSString *cacheKey in cache.allKeys) {
        if ([cacheKey hasPrefix:keyPrefix]) {
            NSString *encryptedIdentifier = [cacheKey substringFromIndex:keyPrefix.length];
            NSString *decryptedIdentifier = encryptedIdentifier;
            
            if (_config.encryptionLevel == CleverTapEncryptionMedium ||
                _config.encryptionLevel == CleverTapEncryptionHigh) {
                
                // Max iterations guard: copyWithZone double-trigger gives 2 layers normally,
                // and the worst-case 1→2 corruption gives 3. Cap at 10 to be safe without
                // risking an infinite loop on any unexpected data.
                NSInteger maxIterations = 10;
                NSInteger iterations = 0;
                
                while (iterations < maxIterations) {
                    NSString *attempt = [self.config.cryptManager decryptString:encryptedIdentifier];
                    
                    // Nil guard: decryptString failed (wrong key, corrupted data, or
                    // already plaintext that isn't AES-GCM wrapped). Stop here and use
                    // whatever we have so far.
                    if (!attempt) break;
                    
                    decryptedIdentifier = attempt;
                    iterations++;
                    
                    // Exit when the result is no longer AES-GCM wrapped.
                    // For old AES-CBC entries (iOS < 13) this exits after the first
                    // successful decrypt since they carry no <ct< >ct> framing.
                    BOOL stillEncrypted = [decryptedIdentifier hasPrefix:AES_GCM_PREFIX] &&
                                          [decryptedIdentifier hasSuffix:AES_GCM_SUFFIX];
                    if (!stillEncrypted) break;
                    
                    encryptedIdentifier = decryptedIdentifier;
                }
            }
            
            if ([decryptedIdentifier isEqualToString:identifier]) {
                return cache[cacheKey];
            }
        }
    }
    
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
