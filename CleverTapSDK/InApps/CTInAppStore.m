//
//  CTInAppStore.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTInAppStore.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CTEncryptionManager.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTMultiDelegateManager.h"

NSString* const kCLIENT_SIDE_MODE = @"CS";
NSString* const kSERVER_SIDE_MODE = @"SS";

@interface CTInAppStore()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) CTEncryptionManager *cryptManager;

@property (nonatomic, strong) NSArray *inAppsQueue;
@property (nonatomic, strong) NSArray *clientSideInApps;
@property (nonatomic, strong) NSArray *serverSideInApps;
@property (nonatomic, strong) NSArray *delayedInAppsQueue;
@property (nonatomic, strong) NSArray *delayedClientSideInApps;
@property (nonatomic, strong) NSArray *delayedServerSideInApps;

@end

@implementation CTInAppStore

@synthesize mode = _mode;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId {
    self = [super init];
    if (self) {
        self.config = config;
        self.accountId = config.accountId;
        self.deviceId = deviceId;
        self.cryptManager = [[CTEncryptionManager alloc] initWithAccountID:config.accountId];
        
        [delegateManager addSwitchUserDelegate:self];
        [self migrateInAppQueueKeys];
        [self migrateDelayedInAppQueueKeys];
    }
    return self;
}

#pragma mark In-App Notifs Queue
- (void)migrateInAppQueueKeys {
    @synchronized(self) {
        NSString *storageKey = [CTPreferences storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY config: self.config];
        id data = [CTPreferences getObjectForKey:storageKey];
        if (data) {
            if ([data isKindOfClass:[NSArray class]]) {
                _inAppsQueue = data;
                
                NSString *encryptedString = nil;
                @try {
                    encryptedString = [self.cryptManager encryptObject:data];
                    if (!encryptedString) {
                        CleverTapLogInternal(self.config.logLevel, @"%@: Encryption failed", self);
                        return;
                    }
                } @catch (NSException *exception) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Encryption error: %@", self, exception);
                    return;
                }
                
                NSString *newStorageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY];
                [CTPreferences putString:encryptedString forKey:newStorageKey];
            }
            [CTPreferences removeObjectForKey:storageKey];
        }
    }
}

- (void)clearInApps {
    @synchronized (self) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Clearing all pending InApp notifications", self);
        _inAppsQueue = [NSArray new];
        _delayedInAppsQueue = [NSArray new];
        //immediate inapps
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY];
        [CTPreferences removeObjectForKey:storageKey];
        //delayed inapps
        NSString *delayedStorageKey = [self storageKeyWithSuffix:CLTAP_PREFS_DELAYED_INAPP_KEY];
        [CTPreferences removeObjectForKey:delayedStorageKey];
    }
}

- (void)storeInApps:(NSArray *)inApps {
    if (!inApps) return;
    
    @synchronized (self) {
        _inAppsQueue = inApps;
        
        NSString *encryptedString = [self.cryptManager encryptObject:inApps];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)inAppsQueue {
    @synchronized(self) {
        if (_inAppsQueue) return _inAppsQueue;
        
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY];
        id data = [CTPreferences getObjectForKey:storageKey];
        
        if ([data isKindOfClass:[NSString class]]) {
            @try {
                if (!self.cryptManager) {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Cannot decrypt inApps queue - cryptManager is nil", self);
                    _inAppsQueue = [NSArray new];
                    return _inAppsQueue;
                }
                
                NSArray *arr = [self.cryptManager decryptObject:data];
                if (arr) {
                    if ([arr isKindOfClass:[NSArray class]]) {
                        _inAppsQueue = arr;
                    } else {
                        CleverTapLogDebug(self.config.logLevel, @"%@: Decrypted inApps queue is not an NSArray type: %@", self, [arr class]);
                        _inAppsQueue = [NSArray new];
                    }
                } else {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Failed to decrypt inApps queue", self);
                    _inAppsQueue = [NSArray new];
                }
            } @catch (NSException *exception) {
                CleverTapLogDebug(self.config.logLevel, @"%@: Exception during inApps queue decryption: %@", self, exception);
                _inAppsQueue = [NSArray new];
            }
        } else if (data) {
            // Log if data exists but is not a string (unexpected type)
            CleverTapLogDebug(self.config.logLevel, @"%@: Found inApps queue data of unexpected type: %@", self, [data class]);
            _inAppsQueue = [NSArray new];
        }
        
        if (!_inAppsQueue) {
            _inAppsQueue = [NSArray new];
        }

        return _inAppsQueue;
    }
}

