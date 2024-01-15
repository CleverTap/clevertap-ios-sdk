#import "CTInAppFCManager.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTInAppNotification.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTInAppFCManager+Legacy.h"
#import "CTImpressionManager.h"
#import "CTInAppEvaluationManager.h"
#import "CleverTapInternal.h"
#import "CTMultiDelegateManager.h"
#import "CTLimitsMatcher.h"

// Per session
//  1. Show only 10 inapps per session
//  2. Show inapp X only 4 times a session
//  3. Once a inapp has been dismissed (using the close button), don't show it anymore
//
// Lifetime
//  1. Show inapp X only twice per user
//
// Daily
//  1. Show only 7 inapps in a day
//  2. Show inapp X n times a day
//
// Exclude support
//  1. Show inapp X regardless of any of the above (but respect the close button per session case)

@interface CTInAppFCManager (){}

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (atomic, copy) NSString *deviceId;

@property (atomic, strong) CTImpressionManager *impressionManager;

@property (atomic, strong) CTLimitsMatcher *limitsMatcher;
@property (atomic, strong) CTInAppTriggerManager *triggerManager;

// id: [todayCount, lifetimeCount]
@property (atomic, strong) NSMutableDictionary *inAppCounts;

@property (assign, readwrite) int localInAppCount;

@end

@implementation CTInAppFCManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId
             impressionManager:(CTImpressionManager *)impressionManager
           inAppTriggerManager:(CTInAppTriggerManager *)inAppTriggerManager {
    if (self = [super init]) {
        _config = config;
        _deviceId = deviceId;
        _impressionManager = impressionManager;
        _limitsMatcher = [[CTLimitsMatcher alloc] init];
        _triggerManager = inAppTriggerManager;
        
        [delegateManager addSwitchUserDelegate:self];
        [delegateManager addAttachToHeaderDelegate:self];
        
        [self migratePreferenceKeys];
        // Init in-app counts after migrating the preference keys
        [self initInAppCounts];
        [self checkUpdateDailyLimits];
    }
    return self;
}

- (void)initInAppCounts {
    _inAppCounts = [[CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY]] mutableCopy];
    if (_inAppCounts == nil) {
        _inAppCounts = [NSMutableDictionary new];
    }
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.config.accountId, suffix, self.deviceId];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.config.accountId, self.deviceId];
}

#pragma mark Session, Daily and Global limits
- (void)checkUpdateDailyLimits {
    NSString *today = [self todaysFormattedDate];
    if ([self shouldResetDailyCounters:today]) {
        [self resetDailyCounters:today];
    }
}

- (int)globalSessionMax {
    return (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_SESSION_MAX_KEY] withResetValue:1];
}

- (int)maxPerDayCount {
    return (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_MAX_PER_DAY_KEY] withResetValue:1];
}

- (int)shownTodayCount {
    return (int) [CTPreferences getIntForKey:
                  [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY] withResetValue:0];
}

- (BOOL)hasSessionCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return NO;
     
    // 1. Has the session max count for this inapp been breached?
    int inAppMaxPerSession = inapp.maxPerSession >= 0 ? inapp.maxPerSession : 1000;
    int inAppPerSession = (int)[self.impressionManager perSession:inapp.Id];
    if (inAppPerSession > 0 && inAppPerSession >= inAppMaxPerSession) {
        return YES;
    }
    
    // 2. Have we shown enough of in-apps this session?
    int globalSessionMax = [self globalSessionMax];
    int shownThisSession = (int) [[self impressionManager] perSessionTotal];
    if (shownThisSession >= globalSessionMax) return YES;
    
    // Session capacity has not been breached
    return NO;
}

- (BOOL)hasLifetimeCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return false;
    int inappLifetimeCount = inapp.totalLifetimeCount;
    if (inappLifetimeCount == -1) return false;
    
    NSArray *counts = self.inAppCounts[inapp.Id];
    return [counts[1] intValue] >= inappLifetimeCount;
}

- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return NO;
    
    // 1. Has the daily count maxed out globally?
    int shownTodayCount = [self shownTodayCount];
    int maxPerDayCount = [self maxPerDayCount];
    if (shownTodayCount >= maxPerDayCount) return YES;
    
    // 2. Has the daily count been maxed out for this inapp?
    int maxPerDay = inapp.totalDailyCount;
    if (maxPerDay == -1) return NO;
    
    NSArray *counts = self.inAppCounts[inapp.Id];
    if ([counts[0] intValue] >= maxPerDay) return YES;
    
    return NO;
}

- (BOOL)hasInAppFrequencyLimitsMaxedOut:(CTInAppNotification *)inApp {
    if (inApp.jsonDescription && inApp.jsonDescription[CLTAP_INAPP_FC_LIMITS]) {
        // Match frequency limits
        NSArray *frequencyLimits = inApp.jsonDescription[CLTAP_INAPP_FC_LIMITS];
        BOOL matchesLimits = [self.limitsMatcher matchWhenLimits:frequencyLimits forCampaignId:inApp.Id
                                           withImpressionManager:self.impressionManager andTriggerManager:self.triggerManager];
        return !matchesLimits;
    }
    return NO;
}

