//
//  InAppHelper.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 15.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "InAppHelper.h"
#import "CleverTapInstanceConfig.h"
#import "CTMultiDelegateManager.h"
#import "CTImpressionManager.h"
#import "CTInAppEvaluationManager.h"
#import "CTInAppStore.h"
#import "CleverTapInstanceConfig.h"
#import "CTInAppFCManager.h"
#import "CTInAppTriggerManager.h"
#import "CTFileDownloader.h"

NSString *const CLTAP_TEST_ACCOUNT_ID = @"testAccountId";
NSString *const CLTAP_TEST_ACCOUNT_TOKEN = @"testAccountToken";
NSString *const CLTAP_TEST_DEVICE_ID = @"testDeviceId";
NSString *const CLTAP_TEST_CAMPAIGN_ID = @"testCampaignId";

@implementation InAppHelper

- (NSString *)accountId {
    return CLTAP_TEST_ACCOUNT_ID;
}

- (NSString *)accountToken {
    return CLTAP_TEST_ACCOUNT_TOKEN;
}

- (NSString *)deviceId {
    return CLTAP_TEST_DEVICE_ID;
}

- (NSString *)campaignId {
    return CLTAP_TEST_CAMPAIGN_ID;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegateManager = [CTMultiDelegateManager new];
        
        self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:self.accountId accountToken:self.accountToken];
        
        self.fileDownloader = [[CTFileDownloader alloc] initWithConfig:self.config];
        
        self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:self.accountId
                                                                       deviceId:self.deviceId
                                                                delegateManager:self.delegateManager];
        
        self.inAppStore = [[CTInAppStore alloc] initWithConfig:self.config
                                               delegateManager:self.delegateManager
                                                      deviceId:self.deviceId];
        
        self.inAppTriggerManager = [[CTInAppTriggerManager alloc] initWithAccountId:self.accountId
                                                                           deviceId:self.deviceId
                                                                    delegateManager:self.delegateManager];
        
        self.inAppFCManager = [[CTInAppFCManager alloc] initWithConfig:self.config
                                                       delegateManager:self.delegateManager
                                                              deviceId:self.deviceId
                                                     impressionManager:self.impressionManager
                                                   inAppTriggerManager:self.inAppTriggerManager];
        
        CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:self.config andCleverTapID:CLTAP_TEST_DEVICE_ID];
        CTDispatchQueueManager *queueManager = [[CTDispatchQueueManager alloc] initWithConfig:self.config];
        self.dataStore = [[CTLocalDataStore alloc] initWithConfig:self.config profileValues:[NSMutableDictionary new] andDeviceInfo:deviceInfo dispatchQueueManager:queueManager];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        // Initialize when needed, requires CleverTap instance
        self.inAppDisplayManager = nil;
#pragma clang diagnostic pop
        
        self.inAppEvaluationManager = [[CTInAppEvaluationManager alloc] initWithAccountId:self.config.accountId
                                                                                 deviceId:self.deviceId
                                                                          delegateManager:self.delegateManager
                                                                        impressionManager:self.impressionManager
                                                                      inAppDisplayManager:self.inAppDisplayManager
                                                                               inAppStore:self.inAppStore
                                                                      inAppTriggerManager:self.inAppTriggerManager localDataStore:self.dataStore];
    }
    return self;
}
@end