- (void)enqueueInApps:(NSArray *)inAppNotifs {
    if (!inAppNotifs) return;
    
    @synchronized(self) {
        NSMutableArray *inAppsQueue = [[NSMutableArray alloc] initWithArray:[self inAppsQueue]];
        NSMutableArray *delayedInAppsQueue = [[NSMutableArray alloc] initWithArray:[self delayedInAppsQueue]];
        
        NSDictionary<NSString *, NSArray *> *partitionedNotifs = [self partitionInApps:inAppNotifs];
        [inAppsQueue addObjectsFromArray:partitionedNotifs[@"immediate"]];
        [delayedInAppsQueue addObjectsFromArray:partitionedNotifs[@"delayed"]];
        
        // Commit all the changes
        [self storeInApps:inAppsQueue];
        [self storeDelayedInApps:delayedInAppsQueue];
    }
}

- (void)insertInFrontInApp:(NSDictionary *)inAppNotif {
    if (!inAppNotif) return;
    
    @synchronized(self) {
        NSMutableArray *inAppsQueue = [[NSMutableArray alloc] initWithArray:[self inAppsQueue]];
        NSMutableArray *delayedInAppsQueue = [[NSMutableArray alloc] initWithArray:[self delayedInAppsQueue]];
        
        if ([self parseDelayFromJson: inAppNotif] == 0) {
            [inAppsQueue insertObject:inAppNotif atIndex:0];
        } else {
            [delayedInAppsQueue insertObject:inAppNotif atIndex:0];
        }
        [self storeInApps:inAppsQueue];
        [self storeDelayedInApps:delayedInAppsQueue];
    }
}

- (NSDictionary *)peekInApp {
    @synchronized(self) {
        NSArray *inApps = [self inAppsQueue];
        if ([inApps count] > 0) {
            return inApps[0];
        }
        return nil;
    }
}

- (NSDictionary *)dequeueInApp {
    @synchronized(self) {
        NSMutableArray *inAppsQueue = [[NSMutableArray alloc] initWithArray:[self inAppsQueue]];
        NSDictionary *inApp = nil;
        if ([inAppsQueue count] > 0) {
            inApp = inAppsQueue[0];
            [inAppsQueue removeObjectAtIndex:0];
            [self storeInApps:inAppsQueue];
        }
        return inApp;
    }
}

#pragma mark Delayed InApps

- (void)migrateDelayedInAppQueueKeys {
    @synchronized(self) {
        NSString *storageKey = [CTPreferences storageKeyWithSuffix:CLTAP_PREFS_DELAYED_INAPP_KEY config: self.config];
        id data = [CTPreferences getObjectForKey:storageKey];
        if (data) {
            if ([data isKindOfClass:[NSArray class]]) {
                _delayedInAppsQueue = data;
                
                NSString *encryptedString = nil;
                @try {
                    encryptedString = [self.cryptManager encryptObject:data];
                    if (!encryptedString) {
                        CleverTapLogInternal(self.config.logLevel, @"%@: Encryption failed", self);
                        return;
                    }
                } @catch (NSException *exception) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Encryption error: %@", self, exception);
                    return;
                }
                
                NSString *newStorageKey = [self storageKeyWithSuffix:CLTAP_PREFS_DELAYED_INAPP_KEY];
                [CTPreferences putString:encryptedString forKey:newStorageKey];
            }
            [CTPreferences removeObjectForKey:storageKey];
        }
    }
}

