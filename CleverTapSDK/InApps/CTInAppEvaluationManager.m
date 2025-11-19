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
@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIdsForProfile;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInAppsForProfile;
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

- (void)evaluateServerSide:(NSArray<CTEventAdapter *> *)events withQueueType:(CTQueueType)queueType;
- (void)evaluateClientSide:(NSArray<CTEventAdapter *> *)events;
- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps;

@end

@implementation CTInAppEvaluationManager

- (instancetype)initWithAccountId:(NSString *)accountId
                       deviceId:(NSString *)deviceId
                   delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
              inAppDisplayManager:(CTInAppDisplayManager *)inAppDisplayManager
                       inAppStore:(CTInAppStore *)inAppStore
              inAppTriggerManager:(CTInAppTriggerManager *)inAppTriggerManager
                   localDataStore:(CTLocalDataStore *)dataStore {
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
        
        self.evaluatedServerSideInAppIdsForProfile = [NSMutableArray new];
        NSArray *savedEvaluatedServerSideInAppIdsForProfile = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY_PROFILE]];
        if (savedEvaluatedServerSideInAppIdsForProfile) {
            self.evaluatedServerSideInAppIdsForProfile = [savedEvaluatedServerSideInAppIdsForProfile mutableCopy];
        }
        
        self.suppressedClientSideInAppsForProfile = [NSMutableArray new];
        NSArray *savedSuppressedClientSideInAppsForProfile = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY_PROFILE]];
        if (savedSuppressedClientSideInAppsForProfile) {
            self.suppressedClientSideInAppsForProfile = [savedSuppressedClientSideInAppsForProfile mutableCopy];
        }

        self.inAppStore = inAppStore;
        self.triggersMatcher = [[CTTriggersMatcher alloc] initWithDataStore:dataStore];
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
    NSArray *eventList = @[event];
    [self evaluateServerSide:eventList withQueueType:CTQueueTypeEvents];
    [self evaluateClientSide:eventList];
}

-(void)evaluateOnUserAttributeChange:(NSDictionary<NSString *, NSDictionary *> *)profile {
    NSDictionary *appFields = self.appLaunchedProperties;
    NSMutableArray<CTEventAdapter *> *eventAdapterList = [NSMutableArray array];
    [profile enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        NSString *eventName = [key stringByAppendingString:CLTAP_USER_ATTRIBUTE_CHANGE];
        NSMutableDictionary *eventProperties = [NSMutableDictionary dictionaryWithDictionary:value];
        [eventProperties addEntriesFromDictionary:appFields];
        CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName profileAttrName:key eventProperties: value andLocation:self.location];
        [eventAdapterList addObject:event];
    }];
    [self evaluateServerSide:eventAdapterList withQueueType:CTQueueTypeProfile];
    [self evaluateClientSide:eventAdapterList];
    
}

- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_CHARGED_EVENT eventProperties:chargeDetails location:self.location andItems:items];
    NSArray *eventList = @[event];
    CTQueueType queueType = CTQueueTypeEvents;
    [self evaluateServerSide:eventList withQueueType:queueType];
    [self evaluateClientSide:eventList];
}

- (void)evaluateOnAppLaunchedClientSide {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    NSArray *eventList = @[event];
    [self evaluateClientSide:eventList];
}

- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:appLaunchedNotifs];
    // Server-side evaluations do **NOT** update TTL
    [self _processEligibleInApps:eligibleInApps shouldUpdateTTL:NO];
}

- (void)evaluateClientSide:(NSArray<CTEventAdapter *> *)events {
    NSMutableArray<NSDictionary *> *eligibleInApps = [NSMutableArray array];    
    for (CTEventAdapter *event in events) {
        id oldValue = [event.eventProperties objectForKey:CLTAP_KEY_OLD_VALUE];
        id newValue = [event.eventProperties objectForKey:CLTAP_KEY_NEW_VALUE];
        if (event.profileAttrName != nil && newValue == oldValue) {
            continue;
        }
        [eligibleInApps addObjectsFromArray:[self evaluate:event withInApps:self.inAppStore.clientSideInApps]];
    }
    // Client-side evaluations **DO** update TTL
    [self _processEligibleInApps:eligibleInApps shouldUpdateTTL:YES];
}

