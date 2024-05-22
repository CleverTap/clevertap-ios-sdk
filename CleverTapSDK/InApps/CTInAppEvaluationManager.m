//
//  CTInAppEvaluationManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "CTInAppEvaluationManager.h"
#import "CTConstants.h"
#import "CTEventAdapter.h"
#import "CTInAppStore.h"
#import "CTTriggersMatcher.h"
#import "CTLimitsMatcher.h"
#import "CTInAppTriggerManager.h"
#import "CTInAppDisplayManager.h"
#import "CTInAppNotification.h"
#import "CTUtils.h"
#import "CTPreferences.h"

@interface CTInAppEvaluationManager()

@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIds;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInApps;
@property BOOL hasAppLaunchedFailed;
@property (nonatomic, strong) NSDictionary *appLaunchedProperties;

@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppDisplayManager *inAppDisplayManager;

@property (nonatomic, strong) CTTriggersMatcher *triggersMatcher;
@property (nonatomic, strong) CTLimitsMatcher *limitsMatcher;
@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;
@property (nonatomic, strong) CTInAppStore *inAppStore;
@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;

- (void)evaluateServerSide:(CTEventAdapter *)event;
- (void)evaluateClientSide:(CTEventAdapter *)event;
- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps;

@end

@implementation CTInAppEvaluationManager

- (instancetype)initWithAccountId:(NSString *)accountId
                       deviceId:(NSString *)deviceId
                   delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
              inAppDisplayManager:(CTInAppDisplayManager *)inAppDisplayManager
                       inAppStore:(CTInAppStore *)inAppStore
              inAppTriggerManager:(CTInAppTriggerManager *)inAppTriggerManager {
    if (self = [super init]) {
        self.accountId = accountId;
        self.deviceId = deviceId;
        self.impressionManager = impressionManager;
        self.inAppDisplayManager = inAppDisplayManager;
        
        self.evaluatedServerSideInAppIds = [NSMutableArray new];
        NSArray *savedEvaluatedServerSideInAppIds = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
        if (savedEvaluatedServerSideInAppIds) {
            self.evaluatedServerSideInAppIds = [savedEvaluatedServerSideInAppIds mutableCopy];
        }
        
        self.suppressedClientSideInApps = [NSMutableArray new];
        NSArray *savedSuppressedClientSideInApps = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY]];
        if (savedSuppressedClientSideInApps) {
            self.suppressedClientSideInApps = [savedSuppressedClientSideInApps mutableCopy];
        }

        self.inAppStore = inAppStore;
        self.triggersMatcher = [CTTriggersMatcher new];
        self.limitsMatcher = [CTLimitsMatcher new];
        self.triggerManager = inAppTriggerManager;

        [delegateManager addBatchSentDelegate:self];
        [delegateManager addAttachToHeaderDelegate:self];
    }
    return self;
}

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties {
    if ([eventName isEqualToString:CLTAP_APP_LAUNCHED_EVENT]) {
        self.appLaunchedProperties = properties ? properties : @{};
        return;
    }
    
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName eventProperties:properties andLocation:self.location];
    [self evaluateServerSide:event];
    [self evaluateClientSide:event];
}

- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_CHARGED_EVENT eventProperties:chargeDetails location:self.location andItems:items];
    [self evaluateServerSide:event];
    [self evaluateClientSide:event];
}

- (void)evaluateOnAppLaunchedClientSide {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    [self evaluateClientSide:event];
}

- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:appLaunchedNotifs];
    [self sortByPriority:eligibleInApps];
    for (NSDictionary *inApp in eligibleInApps) {
        if (![self shouldSuppress:inApp]) {
            [self.inAppDisplayManager _addInAppNotificationsToQueue:@[inApp]];
            break;
        }
        
        [self suppress:inApp];
    }
}

- (void)evaluateClientSide:(CTEventAdapter *)event {
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:self.inAppStore.clientSideInApps];
    [self sortByPriority:eligibleInApps];
    
    for (NSDictionary *inApp in eligibleInApps) {
        if (![self shouldSuppress:inApp]) {
            NSMutableDictionary  *mutableInApp = [inApp mutableCopy];
            [self updateTTL:mutableInApp];
            [self.inAppDisplayManager _addInAppNotificationsToQueue:@[mutableInApp]];
            break;
        }
        
        [self suppress:inApp];
    }
}