- (void)storeDelayedInApps:(NSArray *)inApps {
    if (!inApps) return;
    
    @synchronized (self) {
        _delayedInAppsQueue = inApps;
        
        NSString *encryptedString = [self.cryptManager encryptObject:inApps];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_DELAYED_INAPP_KEY];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)delayedInAppsQueue {
    @synchronized(self) {
        if (_delayedInAppsQueue) return _delayedInAppsQueue;
        
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_DELAYED_INAPP_KEY];
        id data = [CTPreferences getObjectForKey:storageKey];
        
        if ([data isKindOfClass:[NSString class]]) {
            @try {
                if (!self.cryptManager) {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Cannot decrypt inApps queue - cryptManager is nil", self);
                    _delayedInAppsQueue = [NSArray new];
                    return _delayedInAppsQueue;
                }
                
                NSArray *arr = [self.cryptManager decryptObject:data];
                if (arr) {
                    if ([arr isKindOfClass:[NSArray class]]) {
                        _delayedInAppsQueue = arr;
                    } else {
                        CleverTapLogDebug(self.config.logLevel, @"%@: Decrypted inApps queue is not an NSArray type: %@", self, [arr class]);
                        _delayedInAppsQueue = [NSArray new];
                    }
                } else {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Failed to decrypt inApps queue", self);
                    _delayedInAppsQueue = [NSArray new];
                }
            } @catch (NSException *exception) {
                CleverTapLogDebug(self.config.logLevel, @"%@: Exception during inApps queue decryption: %@", self, exception);
                _delayedInAppsQueue = [NSArray new];
            }
        } else if (data) {
            // Log if data exists but is not a string (unexpected type)
            CleverTapLogDebug(self.config.logLevel, @"%@: Found inApps queue data of unexpected type: %@", self, [data class]);
            _delayedInAppsQueue = [NSArray new];
        }
        
        if (!_delayedInAppsQueue) {
            _delayedInAppsQueue = [NSArray new];
        }
        
        return _delayedInAppsQueue;
    }
}

- (NSDictionary *)peekDelayedInApp {
    @synchronized(self) {
        NSArray *inApps = [self delayedInAppsQueue];
        if ([inApps count] > 0) {
            return inApps[0];
        }
        return nil;
    }
}

- (NSDictionary *)dequeueDelayedInApp:(NSDictionary *)inAppNotif {
    @synchronized(self) {
        NSMutableArray *delayedInAppsQueue = [[NSMutableArray alloc] initWithArray:[self delayedInAppsQueue]];
        
        NSDictionary *inApp = nil;
        
        if ([delayedInAppsQueue count] > 0) {
            inApp = delayedInAppsQueue[0];
            [delayedInAppsQueue removeObjectAtIndex:0];
            [self storeDelayedInApps:delayedInAppsQueue];
        }
        return inApp;
    }
}

#pragma mark In-App Mode
- (NSString *)mode {
    @synchronized (self) {
        return _mode;
    }
}

- (void)setMode:(nullable NSString *)mode {
    @synchronized (self) {
        if ([_mode isEqualToString:mode]) return;
        _mode = mode;
        
        if ([mode isEqualToString:kCLIENT_SIDE_MODE]) {
            [self removeServerSideInApps];
        } else if ([mode isEqualToString:kSERVER_SIDE_MODE]) {
            [self removeClientSideInApps];
        } else {
            [self removeServerSideInApps];
            [self removeClientSideInApps];
        }
    }
}


#pragma mark Client-Side In-Apps
- (void)removeClientSideInApps {
    @synchronized (self) {
        _clientSideInApps = [NSArray new];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
        [CTPreferences removeObjectForKey:storageKey];
        
        NSString *delayedStorageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_DELAYED_KEY_CS];
        [CTPreferences removeObjectForKey:delayedStorageKey];
    }
}