- (void)evaluateServerSide:(NSArray<CTEventAdapter *> *)events withQueueType:(CTQueueType)queueType{
    NSMutableArray<NSDictionary *> *eligibleInApps = [NSMutableArray array];
    for (CTEventAdapter *event in events) {
        [eligibleInApps addObjectsFromArray:[self evaluate:event withInApps:self.inAppStore.serverSideInApps]];
    }
    BOOL updated = NO;
    for (NSDictionary *inApp in eligibleInApps) {
        NSString *campaignId = [CTInAppNotification inAppId:inApp];
        if (campaignId) {
            NSNumber *cid = [CTUtils numberFromString:campaignId];
            if (cid) {
                updated = YES;
                if (queueType == CTQueueTypeEvents){
                    [self.evaluatedServerSideInAppIds addObject:cid];
                }
                else if (queueType == CTQueueTypeProfile){
                    [self.evaluatedServerSideInAppIdsForProfile addObject:cid];
                }
            }
        }
    }
    if (updated) {
        if (queueType == CTQueueTypeEvents){
            [self saveEvaluatedServerSideInAppIds];
        }
        else if (queueType == CTQueueTypeProfile){
            [self saveEvaluatedServerSideInAppIdsForProfile];
        }
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

- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success withQueueType:(CTQueueType)queueType{
    if (success) {
        NSDictionary *header = batchWithHeader[0];
        if (queueType == CTQueueTypeEvents) {
            // For combined queues, clean up both events and profile arrays proportionally
            [self removeSentEvaluatedServerSideInAppIdsForCombined:header];
            [self removeSentSuppressedClientSideInAppsForCombined:header];
        }
    }
}

- (void)onAppLaunchedWithSuccess:(BOOL)success {
    // Handle multiple failures when request is retried
    if (!self.hasAppLaunchedFailed) {
        [self evaluateOnAppLaunchedClientSide];
    }
    self.hasAppLaunchedFailed = !success;
}

- (void)removeSentEvaluatedServerSideInAppIdsForCombined:(NSDictionary *)header {
    NSArray *inapps_eval = header[CLTAP_INAPP_SS_EVAL_META_KEY];
    if (inapps_eval && [inapps_eval count] > 0) {
        // Remove from events array first, then profiles
        NSUInteger eventsCount = [self.evaluatedServerSideInAppIds count];
        NSUInteger profilesCount = [self.evaluatedServerSideInAppIdsForProfile count];
        NSUInteger totalToRemove = [inapps_eval count];
        
        // Remove from events array
        NSUInteger removeFromEvents = MIN(eventsCount, totalToRemove);
        if (removeFromEvents > 0) {
            [self.evaluatedServerSideInAppIds removeObjectsInRange:NSMakeRange(0, removeFromEvents)];
            [self saveEvaluatedServerSideInAppIds];
            totalToRemove -= removeFromEvents;
        }
        
        // Remove remaining from profiles array
        if (totalToRemove > 0) {
            NSUInteger removeFromProfiles = MIN(profilesCount, totalToRemove);
            if (removeFromProfiles > 0) {
                [self.evaluatedServerSideInAppIdsForProfile removeObjectsInRange:NSMakeRange(0, removeFromProfiles)];
                [self saveEvaluatedServerSideInAppIdsForProfile];
            }
        }
    }
}

- (void)removeSentSuppressedClientSideInAppsForCombined:(NSDictionary *)header {
    NSArray *suppressed_inapps = header[CLTAP_INAPP_SUPPRESSED_META_KEY];
    if (suppressed_inapps && [suppressed_inapps count] > 0) {
        // Remove from events array first, then profiles
        NSUInteger eventsCount = [self.suppressedClientSideInApps count];
        NSUInteger profilesCount = [self.suppressedClientSideInAppsForProfile count];
        NSUInteger totalToRemove = [suppressed_inapps count];
        
        // Remove from events array
        NSUInteger removeFromEvents = MIN(eventsCount, totalToRemove);
        if (removeFromEvents > 0) {
            [self.suppressedClientSideInApps removeObjectsInRange:NSMakeRange(0, removeFromEvents)];
            [self saveSuppressedClientSideInApps];
            totalToRemove -= removeFromEvents;
        }
        
        // Remove remaining from profiles array
        if (totalToRemove > 0) {
            NSUInteger removeFromProfiles = MIN(profilesCount, totalToRemove);
            if (removeFromProfiles > 0) {
                [self.suppressedClientSideInAppsForProfile removeObjectsInRange:NSMakeRange(0, removeFromProfiles)];
                [self saveSuppressedClientSideInAppsForProfile];
            }
        }
    }
}

- (void)_processEligibleInApps:(NSArray<NSDictionary *> *)eligibleInApps
               shouldUpdateTTL:(BOOL)shouldUpdateTTL {
    if (eligibleInApps.count == 0) return;
    
    // Sort by priority
    NSMutableArray *sorted = [eligibleInApps mutableCopy];
    [self sortByPriority:sorted];
    
    // Partition into delayed + immediate
    NSDictionary<NSString *, NSArray *> *partitioned =
    [self.inAppStore partitionInApps:sorted];
    
    NSArray *delayedQueue   = partitioned[@"delayed"] ?: @[];
    NSArray *immediateQueue = partitioned[@"immediate"] ?: @[];
    
    // Handle all delayed in-apps
    for (NSDictionary *inApp in delayedQueue) {
        [self processInApp:inApp allowOnlyFirst:NO shouldUpdate:shouldUpdateTTL];
    }
    
    // Handle the first immediate in-app
    for (NSDictionary *inApp in immediateQueue) {
        if ([self processInApp:inApp allowOnlyFirst:YES shouldUpdate:shouldUpdateTTL]) {
            break;
        }
    }
}

- (BOOL)processInApp:(NSDictionary *)inApp allowOnlyFirst:(BOOL)onlyOne shouldUpdate:(BOOL)updateTTL{
    BOOL suppressed = [self shouldSuppress:inApp];
    
    if (suppressed) {
        [self suppress:inApp];
        return NO;
    }
    
    NSMutableDictionary *mutable = [inApp mutableCopy];
    if (updateTTL) {
        [self.inAppStore updateTTL:mutable];
    }
    [self.inAppDisplayManager _addInAppNotificationsToQueue:@[mutable]];
    
    return onlyOne;
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
    NSNumber *(^delay)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        NSNumber *d = inApp[CLTAP_DELAY_AFTER_TRIGGER];
           if (d != nil) return d;
           return @(0); // default to 0 if missing
       };
    
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
    
    // Sort by delay ascending
    NSSortDescriptor *sortByDelayDescriptor =
    [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [delay(a) compare:delay(b)];
    }];
    
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

    // Sort by delay theny by priority if delay is same
    //then by timestamp if priority is same
    [inApps sortUsingDescriptors:@[sortByDelayDescriptor, sortByPriorityDescriptor, sortByTimestampDescriptor]];
}