- (void)evaluateServerSide:(CTEventAdapter *)event {
    NSArray *eligibleInApps = [self evaluate:event withInApps:self.inAppStore.serverSideInApps];
    BOOL updated = NO;
    for (NSDictionary *inApp in eligibleInApps) {
        NSString *campaignId = [CTInAppNotification inAppId:inApp];
        if (campaignId) {
            NSNumber *cid = [CTUtils numberFromString:campaignId];
            if (cid) {
                updated = YES;
                [self.evaluatedServerSideInAppIds addObject:cid];
            }
        }
    }
    if (updated) {
        [self saveEvaluatedServerSideInAppIds];
    }
}

- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps {
    NSMutableArray *eligibleInApps = [NSMutableArray new];
    for (NSDictionary *inApp in inApps) {
        NSString *campaignId = [CTInAppNotification inAppId:inApp];
        if (!campaignId) {
            continue;
        }
        if (![self.inAppDisplayManager isTemplateRegistered:inApp]) {
            continue;
        }
        
        // Match trigger
        NSArray *whenTriggers = inApp[CLTAP_INAPP_TRIGGERS];
        BOOL matchesTrigger = [self.triggersMatcher matchEventWhenTriggers:whenTriggers event:event];
        if (!matchesTrigger) continue;
        
        // In-app matches the trigger, increment trigger count
        [self.triggerManager incrementTrigger:campaignId];
        
        // Match limits
        NSArray *frequencyLimits = inApp[CLTAP_INAPP_FC_LIMITS];
        NSArray *occurrenceLimits = inApp[CLTAP_INAPP_OCCURRENCE_LIMITS];
        NSMutableArray *whenLimits = [[NSMutableArray alloc] init];
        [whenLimits addObjectsFromArray:frequencyLimits];
        [whenLimits addObjectsFromArray:occurrenceLimits];
        BOOL matchesLimits = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:campaignId
                                           withImpressionManager:self.impressionManager andTriggerManager:self.triggerManager];
        if (matchesLimits) {
            [eligibleInApps addObject:inApp];
        }
    }
    
    return eligibleInApps;
}

- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success {
    if (success) {
        NSDictionary *header = batchWithHeader[0];
        [self removeSentEvaluatedServerSideInAppIds:header];
        [self removeSentSuppressedClientSideInApps:header];
    }
}

- (void)onAppLaunchedWithSuccess:(BOOL)success {
    // Handle multiple failures when request is retried
    if (!self.hasAppLaunchedFailed) {
        [self evaluateOnAppLaunchedClientSide];
    }
    self.hasAppLaunchedFailed = !success;
}

- (void)removeSentEvaluatedServerSideInAppIds:(NSDictionary *)header {
    NSArray *inapps_eval = header[CLTAP_INAPP_SS_EVAL_META_KEY];
    if (inapps_eval && [inapps_eval count] > 0) {
        NSUInteger len = inapps_eval.count > self.evaluatedServerSideInAppIds.count ?  self.evaluatedServerSideInAppIds.count : inapps_eval.count;
        [self.evaluatedServerSideInAppIds removeObjectsInRange:NSMakeRange(0, len)];
        [self saveEvaluatedServerSideInAppIds];
    }
}

- (void)removeSentSuppressedClientSideInApps:(NSDictionary *)header {
    NSArray *suppresed_inapps = header[CLTAP_INAPP_SUPPRESSED_META_KEY];
    if (suppresed_inapps && [suppresed_inapps count] > 0) {
        NSUInteger len = suppresed_inapps.count > self.suppressedClientSideInApps.count ?  self.suppressedClientSideInApps.count : suppresed_inapps.count;
        [self.suppressedClientSideInApps removeObjectsInRange:NSMakeRange(0, len)];
        [self saveSuppressedClientSideInApps];
    }
}

- (BOOL)shouldSuppress:(NSDictionary *)inApp {
    return [inApp[CLTAP_INAPP_IS_SUPPRESSED] boolValue];
}