- (void)partitionClientSideInApps:(NSArray *)clientSideInApps {
    NSDictionary<NSString *, NSArray *> *partitionedNotifs = [self partitionInApps:clientSideInApps];
    
    [self storeClientSideInApps:partitionedNotifs[@"immediate"]];
    [self storeDelayedClientSideInApps:partitionedNotifs[@"delayed"]];
}

- (void)storeClientSideInApps:(NSArray *)clientSideInApps {
    if (!clientSideInApps) return;
    
    @synchronized (self) {
        _clientSideInApps = clientSideInApps;
        
        NSString *encryptedString = nil;
        @try {
            encryptedString = [self.cryptManager encryptObject:clientSideInApps];
            if (!encryptedString) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Encryption failed for client side InApps", self);
                return;
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Encryption error for client side InApps: %@", self, exception);
            return;
        }
        
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)clientSideInApps {
    @synchronized(self) {
        if (_clientSideInApps) return _clientSideInApps;
        
        @try {
            _clientSideInApps = [self decryptInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_CS];
            if (!_clientSideInApps) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Failed to retrieve client side InApps", self);
                _clientSideInApps = [NSArray new];
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Error retrieving client side InApps: %@", self, exception);
            _clientSideInApps = [NSArray new];
        }
        
        return _clientSideInApps;
    }
}

- (void)storeDelayedClientSideInApps:(NSArray *)clientSideInApps {
    if (!clientSideInApps) return;
    
    @synchronized (self) {
        _delayedClientSideInApps = clientSideInApps;
        
        NSString *encryptedString = nil;
        @try {
            encryptedString = [self.cryptManager encryptObject:clientSideInApps];
            if (!encryptedString) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Encryption failed for delayed client side InApps", self);
                return;
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Encryption error for delayed client side InApps: %@", self, exception);
            return;
        }
        
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_DELAYED_KEY_CS];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)delayedClientSideInApps {
    @synchronized(self) {
        if (_delayedClientSideInApps) return _delayedClientSideInApps;
        
        @try {
            _delayedClientSideInApps = [self decryptInAppsWithKeySuffix:CLTAP_PREFS_INAPP_DELAYED_KEY_CS];
            if (!_delayedClientSideInApps) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Failed to retrieve delayed client side InApps", self);
                _delayedClientSideInApps = [NSArray new];
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Error retrieving delayed client side InApps: %@", self, exception);
            _delayedClientSideInApps = [NSArray new];
        }
        return _delayedClientSideInApps;
    }
}

#pragma mark Server-Side In-Apps

- (void)partitionServerSideInApps:(NSArray *)serverSideInApps {
    NSDictionary<NSString *, NSArray *> *partitionedNotifs = [self partitionInApps:serverSideInApps];
    
    [self storeServerSideInApps:partitionedNotifs[@"immediate"]];
    [self storeDelayedServerSideInApps:partitionedNotifs[@"delayed"]];
}

- (void)removeServerSideInApps {
    @synchronized (self) {
        _serverSideInApps = [NSArray new];
        _delayedServerSideInApps = [NSArray new];
        
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
        [CTPreferences removeObjectForKey:storageKey];
        
        NSString *delayedStorageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_DELAYED_KEY_SS];
        [CTPreferences removeObjectForKey:delayedStorageKey];
    }
}

