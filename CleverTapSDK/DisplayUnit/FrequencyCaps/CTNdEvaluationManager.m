//
//  CTNdEvaluationManager.m
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import "CTNdEvaluationManager.h"
#import "CTNdStore.h"
#import "CTNdFCManager.h"
#import "CTConstants.h"
#import "CTEventAdapter.h"
#import "CTTriggersMatcher.h"
#import "CTLimitsMatcher.h"
#import "CTImpressionManager.h"
#import "CTInAppTriggerManager.h"
#import "CTMultiDelegateManager.h"
#import "CTPreferences.h"
#import "CTUtils.h"

@interface CTNdEvaluationManager ()

/// The ti of every campaign the user qualified for that has not been sent yet.
@property (nonatomic, strong) NSMutableArray *evaluatedServerSideNativeDisplayIds;
/// Control group replies waiting to be sent. See recordSuppressedNativeDisplay:.
@property (nonatomic, strong) NSMutableArray *suppressedNativeDisplays;

/// The properties of the last App Launched event, merged into profile change events.
@property (nonatomic, strong) NSDictionary *appLaunchedProperties;

@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;
@property (nonatomic, strong) CTNdStore *ndStore;

@property (nonatomic, strong) CTTriggersMatcher *triggersMatcher;
@property (nonatomic, strong) CTLimitsMatcher *limitsMatcher;

@property (nonatomic, strong) NSString *accountId;
@property (atomic, copy) NSString *deviceId;

@end

@implementation CTNdEvaluationManager

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
                   triggerManager:(CTInAppTriggerManager *)triggerManager
                          ndStore:(CTNdStore *)ndStore
                   localDataStore:(CTLocalDataStore *)dataStore {
    if (self = [super init]) {
        self.accountId = accountId;
        self.deviceId = deviceId;
        self.impressionManager = impressionManager;
        self.triggerManager = triggerManager;
        self.ndStore = ndStore;

        // Both matchers hold no state. They take the managers on each call. In-app's could have
        // been shared. Making our own is cheap. It also keeps the two channels apart.
        self.triggersMatcher = [[CTTriggersMatcher alloc] initWithDataStore:dataStore];
        self.limitsMatcher = [CTLimitsMatcher new];

        [self loadPendingLists];

        [delegateManager addBatchSentDelegate:self];
        [delegateManager addAttachToHeaderDelegate:self];
        [delegateManager addSwitchUserDelegate:self];
    }
    return self;
}

- (void)loadPendingLists {
    self.evaluatedServerSideNativeDisplayIds = [NSMutableArray new];
    NSArray *savedEvaluated = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_ND_SS_EVAL_STORAGE_KEY]];
    if ([savedEvaluated isKindOfClass:[NSArray class]]) {
        self.evaluatedServerSideNativeDisplayIds = [savedEvaluated mutableCopy];
    }

    self.suppressedNativeDisplays = [NSMutableArray new];
    NSArray *savedSuppressed = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_ND_SUPPRESSED_STORAGE_KEY]];
    if ([savedSuppressed isKindOfClass:[NSArray class]]) {
        self.suppressedNativeDisplays = [savedSuppressed mutableCopy];
    }
}

#pragma mark Evaluation Entry Points

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties {
    if ([eventName isEqualToString:CLTAP_APP_LAUNCHED_EVENT]) {
        // App Launched is not evaluated for Native Display. We keep its properties anyway. Profile
        // change events are matched against them too.
        self.appLaunchedProperties = properties ? properties : @{};
        return;
    }

    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName
                                                      eventProperties:properties ? properties : @{}
                                                          andLocation:self.location];
    [self evaluate:@[event]];
}

- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_CHARGED_EVENT
                                                      eventProperties:chargeDetails ? chargeDetails : @{}
                                                             location:self.location
                                                             andItems:items ? items : @[]];
    [self evaluate:@[event]];
}

