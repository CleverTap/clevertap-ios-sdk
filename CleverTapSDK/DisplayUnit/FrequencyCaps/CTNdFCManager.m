//
//  CTNdFCManager.m
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import "CTNdFCManager.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTImpressionManager.h"
#import "CTInAppTriggerManager.h"
#import "CleverTapInternal.h"
#import "CTMultiDelegateManager.h"

// -1 is how the server says "no limit" for every count in this file, per-target and account-wide.
static const int kCTNdUncapped = -1;

// Used when a target sets no mdc of its own. Same value in-app uses, high enough to be no limit in
// practice while still being a number the comparison can use.
static const int kCTNdSessionCapDefault = 1000;

@interface CTNdFCManager ()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (atomic, copy) NSString *deviceId;

@property (atomic, strong) CTImpressionManager *impressionManager;
@property (atomic, strong) CTInAppTriggerManager *triggerManager;

/// targetId -> [todayCount, lifetimeCount]
@property (atomic, strong) NSMutableDictionary *targetCounts;

@end

@implementation CTNdFCManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId
             impressionManager:(CTImpressionManager *)impressionManager
                triggerManager:(CTInAppTriggerManager *)triggerManager {
    if (self = [super init]) {
        _config = config;
        _deviceId = deviceId;
        _impressionManager = impressionManager;
        _triggerManager = triggerManager;

        [delegateManager addSwitchUserDelegate:self];
        [delegateManager addAttachToHeaderDelegate:self];

        [self initTargetCounts];
        [self checkUpdateDailyLimits];
    }
    return self;
}

- (void)initTargetCounts {
    id saved = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_TARGET_KEY]];
    if ([saved isKindOfClass:[NSDictionary class]]) {
        _targetCounts = [saved mutableCopy];
    } else {
        _targetCounts = [NSMutableDictionary new];
    }
}

// Matches the ordering CTInAppFCManager uses, which is accountId:suffix:deviceId. CTInAppStore
// orders it differently, so each class follows the one it mirrors.
- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.config.accountId, suffix, self.deviceId];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.config.accountId, self.deviceId];
}

#pragma mark Cap-Managed Units

+ (BOOL)isFcapManaged:(NSDictionary *)unit {
    if (![unit isKindOfClass:[NSDictionary class]]) return NO;

    return unit[CLTAP_INAPP_EXCLUDE_FROM_CAPS] != nil
        || unit[CLTAP_INAPP_TOTAL_LIFETIME_COUNT] != nil
        || unit[CLTAP_INAPP_TOTAL_DAILY_COUNT] != nil
        || unit[CLTAP_INAPP_MAX_PER_SESSION] != nil
        || unit[CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS] != nil;
}

#pragma mark Session, Daily and Global limits

- (void)checkUpdateDailyLimits {
    NSString *today = [self todaysFormattedDate];
    if ([self shouldResetDailyCounters:today]) {
        [self resetDailyCounters:today];
    }
}

- (int)globalSessionMax {
    return (int)[CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_SESSION_MAX_KEY] withResetValue:1];
}

- (int)maxPerDayCount {
    return (int)[CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_MAX_PER_DAY_KEY] withResetValue:1];
}

- (int)shownTodayCount {
    return (int)[CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_SHOWN_TODAY_KEY] withResetValue:0];
}

- (BOOL)hasSessionCapacityMaxedOut:(NSString *)targetId
                     maxPerSession:(int)maxPerSession
                 excludeGlobalCaps:(BOOL)excludeGlobalCaps {
    // 1. Has this target hit its own session count? excludeGlobalFCaps does not skip this one.
    int perSessionMax = maxPerSession >= 0 ? maxPerSession : kCTNdSessionCapDefault;
    if ([self.impressionManager perSession:targetId] >= perSessionMax) {
        return YES;
    }

    // 2. Have we shown enough Native Display units this session? This is account-wide, so
    // excludeGlobalFCaps skips it.
    if (excludeGlobalCaps) return NO;
    int globalSessionMax = [self globalSessionMax];
    if (globalSessionMax == kCTNdUncapped) return NO;
    return [self.impressionManager perSessionTotal] >= globalSessionMax;
}

- (BOOL)hasLifetimeCapacityMaxedOut:(NSString *)targetId totalLifetimeCount:(int)totalLifetimeCount {
    if (totalLifetimeCount == kCTNdUncapped) return NO;
    return [self lifetimeCountForTarget:targetId] >= totalLifetimeCount;
}

- (BOOL)hasDailyCapacityMaxedOut:(NSString *)targetId
                 totalDailyCount:(int)totalDailyCount
               excludeGlobalCaps:(BOOL)excludeGlobalCaps {
    // 1. Has the account's daily count maxed out? Account-wide, so excludeGlobalFCaps skips it.
    if (!excludeGlobalCaps) {
        int maxPerDayCount = [self maxPerDayCount];
        if (maxPerDayCount != kCTNdUncapped && [self shownTodayCount] >= maxPerDayCount) {
            return YES;
        }
    }

    // 2. Has this target hit its own daily count? excludeGlobalFCaps does not skip this one.
    if (totalDailyCount == kCTNdUncapped) return NO;
    return [self todayCountForTarget:targetId] >= totalDailyCount;
}

