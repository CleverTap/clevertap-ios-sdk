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
#import "CTInAppImagePrefetchManager.h"

@implementation InAppHelper

- (NSString *)accountId {
    return @"testAccountId";
}

- (NSString *)accountToken {
    return @"testAccountToken";
}

- (NSString *)deviceId {
    return @"testDeviceId";
}

- (NSString *)campaignId {
    return @"testCampaignId";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegateManager = [CTMultiDelegateManager new];
        
        self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:self.accountId accountToken:self.accountToken];
        
        self.imagePrefetchManager = [[CTInAppImagePrefetchManager alloc] initWithConfig:self.config];
        
        self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:self.accountId
                                                                       deviceId:self.deviceId
                                                                delegateManager:self.delegateManager];
        
        self.inAppStore = [[CTInAppStore alloc] initWithConfig:self.config
                                               delegateManager:self.delegateManager
                                          imagePrefetchManager:self.imagePrefetchManager
                                                      deviceId:self.deviceId];
        
        self.inAppTriggerManager = [[CTInAppTriggerManager alloc] initWithAccountId:self.accountId
                                                                           deviceId:self.deviceId
                                                                    delegateManager:self.delegateManager];
        
        self.inAppFCManager = [[CTInAppFCManager alloc] initWithConfig:self.config
                                                       delegateManager:self.delegateManager
                                                              deviceId:self.deviceId
                                                     impressionManager:self.impressionManager
                                                   inAppTriggerManager:self.inAppTriggerManager];
        
        // Initialize when needed, requires CleverTap instance
        self.inAppDisplayManager = nil;
        
        self.inAppEvaluationManager = [[CTInAppEvaluationManager alloc] initWithAccountId:self.config.accountId
                                                                                 deviceId:self.deviceId
                                                                          delegateManager:self.delegateManager
                                                                        impressionManager:self.impressionManager
                                                                      inAppDisplayManager:self.inAppDisplayManager
                                                                               inAppStore:self.inAppStore
                                                                      inAppTriggerManager:self.inAppTriggerManager];
    }
    return self;
}
@end
