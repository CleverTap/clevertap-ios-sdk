//
//  NdHelper.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import "NdHelper.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"
#import "CTMultiDelegateManager.h"
#import "CTImpressionManager.h"
#import "CTInAppTriggerManager.h"
#import "CTLocalDataStore.h"
#import "CTDeviceInfo.h"
#import "CTDispatchQueueManager.h"
#import "CTNdStore.h"
#import "CTNdFCManager.h"
#import "CTNdEvaluationManager.h"

@implementation NdHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        // A fresh account id per test. Preferences are one flat keyspace and every key below starts
        // with the account id, so this is what keeps one test's counts out of the next one's.
        _accountId = [NSString stringWithFormat:@"ndTestAccount_%@", [[NSUUID UUID] UUIDString]];
        _deviceId = @"ndTestDeviceId";

        self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:_accountId
                                                            accountToken:@"ndTestAccountToken"];
        self.delegateManager = [CTMultiDelegateManager new];

        self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:_accountId
                                                                       deviceId:_deviceId
                                                                delegateManager:self.delegateManager
                                                               storageNamespace:CLTAP_PREFS_ND_IMPRESSIONS_NAMESPACE];

        self.triggerManager = [[CTInAppTriggerManager alloc] initWithAccountId:_accountId
                                                                      deviceId:_deviceId
                                                               delegateManager:self.delegateManager
                                                              storageNamespace:CLTAP_PREFS_ND_TRIGGERS_NAMESPACE];

        self.ndStore = [[CTNdStore alloc] initWithConfig:self.config
                                         delegateManager:self.delegateManager
                                                deviceId:_deviceId];

        self.ndFCManager = [[CTNdFCManager alloc] initWithConfig:self.config
                                                 delegateManager:self.delegateManager
                                                        deviceId:_deviceId
                                               impressionManager:self.impressionManager
                                                  triggerManager:self.triggerManager];

        CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:_deviceId];
        CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:self.config];
        self.dataStore = [[CTLocalDataStore alloc] initWithConfig:self.config
                                                    profileValues:[NSMutableDictionary new]
                                                    andDeviceInfo:deviceInfo
                                             dispatchQueueManager:queueManager];

        self.evaluationManager = [[CTNdEvaluationManager alloc] initWithAccountId:_accountId
                                                                         deviceId:_deviceId
                                                                  delegateManager:self.delegateManager
                                                                impressionManager:self.impressionManager
                                                                   triggerManager:self.triggerManager
                                                                          ndStore:self.ndStore
                                                                   localDataStore:self.dataStore];
    }
    return self;
}

- (void)tearDown {
    // Sweeping by account id rather than listing the keys, because the managers between them write
    // about a dozen and a list would quietly go out of date the next time one is added. The account
    // id has a UUID in it, so nothing else can match.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keys = [[defaults dictionaryRepresentation] allKeys];
    for (NSString *key in keys) {
        if ([key containsString:self.accountId]) {
            [defaults removeObjectForKey:key];
        }
    }
    [defaults synchronize];
}

@end
