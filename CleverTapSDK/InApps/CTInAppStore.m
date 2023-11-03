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
#import "CleverTapInstanceConfigPrivate.h"

NSString* const kCLIENT_SIDE_MODE = @"CS";
NSString* const kSERVER_SIDE_MODE = @"SS";

@interface CTInAppStore()

@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) CTAES *ctAES;

@property (nonatomic, strong) NSArray *clientSideInApps;
@property (nonatomic, strong) NSArray *serverSideInApps;

@end

@implementation CTInAppStore

@synthesize mode = _mode;

- (instancetype)initWithAccountId:(NSString *)accountId deviceId:(NSString *)deviceId
{
    self = [super init];
    if (self) {
        self.accountId = accountId;
        self.ctAES = [[CTAES alloc] initWithAccountID:accountId];
        self.deviceId = deviceId;
    }
    return self;
}

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

- (void)removeClientSideInApps {
    @synchronized (self) {
        _clientSideInApps = [NSArray new];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
        [CTPreferences removeObjectForKey:storageKey];
    }
}

- (void)removeServerSideInApps {
    @synchronized (self) {
        _serverSideInApps = [NSArray new];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
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

- (void)storeServerSideInApps:(NSArray *)serverSideInApps {
    if (!serverSideInApps) return;
    
    @synchronized (self) {
        _serverSideInApps = serverSideInApps;
        
        NSString *encryptedString = [self.ctAES getEncryptedBase64String:serverSideInApps];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
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

- (NSArray *)serverSideInApps {
    @synchronized(self) {
        if (_serverSideInApps) return _serverSideInApps;
        
        _serverSideInApps = [self decryptInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS];
        return _serverSideInApps;
    }
}

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
    return [NSString stringWithFormat:@"%@_%@_%@", self.accountId, self.deviceId, suffix];
}

@end
