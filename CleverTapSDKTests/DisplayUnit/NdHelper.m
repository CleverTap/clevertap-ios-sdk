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
        // A new account id for each test. Preferences are one flat list of keys. Every key below
        // starts with the account id. That keeps one test's counts out of the next test's.
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
    // We search by account id instead of listing the keys. The managers write about a dozen keys
    // between them. A list would go out of date the next time someone adds a key. The account id
    // has a UUID in it. Nothing else can match it.
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
