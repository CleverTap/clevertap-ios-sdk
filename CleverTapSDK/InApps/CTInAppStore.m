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
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTAES *ctAES;
@end

@implementation CTInAppStore

@synthesize mode = _mode;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo:(CTDeviceInfo *)deviceInfo
{
    self = [super init];
    if (self) {
        self.config = config;
        self.ctAES = [[CTAES alloc]initWithAccountID:self.config.accountId];
    }
    return self;
}

- (NSString *)mode {
    return _mode;
}

- (void)setMode:(nullable NSString *)mode {
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

- (void)removeClientSideInApps {
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_CS];
    [CTPreferences removeObjectForKey:storageKey];
}

- (void)removeServerSideInApps {
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_SS];
    [CTPreferences removeObjectForKey:storageKey];
}

// TODO: DECIDE ON STORAGE METHODS

// PLAIN TEXT STORAGE
//- (void)storeClientSideInApps:(NSArray *)clientSideInApps {
//    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_CS];
//    [CTPreferences putObject:clientSideInApps forKey:storageKey];
//}
//
//- (void)storeServerSideInApps:(NSArray *)serverSideInApps {
//    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_SS];
//    [CTPreferences putObject:clientSideInApps forKey:storageKey];
//}

//- (NSMutableArray *)clientSideInApps {
//    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_CS];
//    return [[CTPreferences getObjectForKey:storageKey]mutableCopy];
//}
//
//- (NSMutableArray *)serverSideInApps {
//    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_SS];
//    return [[CTPreferences getObjectForKey:storageKey]mutableCopy];
//}

// ENCRYPTION STORAGE
- (void)storeClientSideInApps:(NSArray *)clientSideInApps {
    NSString *encryptedString = [self.ctAES getEncryptedBase64String:clientSideInApps];
    
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_CS];
    [CTPreferences putString:encryptedString forKey:storageKey];
}

- (void)storeServerSideInApps:(NSArray *)serverSideInApps {
    NSString *encryptedString = [self.ctAES getEncryptedBase64String:serverSideInApps];
    
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_SS];
    [CTPreferences putString:encryptedString forKey:storageKey];
}

- (NSMutableArray *)clientSideInApps {
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_CS];
    NSString *encryptedString = [[CTPreferences getObjectForKey:storageKey]mutableCopy];
    return [self.ctAES getDecryptedObject:encryptedString];
}

- (NSMutableArray *)serverSideInApps {
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_SS];
    NSString *encryptedString = [[CTPreferences getObjectForKey:storageKey]mutableCopy];
    return [self.ctAES getDecryptedObject:encryptedString];
}

@end