- (void)suppress:(NSDictionary *)inApp {
    NSString *ti = [CTInAppNotification inAppId:inApp];
    if (!ti) return;
    NSString *wzrk_id = [self generateWzrkId:ti];
    NSString *pivot = inApp[CLTAP_NOTIFICATION_PIVOT] ? inApp[CLTAP_NOTIFICATION_PIVOT] : CLTAP_NOTIFICATION_PIVOT_DEFAULT;
    NSNumber *cgId = inApp[CLTAP_NOTIFICATION_CONTROL_GROUP_ID];
    
    NSMutableDictionary *suppressedInAppMeta = [NSMutableDictionary new];
    suppressedInAppMeta[CLTAP_NOTIFICATION_ID_TAG] = wzrk_id;
    suppressedInAppMeta[CLTAP_NOTIFICATION_PIVOT] = pivot;
    if (cgId) {
        suppressedInAppMeta[CLTAP_NOTIFICATION_CONTROL_GROUP_ID] = cgId;
    }
    [self.suppressedClientSideInApps addObject:suppressedInAppMeta];
    [self saveSuppressedClientSideInApps];
}

- (void)sortByPriority:(NSMutableArray *)inApps {
    NSNumber *(^priority)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        NSNumber *priority = inApp[CLTAP_INAPP_PRIORITY];
        if (priority != nil) {
            return priority;
        }
        return @(1);
    };
    
    NSNumber *(^ti)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        id ti = inApp[CLTAP_INAPP_ID];
        if (ti && [ti isKindOfClass:[NSNumber class]]) {
            return ti;
        } else if (ti && [ti isKindOfClass:[NSString class]]) {
            ti = [CTUtils numberFromString:ti];
            if (ti) return ti;
        }
        return [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    };
    
    // Sort by priority descending since 100 is highest priority and 1 is lowest
    NSSortDescriptor* sortByPriorityDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO comparator:^NSComparisonResult(NSDictionary *inAppA, NSDictionary *inAppB) {
        NSNumber *priorityA = priority(inAppA);
        NSNumber *priorityB = priority(inAppB);
        NSComparisonResult comparison = [priorityA compare:priorityB];
        return  comparison;
    }];
    
    // Sort by the earliest created, ascending order of the timestamps
    NSSortDescriptor* sortByTimestampDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(NSDictionary *inAppA, NSDictionary *inAppB) {
        // If priority is the same, display the earliest created
        return [ti(inAppA) compare:ti(inAppB)];
    }];

    // Sort by priority then by timestamp if priority is same
    [inApps sortUsingDescriptors:@[sortByPriorityDescriptor, sortByTimestampDescriptor]];
}

- (NSString *)generateWzrkId:(NSString *)ti {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:CLTAP_DATE_FORMAT];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    NSString *wzrk_id = [NSString stringWithFormat:@"%@_%@", ti, date];
    return wzrk_id;
}

- (void)updateTTL:(NSMutableDictionary *)inApp {
    NSNumber *offset = inApp[CLTAP_INAPP_CS_TTL_OFFSET];
    if (offset != nil) {
        NSInteger now = [[NSDate date] timeIntervalSince1970];
        NSInteger ttl = now + [offset longValue];
        [inApp setObject:[NSNumber numberWithLong:ttl] forKey:CLTAP_INAPP_TTL];
    } else {
        // Remove TTL, since it cannot be calculated based on the TTL offset
        // The default TTL will be set in CTInAppNotification
        [inApp removeObjectForKey:CLTAP_INAPP_TTL];
    }
}

- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
    // Evaluation is done for events only at the moment,
    // send the evaluated and suppressed ids in that queue header
    if (queueType != CTQueueTypeEvents) {
        return [NSMutableDictionary new];
    }
    
    NSMutableDictionary *header = [NSMutableDictionary new];
    if ([self.evaluatedServerSideInAppIds count] > 0) {
        header[CLTAP_INAPP_SS_EVAL_META_KEY] = self.evaluatedServerSideInAppIds;
    }
    if ([self.suppressedClientSideInApps count] > 0) {
        header[CLTAP_INAPP_SUPPRESSED_META_KEY] = self.suppressedClientSideInApps;
    }
    
    return header;
}

- (void)saveEvaluatedServerSideInAppIds {
    [CTPreferences putObject:self.evaluatedServerSideInAppIds forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
}

- (void)saveSuppressedClientSideInApps {
    [CTPreferences putObject:self.suppressedClientSideInApps forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY]];
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.accountId, suffix, self.deviceId];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.accountId, self.deviceId];
}

@end
