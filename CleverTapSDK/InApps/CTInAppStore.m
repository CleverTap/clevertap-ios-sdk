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
#import "CleverTapInstanceConfigPrivate.h"

NSString* const kCLIENT_SIDE_MODE = @"CS";
NSString* const kSERVER_SIDE_MODE = @"SS";

@interface CTInAppStore()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@end

@implementation CTInAppStore

@synthesize mode = _mode;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo:(CTDeviceInfo *)deviceInfo
{
    self = [super init];
    if (self) {
        self.config = config;
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

- (NSMutableArray *)clientSideInApps {
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_CS];
    return [[CTPreferences getObjectForKey:storageKey]mutableCopy];
}

- (NSMutableArray *)serverSideInApps {
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_SS];
    return [[CTPreferences getObjectForKey:storageKey]mutableCopy];
}

- (void)removeClientSideInApps {
}

- (void)removeServerSideInApps {
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

// ENCRYPTION STORAGE
- (void)storeClientSideInApps:(NSArray *)clientSideInApps {
    CTAES *ctAES = [[CTAES alloc]initWithAccountID:self.config.accountId];
    NSString *encryptedString = [ctAES getEncryptedBase64String:clientSideInApps];
    
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_CS];
    [CTPreferences putString:encryptedString forKey:storageKey];
}

- (void)storeServerSideInApps:(NSArray *)serverSideInApps {
    CTAES *ctAES = [[CTAES alloc]initWithAccountID:self.config.accountId];
    NSString *encryptedString = [ctAES getEncryptedBase64String:serverSideInApps];
    
    NSString *storageKey = [NSString stringWithFormat:@"%@_%@_%@", self.config.accountId, self.deviceInfo.deviceId, CLTAP_PREFS_INAPP_KEY_SS];
    [CTPreferences putString:encryptedString forKey:storageKey];
}

@end
