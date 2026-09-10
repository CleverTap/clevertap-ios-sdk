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

// The server sends -1 to mean no limit. That is true for every count here, per campaign and
// account-wide.
static const int kCTNdUncapped = -1;

@interface CTNdFCManager ()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (atomic, copy) NSString *deviceId;

@property (atomic, strong) CTImpressionManager *impressionManager;
@property (atomic, strong) CTInAppTriggerManager *triggerManager;

/// campaign id -> a two item array, today's count then the lifetime count.
@property (atomic, strong) NSMutableDictionary *campaignCounts;

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

        [self initCampaignCounts];
        [self checkUpdateDailyLimits];
    }
    return self;
}

- (void)initCampaignCounts {
    id saved = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_CAMPAIGN_KEY]];
    if ([saved isKindOfClass:[NSDictionary class]]) {
        _campaignCounts = [saved mutableCopy];
    } else {
        _campaignCounts = [NSMutableDictionary new];
    }
}

// Same key order as CTInAppFCManager. That order is accountId:suffix:deviceId. CTInAppStore uses a
// different order. Each class copies the one it is based on.
- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.config.accountId, suffix, self.deviceId];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.config.accountId, self.deviceId];
}

#pragma mark Which accounts have caps

- (BOOL)hasAccountCaps {
    return [self globalSessionMax] != kCTNdUncapped || [self maxPerDayCount] != kCTNdUncapped;
}

+ (NSString *)campaignIdFrom:(NSDictionary *)unit {
    if (![unit isKindOfClass:[NSDictionary class]]) return @"";

    id campaignId = unit[CLTAP_INAPP_ID];
    if ([campaignId isKindOfClass:[NSString class]]) return campaignId;
    // The server sends ti as a number in the content payload and as a string in other payloads.
    if ([campaignId isKindOfClass:[NSNumber class]]) return [campaignId stringValue];
    return @"";
}

#pragma mark Session, Daily and Global limits

- (void)checkUpdateDailyLimits {
    NSString *today = [self todaysFormattedDate];
    if ([self shouldResetDailyCounters:today]) {
        [self resetDailyCounters:today];
    }
}

// No limit until the server sends one. ndmc and ndmp are new keys. A response may not carry them
// at all. A default of 1 would then hold every account to one unit per session and one per day.
// In-app defaults these to 1. In-app can do that because imc and imp are on every response.
- (int)globalSessionMax {
    return (int)[CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_SESSION_MAX_KEY] withResetValue:kCTNdUncapped];
}

- (int)maxPerDayCount {
    return (int)[CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_MAX_PER_DAY_KEY] withResetValue:kCTNdUncapped];
}

- (int)shownTodayCount {
    return (int)[CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_SHOWN_TODAY_KEY] withResetValue:0];
}

- (BOOL)hasSessionCapacityMaxedOut:(NSString *)campaignId
                     maxPerSession:(int)maxPerSession
                 excludeGlobalCaps:(BOOL)excludeGlobalCaps {
    // 1. Has this campaign hit its own session cap? excludeGlobalFCaps does not skip this one.
    // Native Display never sends mdc, so this check is skipped every time today. The parameter is
    // kept for a caller that does send one.
    if (maxPerSession != kCTNdUncapped
        && [self.impressionManager perSession:campaignId] >= maxPerSession) {
        return YES;
    }

    // 2. Has the account hit its session cap? This one is account-wide. excludeGlobalFCaps skips
    // it.
    if (excludeGlobalCaps) return NO;
    int globalSessionMax = [self globalSessionMax];
    if (globalSessionMax == kCTNdUncapped) return NO;
    return [self.impressionManager perSessionTotal] >= globalSessionMax;
}

- (BOOL)hasLifetimeCapacityMaxedOut:(NSString *)campaignId totalLifetimeCount:(int)totalLifetimeCount {
    if (totalLifetimeCount == kCTNdUncapped) return NO;
    return [self lifetimeCountForCampaign:campaignId] >= totalLifetimeCount;
}

- (BOOL)hasDailyCapacityMaxedOut:(NSString *)campaignId
                 totalDailyCount:(int)totalDailyCount
               excludeGlobalCaps:(BOOL)excludeGlobalCaps {
    // 1. Has the account hit its daily cap? This one is account-wide. excludeGlobalFCaps skips it.
    if (!excludeGlobalCaps) {
        int maxPerDayCount = [self maxPerDayCount];
        if (maxPerDayCount != kCTNdUncapped && [self shownTodayCount] >= maxPerDayCount) {
            return YES;
        }
    }

    // 2. Has this campaign hit its own daily cap? excludeGlobalFCaps does not skip this one.
    if (totalDailyCount == kCTNdUncapped) return NO;
    return [self todayCountForCampaign:campaignId] >= totalDailyCount;
}