- (void)evaluateOnUserAttributeChange:(NSDictionary<NSString *, NSDictionary *> *)profile {
    NSDictionary *appFields = self.appLaunchedProperties ? self.appLaunchedProperties : @{};
    NSMutableArray<CTEventAdapter *> *events = [NSMutableArray array];

    [[self toNestedMap:profile] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *value, BOOL *stop) {
        if ([CLTAP_SKIP_KEYS_USER_ATTRIBUTE_EVALUATION containsObject:key]) {
            return;
        }
        NSString *eventName = [key stringByAppendingString:CLTAP_USER_ATTRIBUTE_CHANGE];
        NSMutableDictionary *eventProperties = [NSMutableDictionary dictionaryWithDictionary:value];
        [eventProperties addEntriesFromDictionary:appFields];
        CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName
                                                          profileAttrName:key
                                                          eventProperties:eventProperties
                                                              andLocation:self.location];
        [events addObject:event];
    }];

    [self evaluate:events];
}

- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)toNestedMap:(NSDictionary<NSString *, NSDictionary *> *)profileChanges {
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *result =
        [NSMutableDictionary dictionaryWithCapacity:profileChanges.count];

    [profileChanges enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *change, BOOL *stop) {
        result[key] = @{
            @"oldValue": change[@"oldValue"] ?: [NSNull null],
            @"newValue": change[@"newValue"] ?: [NSNull null]
        };
    }];
    return [result copy];
}

#pragma mark Evaluation

- (void)evaluate:(NSArray<CTEventAdapter *> *)events {
    NSArray *nativeDisplays = [self.ndStore serverSideNativeDisplays];
    if (nativeDisplays.count == 0) return;

    BOOL updated = NO;
    for (CTEventAdapter *event in events) {
        for (NSDictionary *nativeDisplay in nativeDisplays) {
            if (![nativeDisplay isKindOfClass:[NSDictionary class]]) continue;

            // Same helper the cap manager uses. Triggers and impressions must use one id. Two
            // helpers could drift apart. Then one would write the id and the other would read it.
            NSString *campaignId = [CTNdFCManager campaignIdFrom:nativeDisplay];
            if (campaignId.length == 0) continue;

            NSArray *whenTriggers = nativeDisplay[CLTAP_INAPP_TRIGGERS];
            if (![self.triggersMatcher matchEventWhenTriggers:whenTriggers event:event]) continue;

            // The campaign matched the trigger. Its trigger count goes up whether the limits pass
            // or not. occurrenceLimits are counted in triggers. They need this.
            [self.triggerManager incrementTrigger:campaignId];

            NSMutableArray *whenLimits = [NSMutableArray new];
            [whenLimits addObjectsFromArray:nativeDisplay[CLTAP_INAPP_FC_LIMITS]];
            [whenLimits addObjectsFromArray:nativeDisplay[CLTAP_INAPP_OCCURRENCE_LIMITS]];
            BOOL matchesLimits = [self.limitsMatcher matchWhenLimits:whenLimits
                                                       forCampaignId:campaignId
                                               withImpressionManager:self.impressionManager
                                                   andTriggerManager:self.triggerManager];
            if (!matchesLimits) continue;

            NSNumber *ti = [CTUtils numberFromString:campaignId];
            if (!ti) continue;

            // Added even if the same id is already in the list. A campaign can qualify again
            // during a send. A send removes only what it sent. A dropped repeat would be lost.
            // The server ignores repeats.
            @synchronized (self) {
                [self.evaluatedServerSideNativeDisplayIds addObject:ti];
            }
            updated = YES;
            CleverTapLogStaticDebug(@"Native Display campaign %@ is eligible for event %@", ti, [event eventName]);
        }
    }

    if (updated) {
        [self saveEvaluatedServerSideNativeDisplayIds];
    }
}

#pragma mark Control Group Replies

