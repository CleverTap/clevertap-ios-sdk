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
#import "CTAES.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTMultiDelegateManager.h"

NSString* const kCLIENT_SIDE_MODE = @"CS";
NSString* const kSERVER_SIDE_MODE = @"SS";

@interface CTInAppStore()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) CTAES *ctAES;

@property (nonatomic, strong) NSArray *inAppsQueue;
@property (nonatomic, strong) NSArray *clientSideInApps;
@property (nonatomic, strong) NSArray *serverSideInApps;

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
        self.ctAES = [[CTAES alloc] initWithAccountID:config.accountId];
        
        [delegateManager addSwitchUserDelegate:self];
        [self migrateInAppQueueKeys];
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
                NSString *encryptedString = [self.ctAES getEncryptedBase64String:data];
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
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY];
        [CTPreferences removeObjectForKey:storageKey];
    }
}

- (void)storeInApps:(NSArray *)inApps {
    if (!inApps) return;
    
    @synchronized (self) {
        _inAppsQueue = inApps;
        
        NSString *encryptedString = [self.ctAES getEncryptedBase64String:inApps];
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
            NSArray *arr = [self.ctAES getDecryptedObject:data];
            if (arr) {
                _inAppsQueue = arr;
            }
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
        for (int i = 0; i < [inAppNotifs count]; i++) {
            @try {
                NSMutableDictionary *inAppNotif = [[NSMutableDictionary alloc] initWithDictionary:inAppNotifs[i]];
                [inAppsQueue addObject:inAppNotif];
            } @catch (NSException *e) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Malformed InApp notification", self);
            }
        }
        // Commit all the changes
        [self storeInApps:inAppsQueue];
    }
}

- (void)insertInFrontInApp:(NSDictionary *)inAppNotif {
    if (!inAppNotif) return;
    
    @synchronized(self) {
        NSMutableArray *inAppsQueue = [[NSMutableArray alloc] initWithArray:[self inAppsQueue]];
        [inAppsQueue insertObject:inAppNotif atIndex:0];
        [self storeInApps:inAppsQueue];
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
    }
}

- (void)storeClientSideInApps:(NSArray *)clientSideInApps {
    if (!clientSideInApps) return;
    
    @synchronized (self) {
        _clientSideInApps = clientSideInApps;
        
        NSString *encryptedString = [self.ctAES getEncryptedBase64String:clientSideInApps];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)clientSideInApps {
    @synchronized(self) {
        if (_clientSideInApps) return _clientSideInApps;
        
        _clientSideInApps = [self decryptInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_CS];
        return _clientSideInApps;
    }
}

#pragma mark Server-Side In-Apps
- (void)removeServerSideInApps {
    @synchronized (self) {
        _serverSideInApps = [NSArray new];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
        [CTPreferences removeObjectForKey:storageKey];
    }
}

- (void)storeServerSideInApps:(NSArray *)serverSideInApps {
    if (!serverSideInApps) return;
    
    @synchronized (self) {
        _serverSideInApps = serverSideInApps;
        
        NSString *encryptedString = [self.ctAES getEncryptedBase64String:serverSideInApps];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
        [CTPreferences putString:encryptedString forKey:storageKey];
    }
}

- (NSArray *)serverSideInApps {
    @synchronized(self) {
        if (_serverSideInApps) return _serverSideInApps;
        
        _serverSideInApps = [self decryptInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS];
        return _serverSideInApps;
    }
}

#pragma mark Utils
- (NSArray *)decryptInAppsWithKeySuffix:(NSString *)keySuffix {
    NSString *key = [self storageKeyWithSuffix:keySuffix];
    NSString *encryptedString = [CTPreferences getObjectForKey:key];
    if (encryptedString) {
        NSArray *arr = [self.ctAES getDecryptedObject:encryptedString];
        if (arr) {
            return arr;
        }
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
}

@end