- (BOOL)canShow:(CTInAppNotification *)inapp {
    NSString *key = inapp.Id;
    if (!key) {
        return true;
    }
    
    // Evaluate frequency limits again (without Nth triggers)
    // in case the message was added multiple times before being displayed,
    // or queue was paused and the message was added multiple times in the meantime
    if ([self hasInAppFrequencyLimitsMaxedOut:inapp]) {
        return false;
    }
    
    // Exclude from all caps?
    if (inapp.excludeFromCaps) return true;
    if (![self hasSessionCapacityMaxedOut:inapp]
        && ![self hasLifetimeCapacityMaxedOut:inapp]
        && ![self hasDailyCapacityMaxedOut:inapp]) {
        return true;
    }
    return false;
}

- (void)didShow:(CTInAppNotification *)inapp {
    if (!inapp.Id) return;
    [self recordImpression:inapp.Id];
}

- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession {
    [CTPreferences putInt:perDay forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_MAX_PER_DAY_KEY]];
    [CTPreferences putInt:perSession forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_SESSION_MAX_KEY]];
}

- (void)removeStaleInAppCounts:(NSArray *)staleInApps {
    if ([staleInApps isKindOfClass:[NSArray class]]) {
        @try {
            @synchronized (self.inAppCounts) {
                for (int i = 0; i < [staleInApps count]; i++) {
                    NSString *inAppId = [NSString stringWithFormat:@"%@", staleInApps[i]];
                    // Remove stale in-app counts, triggers and impressions
                    [self.inAppCounts removeObjectForKey:inAppId];
                    [self.impressionManager removeImpressions:inAppId];
                    [self.triggerManager removeTriggers:inAppId];
                    CleverTapLogInternal(self.config.logLevel, @"%@: Purged inapp counts, triggers, and impressions with key %@", self, inAppId);
                }
                [CTPreferences putObject:self.inAppCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY]];
            }
        } @catch (NSException *e) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Failed to purge out stale in-app counts - %@", self, e.debugDescription);
        }
    }
}

- (NSString *)todaysFormattedDate {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:CLTAP_DATE_FORMAT];
    return [formatter stringFromDate:[NSDate date]];
}

- (BOOL)shouldResetDailyCounters:(NSString *)today {
    NSString *lastUpdate = [CTPreferences getStringForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_LAST_DATE_KEY] withResetValue:@"20140428"];
    return ![today isEqualToString:lastUpdate];
}

- (void)resetDailyCounters:(NSString *)today {
    // Dates have changed
    [CTPreferences putString:today forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_LAST_DATE_KEY]];
    
    // Reset today count
    [CTPreferences putInt:0 forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY]];
    
    // Reset the counts for each inapp
    @synchronized (self.inAppCounts) {
        NSArray *keys = [self.inAppCounts allKeys];
        for (int i = 0; i < keys.count; ++i) {
            NSMutableArray *counts = [self.inAppCounts[keys[i]] mutableCopy];
            if (!counts || [counts count] != 2) {
                [self.inAppCounts removeObjectForKey:keys[i]];
                continue;
            }
            // protocol: todayCount, lifetimeCount
            counts[0] = @0;
            self.inAppCounts[keys[i]] = counts;
        }
        [CTPreferences putObject:self.inAppCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY]];
    }
}

- (void)recordImpression:(NSString *)inAppId {
    // Record impression for limits
    // Record impression for session
    [self.impressionManager recordImpression:inAppId];
    
    // Record impression for day
    [self incrementShownToday];
    
    // Record impression in tlc counts
    @synchronized (self.inAppCounts) {
        NSMutableArray *counts = [self.inAppCounts[inAppId] mutableCopy];
        if (!counts) {
            counts = [[NSMutableArray alloc] initWithObjects:@1, @1, nil];
        } else {
            // protocol: todayCount, lifetimeCount
            counts[0] = @([counts[0] intValue] + 1);
            counts[1] = @([counts[1] intValue] + 1);
        }
        
        self.inAppCounts[inAppId] = counts;
        [CTPreferences putObject:self.inAppCounts forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY]];
    }
}

- (void)incrementShownToday {
    int shownToday = [self shownTodayCount];
    [CTPreferences putInt:shownToday + 1 forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY]];
}

- (void)incrementLocalInAppCount {
    self.localInAppCount = self.localInAppCount + 1;
    [CTPreferences putInt:self.localInAppCount forKey:CLTAP_PREFS_INAPP_LOCAL_INAPP_COUNT_KEY];
}

- (int)getLocalInAppCount {
    self.localInAppCount = (int) [CTPreferences getIntForKey:CLTAP_PREFS_INAPP_LOCAL_INAPP_COUNT_KEY withResetValue:0];
    return self.localInAppCount;
}

#pragma mark Switch User Delegate
- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceId = newDeviceId;
    [self migratePreferenceKeys];
    [self initInAppCounts];
}

#pragma mark AttachToBatchHeader delegate
- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
    NSMutableDictionary *header = [NSMutableDictionary new];
    @try {
        header[CLTAP_INAPP_SHOWN_TODAY_META_KEY] = @([self shownTodayCount]);

        NSMutableArray *arr = [NSMutableArray new];
        NSArray *keys = [self.inAppCounts allKeys];
        for (NSUInteger i = 0; i < keys.count; ++i) {
            NSArray *counts = self.inAppCounts[keys[i]];
            if (counts.count == 2) {
                // tlc: [[targetID, todayCount, lifetime]]
                [arr addObject:@[keys[i], counts[0], counts[1]]];
            }
        }
        
        header[@"af.LIAMC"] = @([self localInAppCount]);
        
        header[CLTAP_INAPP_COUNTS_META_KEY] = arr;
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach FC to header: %@", self, e.debugDescription);
    }
    return header;
}

@end