- (void)recordSuppressedNativeDisplay:(NSDictionary *)suppressedUnit {
    if (![suppressedUnit isKindOfClass:[NSDictionary class]]) return;

    NSString *wzrkId = suppressedUnit[CLTAP_NOTIFICATION_ID_TAG];
    if (![wzrkId isKindOfClass:[NSString class]] || wzrkId.length == 0) {
        // The server always sends wzrk_id on these stubs. This should not happen. Without one
        // there is nothing to reply about. Log it instead of dropping it silently.
        CleverTapLogStaticDebug(@"Dropping Native Display control group reply, no wzrk_id on %@", suppressedUnit);
        return;
    }

    NSMutableDictionary *reply = [NSMutableDictionary new];
    reply[CLTAP_NOTIFICATION_ID_TAG] = wzrkId;
    reply[CLTAP_NOTIFICATION_PIVOT] = suppressedUnit[CLTAP_NOTIFICATION_PIVOT] ?: CLTAP_NOTIFICATION_PIVOT_DEFAULT;
    NSNumber *controlGroupId = suppressedUnit[CLTAP_NOTIFICATION_CONTROL_GROUP_ID];
    if (controlGroupId) {
        reply[CLTAP_NOTIFICATION_CONTROL_GROUP_ID] = controlGroupId;
    }

    @synchronized (self) {
        [self.suppressedNativeDisplays addObject:reply];
    }
    [self saveSuppressedNativeDisplays];
    CleverTapLogStaticDebug(@"Recorded Native Display control group reply for %@", wzrkId);
}

#pragma mark AttachToBatchHeader delegate

- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
    NSMutableDictionary *header = [NSMutableDictionary new];
    // Both lists go out on the events batch, even entries that came from a profile change. In-app
    // sends its versions there too. The server reads them from the same place.
    if (queueType != CTQueueTypeEvents) return header;

    @synchronized (self) {
        if (self.evaluatedServerSideNativeDisplayIds.count > 0) {
            header[CLTAP_ND_SS_EVAL_META_KEY] = [self.evaluatedServerSideNativeDisplayIds copy];
        }
        if (self.suppressedNativeDisplays.count > 0) {
            header[CLTAP_ND_SUPPRESSED_META_KEY] = [self.suppressedNativeDisplays copy];
        }
    }
    return header;
}

#pragma mark BatchSent delegate

- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success withQueueType:(CTQueueType)queueType {
    if (!success || queueType != CTQueueTypeEvents) return;

    NSDictionary *header = batchWithHeader.firstObject;
    if (![header isKindOfClass:[NSDictionary class]]) return;

    [self removeSent:header[CLTAP_ND_SS_EVAL_META_KEY]
            fromList:self.evaluatedServerSideNativeDisplayIds
             didSave:^{ [self saveEvaluatedServerSideNativeDisplayIds]; }];

    [self removeSent:header[CLTAP_ND_SUPPRESSED_META_KEY]
            fromList:self.suppressedNativeDisplays
             didSave:^{ [self saveSuppressedNativeDisplays]; }];
}

/// Removes as many entries from the front of the list as the batch carried, and no more. New
/// entries arriving during the send sit behind them. Those go out next time.
- (void)removeSent:(NSArray *)sent fromList:(NSMutableArray *)list didSave:(void (^)(void))save {
    if (![sent isKindOfClass:[NSArray class]] || sent.count == 0) return;

    @synchronized (self) {
        NSUInteger toRemove = MIN(list.count, sent.count);
        if (toRemove == 0) return;
        [list removeObjectsInRange:NSMakeRange(0, toRemove)];
    }
    save();
}

#pragma mark Storage

- (void)saveEvaluatedServerSideNativeDisplayIds {
    @synchronized (self) {
        [CTPreferences putObject:[self.evaluatedServerSideNativeDisplayIds copy]
                          forKey:[self storageKeyWithSuffix:CLTAP_ND_SS_EVAL_STORAGE_KEY]];
    }
}

- (void)saveSuppressedNativeDisplays {
    @synchronized (self) {
        [CTPreferences putObject:[self.suppressedNativeDisplays copy]
                          forKey:[self storageKeyWithSuffix:CLTAP_ND_SUPPRESSED_STORAGE_KEY]];
    }
}

// Same key order as CTInAppEvaluationManager. That order is accountId:suffix:deviceId.
- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.accountId, suffix, self.deviceId];
}

#pragma mark SwitchUser delegate

- (void)deviceIdDidChange:(NSString *)newDeviceId {
    @synchronized (self) {
        self.deviceId = newDeviceId;
        // Anything still waiting belongs to the old user. We leave it under their key. It must not
        // be sent under the new user's key.
        [self loadPendingLists];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.accountId, self.deviceId];
}

@end