- (BOOL)canShowTarget:(NSString *)targetId
      excludeFromCaps:(BOOL)excludeFromCaps
    excludeGlobalCaps:(BOOL)excludeGlobalCaps
   totalLifetimeCount:(int)totalLifetimeCount
      totalDailyCount:(int)totalDailyCount
        maxPerSession:(int)maxPerSession {
    if (![targetId isKindOfClass:[NSString class]] || targetId.length == 0) {
        return YES;
    }

    // efc skips all the caps, so we can answer right here. excludeGlobalFCaps cannot do that,
    // because it skips only the two account-wide caps and the target still has to obey its own
    // tlc, tdc and mdc. That is why it is passed down to the checks instead.
    if (excludeFromCaps) return YES;

    return ![self hasSessionCapacityMaxedOut:targetId
                               maxPerSession:maxPerSession
                           excludeGlobalCaps:excludeGlobalCaps]
        && ![self hasLifetimeCapacityMaxedOut:targetId totalLifetimeCount:totalLifetimeCount]
        && ![self hasDailyCapacityMaxedOut:targetId
                           totalDailyCount:totalDailyCount
                         excludeGlobalCaps:excludeGlobalCaps];
}

- (void)didShowTarget:(NSString *)targetId storeTimestamp:(BOOL)storeTimestamp {
    if (![targetId isKindOfClass:[NSString class]] || targetId.length == 0) return;

    // Record the impression. This always feeds the session counts, and when asked for it also saves
    // the timestamp that frequencyLimits and occurrenceLimits are matched against.
    [self.impressionManager recordImpression:targetId storeTimestamp:storeTimestamp];

    // Add to the total shown today.
    [self incrementShownToday];

    // Add to this target's own today and lifetime counts.
    @synchronized (self.targetCounts) {
        NSMutableArray *counts = [self.targetCounts[targetId] mutableCopy];
        if (!counts || counts.count != 2) {
            counts = [[NSMutableArray alloc] initWithObjects:@1, @1, nil];
        } else {
            // The two values are todayCount then lifetimeCount.
            counts[0] = @([counts[0] intValue] + 1);
            counts[1] = @([counts[1] intValue] + 1);
        }
        self.targetCounts[targetId] = counts;
        [CTPreferences putObject:self.targetCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_TARGET_KEY]];
    }
}

- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession {
    [CTPreferences putInt:perDay forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_MAX_PER_DAY_KEY]];
    [CTPreferences putInt:perSession forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_SESSION_MAX_KEY]];
}

- (void)removeStaleTargetCounts:(NSArray *)staleTargets {
    if (![staleTargets isKindOfClass:[NSArray class]]) return;

    @try {
        @synchronized (self.targetCounts) {
            for (id stale in staleTargets) {
                NSString *targetId = [NSString stringWithFormat:@"%@", stale];
                // Counts, impressions and triggers all key off the target id, so all three go.
                // Dropping only the counts would leave the other two on disk for good.
                [self.targetCounts removeObjectForKey:targetId];
                [self.impressionManager removeImpressions:targetId];
                [self.triggerManager removeTriggers:targetId];
                CleverTapLogInternal(self.config.logLevel, @"%@: Purged Native Display counts, triggers, and impressions with key %@", self, targetId);
            }
            [CTPreferences putObject:self.targetCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_TARGET_KEY]];
        }
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to purge out stale Native Display counts - %@", self, e.debugDescription);
    }
}

#pragma mark Counts

- (int)todayCountForTarget:(NSString *)targetId {
    @synchronized (self.targetCounts) {
        NSArray *counts = self.targetCounts[targetId];
        return counts.count == 2 ? [counts[0] intValue] : 0;
    }
}

- (int)lifetimeCountForTarget:(NSString *)targetId {
    @synchronized (self.targetCounts) {
        NSArray *counts = self.targetCounts[targetId];
        return counts.count == 2 ? [counts[1] intValue] : 0;
    }
}

- (void)incrementShownToday {
    [CTPreferences putInt:[self shownTodayCount] + 1 forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_SHOWN_TODAY_KEY]];
}

#pragma mark Daily Reset

- (NSString *)todaysFormattedDate {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:CLTAP_DATE_FORMAT];
    return [formatter stringFromDate:[NSDate date]];
}

- (BOOL)shouldResetDailyCounters:(NSString *)today {
    NSString *lastUpdate = [CTPreferences getStringForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_LAST_DATE_KEY] withResetValue:@"20140428"];
    return ![today isEqualToString:lastUpdate];
}

- (void)resetDailyCounters:(NSString *)today {
    [CTPreferences putString:today forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_LAST_DATE_KEY]];

    [CTPreferences putInt:0 forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_SHOWN_TODAY_KEY]];

    @synchronized (self.targetCounts) {
        NSArray *keys = [self.targetCounts allKeys];
        for (NSString *key in keys) {
            NSMutableArray *counts = [self.targetCounts[key] mutableCopy];
            if (!counts || counts.count != 2) {
                [self.targetCounts removeObjectForKey:key];
                continue;
            }
            // The two values are todayCount then lifetimeCount. Lifetime is not reset.
            counts[0] = @0;
            self.targetCounts[key] = counts;
        }
        [CTPreferences putObject:self.targetCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_TARGET_KEY]];
    }
}

#pragma mark Switch User Delegate

- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceId = newDeviceId;
    [self initTargetCounts];
    [self checkUpdateDailyLimits];
}

#pragma mark AttachToBatchHeader delegate

- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
    NSMutableDictionary *header = [NSMutableDictionary new];
    @try {
        header[CLTAP_ND_SHOWN_TODAY_META_KEY] = @([self shownTodayCount]);

        NSMutableArray *arr = [NSMutableArray new];
        @synchronized (self.targetCounts) {
            for (NSString *key in [self.targetCounts allKeys]) {
                NSArray *counts = self.targetCounts[key];
                if (counts.count == 2) {
                    // ndtlc: [[targetId, todayCount, lifetimeCount], ...]
                    [arr addObject:@[key, counts[0], counts[1]]];
                }
            }
        }
        header[CLTAP_ND_COUNTS_META_KEY] = arr;
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach Native Display FC to header: %@", self, e.debugDescription);
    }
    return header;
}

@end