- (NSString *)generateWzrkId:(NSString *)ti {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:CLTAP_DATE_FORMAT];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    NSString *wzrk_id = [NSString stringWithFormat:@"%@_%@", ti, date];
    return wzrk_id;
}

- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
   // Evaluation is done for events and profiles,
   // send the evaluated and suppressed ids in that queue header
   if (queueType != CTQueueTypeEvents && queueType != CTQueueTypeProfile) {
       return [NSMutableDictionary new];
   }
   
   NSMutableDictionary *header = [NSMutableDictionary new];
   
   // For combined queues, merge both events and profile arrays
   if (queueType == CTQueueTypeEvents) {
       // Combine evaluated IDs from both events and profiles
       NSMutableArray *combinedEvaluatedIds = [NSMutableArray array];
       if ([self.evaluatedServerSideInAppIds count] > 0) {
           [combinedEvaluatedIds addObjectsFromArray:self.evaluatedServerSideInAppIds];
       }
       if ([self.evaluatedServerSideInAppIdsForProfile count] > 0) {
           [combinedEvaluatedIds addObjectsFromArray:self.evaluatedServerSideInAppIdsForProfile];
       }
       if ([combinedEvaluatedIds count] > 0) {
           header[CLTAP_INAPP_SS_EVAL_META_KEY] = combinedEvaluatedIds;
       }
       
       // Combine suppressed IDs from both events and profiles
       NSMutableArray *combinedSuppressedIds = [NSMutableArray array];
       if ([self.suppressedClientSideInApps count] > 0) {
           [combinedSuppressedIds addObjectsFromArray:self.suppressedClientSideInApps];
       }
       if ([self.suppressedClientSideInAppsForProfile count] > 0) {
           [combinedSuppressedIds addObjectsFromArray:self.suppressedClientSideInAppsForProfile];
       }
       if ([combinedSuppressedIds count] > 0) {
           header[CLTAP_INAPP_SUPPRESSED_META_KEY] = combinedSuppressedIds;
       }
   }
   return header;
}

- (void)saveEvaluatedServerSideInAppIds {
    [CTPreferences putObject:self.evaluatedServerSideInAppIds forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
}

- (void)saveSuppressedClientSideInApps {
    [CTPreferences putObject:self.suppressedClientSideInApps forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY]];
}

- (void)saveEvaluatedServerSideInAppIdsForProfile {
    [CTPreferences putObject:self.evaluatedServerSideInAppIdsForProfile forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY_PROFILE]];
}

- (void)saveSuppressedClientSideInAppsForProfile {
    [CTPreferences putObject:self.suppressedClientSideInAppsForProfile forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY_PROFILE]];
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.accountId, suffix, self.deviceId];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.accountId, self.deviceId];
}

@end