- (void)storeServerSideInApps:(NSArray *)serverSideInApps {
    if (!serverSideInApps) return;
    
    @synchronized (self) {
        _serverSideInApps = serverSideInApps;
        
        NSString *encryptedString = nil;
        @try {
            encryptedString = [self.cryptManager encryptObject:serverSideInApps];
            if (!encryptedString) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Encryption failed for server side InApps", self);
                return;
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Encryption error for server side InApps: %@", self, exception);
            return;
        }
        
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)serverSideInApps {
    @synchronized(self) {
        if (_serverSideInApps) return _serverSideInApps;
        
        @try {
            _serverSideInApps = [self decryptInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS];
            if (!_serverSideInApps) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Failed to retrieve server side InApps", self);
                _serverSideInApps = [NSArray new];
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Error retrieving server side InApps: %@", self, exception);
            _serverSideInApps = [NSArray new];
        }
        
        return _serverSideInApps;
    }
}

- (void)storeDelayedServerSideInApps:(NSArray *)serverSideInApps {
    if (!serverSideInApps) return;
    
    @synchronized (self) {
        _delayedServerSideInApps = serverSideInApps;
        
        NSString *encryptedString = nil;
        @try {
            encryptedString = [self.cryptManager encryptObject:serverSideInApps];
            if (!encryptedString) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Encryption failed for delayed server side InApps", self);
                return;
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Encryption error for delayed server side InApps: %@", self, exception);
            return;
        }
        
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_DELAYED_KEY_SS];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)delayedServerSideInApps {
    @synchronized(self) {
        if (_delayedServerSideInApps) return _delayedServerSideInApps;
        
        @try {
            _delayedServerSideInApps = [self decryptInAppsWithKeySuffix:CLTAP_PREFS_INAPP_DELAYED_KEY_SS];
            if (!_delayedServerSideInApps) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Failed to retrieve delayed server side InApps", self);
                _delayedServerSideInApps = [NSArray new];
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Error retrieving delayed server side InApps: %@", self, exception);
            _delayedServerSideInApps = [NSArray new];
        }
        
        return _delayedServerSideInApps;
    }
}

#pragma mark Utils

- (NSDictionary<NSString *, NSArray *> *)partitionInApps:(NSArray *)inAppNotifs {
    NSMutableArray *immediate = [NSMutableArray array];
    NSMutableArray *delayed = [NSMutableArray array];
    
    for (int i = 0; i < [inAppNotifs count]; i++) {
        @try {
            NSMutableDictionary *inAppNotif = [[NSMutableDictionary alloc] initWithDictionary:inAppNotifs[i]];
            if ([self parseDelayFromJson: inAppNotif] == 0) {
                [immediate addObject:inAppNotif];
            } else {
                [delayed addObject:inAppNotif];
            }
            
        } @catch (NSException *e) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Malformed InApp notification", self);
        }
    }
    return @{
        @"immediate": [immediate copy],
        @"delayed": [delayed copy]
    };
}

- (NSInteger)parseDelayFromJson:(NSDictionary *)inAppNotif {
    NSNumber *delayValue = inAppNotif[CLTAP_DELAY_AFTER_TRIGGER];
    if (!delayValue) return 0;
    
    NSInteger delay = [delayValue integerValue];
    if (delay < 1 || delay > 1000) {
        return 0; // immediate
    }
    return delay;
}

- (NSArray *)decryptInAppsWithKeySuffix:(NSString *)keySuffix {
    NSString *key = [self storageKeyWithSuffix:keySuffix];
    NSString *encryptedString = [CTPreferences getObjectForKey:key];
    
    if (encryptedString) {
        NSArray *arr = nil;
        @try {
            arr = [self.cryptManager decryptObject:encryptedString];
            if (!arr) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Decryption failed", self);
                return [NSArray new];
            }
        } @catch (NSException *exception) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Decryption error: %@", self, exception);
            return [NSArray new];
        }
        
        return arr;
    }
    
    return [NSArray new];
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.accountId, self.deviceId, suffix];
}

#pragma mark CTSwitchUserDelegate
- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceId = newDeviceId;
    // Set to nil to reload from cache
    self.inAppsQueue = nil;
    self.clientSideInApps = nil;
    self.serverSideInApps = nil;
    
    self.delayedInAppsQueue = nil;
    self.delayedClientSideInApps = nil;
    self.delayedServerSideInApps = nil;
}

@end
