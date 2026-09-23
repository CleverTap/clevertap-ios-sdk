//
//  CTInAppTriggerManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTInAppTriggerManager.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CTMultiDelegateManager.h"

@interface CTInAppTriggerManager()

@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, copy, readwrite) NSString *storageNamespace;

@end

@implementation CTInAppTriggerManager

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager {
    return [self initWithAccountId:accountId
                          deviceId:deviceId
                   delegateManager:delegateManager
                  storageNamespace:CLTAP_PREFS_INAPP_TRIGGERS_NAMESPACE];
}

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                 storageNamespace:(NSString *)storageNamespace {
    self = [super init];
    if (self) {
        self.accountId = accountId;
        self.deviceId = deviceId;
        self.storageNamespace = storageNamespace;
        [delegateManager addSwitchUserDelegate:self];
    }
    return self;
}

#pragma mark Manage Triggers
- (NSUInteger)getTriggers:(NSString *)campaignId {
    NSUInteger savedTriggers = [CTPreferences getIntForKey:[self getTriggersKey:campaignId] withResetValue:0];
    
    return savedTriggers;
}

- (void)incrementTrigger:(NSString *)campaignId {
    NSUInteger savedTriggers = [self getTriggers:campaignId];
    savedTriggers++;
    [CTPreferences putInt:savedTriggers forKey:[self getTriggersKey:campaignId]];
}

- (void)removeTriggers:(NSString *)campaignId {
    [CTPreferences removeObjectForKey:[self getTriggersKey:campaignId]];
}

- (NSString *)getTriggersKey:(NSString *)campaignId {
    return [NSString stringWithFormat:@"%@:%@:%@:%@", self.accountId, self.deviceId, self.storageNamespace, campaignId];
}

#pragma mark Switch User Delegate

- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceId = newDeviceId;
}

@end
