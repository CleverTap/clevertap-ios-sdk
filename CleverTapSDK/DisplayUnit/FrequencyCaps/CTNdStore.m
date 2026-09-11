//
//  CTNdStore.m
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import "CTNdStore.h"
#import "CTSwitchUserDelegate.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"
#import "CTMultiDelegateManager.h"

@interface CTNdStore () <CTSwitchUserDelegate>

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;

@property (nonatomic, strong) NSArray *serverSideNativeDisplays;

@end

@implementation CTNdStore

@synthesize serverSideNativeDisplays = _serverSideNativeDisplays;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId {
    self = [super init];
    if (self) {
        self.config = config;
        self.accountId = config.accountId;
        self.deviceId = deviceId;

        [delegateManager addSwitchUserDelegate:self];
    }
    return self;
}

#pragma mark Server-Side Native Displays

- (NSArray *)serverSideNativeDisplays {
    @synchronized (self) {
        if (_serverSideNativeDisplays) return _serverSideNativeDisplays;

        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_ND_KEY_SS];
        id saved = [CTPreferences getObjectForKey:storageKey];
        if ([saved isKindOfClass:[NSArray class]]) {
            _serverSideNativeDisplays = saved;
        } else {
            _serverSideNativeDisplays = [NSArray new];
        }
        return _serverSideNativeDisplays;
    }
}

- (void)storeServerSideNativeDisplays:(NSArray *)serverSideNativeDisplays {
    if (!serverSideNativeDisplays) return;

    @synchronized (self) {
        _serverSideNativeDisplays = serverSideNativeDisplays;
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_ND_KEY_SS];
        [CTPreferences putObject:serverSideNativeDisplays forKey:storageKey];
    }
}

- (void)removeServerSideNativeDisplays {
    @synchronized (self) {
        _serverSideNativeDisplays = [NSArray new];
        NSString *storageKey = [self storageKeyWithSuffix:CLTAP_PREFS_ND_KEY_SS];
        [CTPreferences removeObjectForKey:storageKey];
    }
}

#pragma mark Storage Key

// Same key order as CTInAppStore. That order is accountId:deviceId:suffix. CTInAppFCManager uses a
// different order. Each class copies the one it is based on.
- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.accountId, self.deviceId, suffix];
}

#pragma mark CTSwitchUserDelegate

- (void)deviceIdDidChange:(NSString *)newDeviceId {
    @synchronized (self) {
        self.deviceId = newDeviceId;
        // Set to nil so the next read loads the new user's rules from storage.
        _serverSideNativeDisplays = nil;
    }
}

@end