- (BOOL)canShowCampaign:(NSString *)campaignId
        excludeFromCaps:(BOOL)excludeFromCaps
      excludeGlobalCaps:(BOOL)excludeGlobalCaps
     totalLifetimeCount:(int)totalLifetimeCount
        totalDailyCount:(int)totalDailyCount
          maxPerSession:(int)maxPerSession {
    if (![campaignId isKindOfClass:[NSString class]] || campaignId.length == 0) {
        return YES;
    }

    // efc skips every cap. We can answer here. excludeGlobalFCaps cannot be answered here. It skips
    // only the two account caps. The campaign still has to obey its own tlc, tdc and mdc. That is
    // why it is passed down to each check instead.
    if (excludeFromCaps) return YES;

    return ![self hasSessionCapacityMaxedOut:campaignId
                               maxPerSession:maxPerSession
                           excludeGlobalCaps:excludeGlobalCaps]
        && ![self hasLifetimeCapacityMaxedOut:campaignId totalLifetimeCount:totalLifetimeCount]
        && ![self hasDailyCapacityMaxedOut:campaignId
                           totalDailyCount:totalDailyCount
                         excludeGlobalCaps:excludeGlobalCaps];
}

- (void)didShowCampaign:(NSString *)campaignId storeTimestamp:(BOOL)storeTimestamp {
    if (![campaignId isKindOfClass:[NSString class]] || campaignId.length == 0) return;

    // Record the impression. Session counts always go up. The time is saved only when asked for.
    // Only frequencyLimits and occurrenceLimits ever read it.
    [self.impressionManager recordImpression:campaignId storeTimestamp:storeTimestamp];

    // Add to the total shown today.
    [self incrementShownToday];

    // Add to this campaign's own daily and lifetime counts.
    @synchronized (self.campaignCounts) {
        NSMutableArray *counts = [self.campaignCounts[campaignId] mutableCopy];
        if (!counts || counts.count != 2) {
            counts = [[NSMutableArray alloc] initWithObjects:@1, @1, nil];
        } else {
            // The two values are today's count then the lifetime count.
            counts[0] = @([counts[0] intValue] + 1);
            counts[1] = @([counts[1] intValue] + 1);
        }
        self.campaignCounts[campaignId] = counts;
        [CTPreferences putObject:self.campaignCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_CAMPAIGN_KEY]];
    }
}

- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession {
    [CTPreferences putInt:perDay forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_MAX_PER_DAY_KEY]];
    [CTPreferences putInt:perSession forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_SESSION_MAX_KEY]];
}

- (void)removeStaleCampaignCounts:(NSArray *)staleCampaigns {
    if (![staleCampaigns isKindOfClass:[NSArray class]]) return;

    @try {
        @synchronized (self.campaignCounts) {
            for (id stale in staleCampaigns) {
                NSString *campaignId = [NSString stringWithFormat:@"%@", stale];
                // Counts, impressions and triggers are all stored under the campaign id. All three
                // go. Removing only the counts would leave the other two on disk forever.
                [self.campaignCounts removeObjectForKey:campaignId];
                [self.impressionManager removeImpressions:campaignId];
                [self.triggerManager removeTriggers:campaignId];
                CleverTapLogInternal(self.config.logLevel, @"%@: Removed counts, triggers and impressions for Native Display campaign %@", self, campaignId);
            }
            [CTPreferences putObject:self.campaignCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_CAMPAIGN_KEY]];
        }
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to remove old Native Display counts - %@", self, e.debugDescription);
    }
}

#pragma mark Counts

- (int)todayCountForCampaign:(NSString *)campaignId {
    @synchronized (self.campaignCounts) {
        NSArray *counts = self.campaignCounts[campaignId];
        return counts.count == 2 ? [counts[0] intValue] : 0;
    }
}

- (int)lifetimeCountForCampaign:(NSString *)campaignId {
    @synchronized (self.campaignCounts) {
        NSArray *counts = self.campaignCounts[campaignId];
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

    @synchronized (self.campaignCounts) {
        NSArray *keys = [self.campaignCounts allKeys];
        for (NSString *key in keys) {
            NSMutableArray *counts = [self.campaignCounts[key] mutableCopy];
            if (!counts || counts.count != 2) {
                [self.campaignCounts removeObjectForKey:key];
                continue;
            }
            // The two values are today's count then the lifetime count. Lifetime is not reset.
            counts[0] = @0;
            self.campaignCounts[key] = counts;
        }
        [CTPreferences putObject:self.campaignCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_ND_COUNTS_PER_CAMPAIGN_KEY]];
    }
}

#pragma mark Switch User Delegate

- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceId = newDeviceId;
    [self initCampaignCounts];
    [self checkUpdateDailyLimits];
}

#pragma mark AttachToBatchHeader delegate

- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
    NSMutableDictionary *header = [NSMutableDictionary new];
    @try {
        // Check the date first. The day may have changed since the last count. The server applies
        // the caps from these numbers. Yesterday's totals would hide units the user should see
        // today.
        [self checkUpdateDailyLimits];

        header[CLTAP_ND_SHOWN_TODAY_META_KEY] = @([self shownTodayCount]);

        NSMutableArray *arr = [NSMutableArray new];
        @synchronized (self.campaignCounts) {
            for (NSString *key in [self.campaignCounts allKeys]) {
                NSArray *counts = self.campaignCounts[key];
                if (counts.count == 2) {
                    // ndtlc: [[campaign id, today's count, lifetime count], ...]
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
