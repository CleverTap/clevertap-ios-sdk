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
@property (atomic, weak) CTInAppEvaluationManager *evaluationManager;

// id: [todayCount, lifetimeCount]
@property (atomic, strong) NSMutableDictionary *inAppCounts;

@property (assign, readwrite) int localInAppCount;

@end

@implementation CTInAppFCManager

- (instancetype)initWithInstance:(CleverTap *)instance
                      deviceId:(NSString *)deviceId
             evaluationManager: (CTInAppEvaluationManager *)evaluationManager impressionManager:(CTImpressionManager *)impressionManager {
    if (self = [super init]) {
        _config = instance.config;
        _deviceId = deviceId;
        _impressionManager = impressionManager;
        _evaluationManager = evaluationManager;
        
        [instance addAttachToHeaderDelegate:self];
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

- (NSString *)storageKeyWithSuffix: (NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.config.accountId, suffix, self.deviceId];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.config.accountId, self.deviceId];
}

#pragma mark Switch User Delegate
- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceId = newDeviceId;
    [self migratePreferenceKeys];
    [self initInAppCounts];
}

- (void)checkUpdateDailyLimits {
    NSString *today = [self todaysFormattedDate];
    if ([self shouldResetDailyCounters:today]) {
        [self resetDailyCounters:today];
    }
}

- (BOOL)hasSessionCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return false;
    
    // 1. Has the session max count for this inapp been breached?
    int inAppMaxPerSession = inapp.maxPerSession >= 0 ? inapp.maxPerSession : 1000;
    int inAppPerSession = (int)[self.impressionManager perSession:inapp.Id];
    if (inAppPerSession >= inAppMaxPerSession) {
        return YES;
    }
    
    // 2. Have we shown enough of in-apps this session?
    int globalSessionMax = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_SESSION_MAX_KEY] withResetValue:1];
    int shownThisSession = (int) [[self impressionManager] perSessionTotal];
    if (shownThisSession >= globalSessionMax) return true;
    
    // Session capacity has not been breached
    return false;
}

- (BOOL)hasLifetimeCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return false;
    int inappLifetimeCount = inapp.totalLifetimeCount;
    if (inappLifetimeCount == -1) return false;
    
    NSArray *counts = self.inAppCounts[inapp.Id];
    return [counts[1] intValue] >= inappLifetimeCount;
}

- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return false;
    
    // 1. Has the daily count maxed out globally?
    int shownTodayCount = (int) [CTPreferences getIntForKey:
                                 [self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY] withResetValue:0];
    int maxPerDayCount = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_MAX_PER_DAY_KEY] withResetValue:1];
    if (shownTodayCount >= maxPerDayCount) return true;
    
    // 2. Has the daily count been maxed out for this inapp?
    int maxPerDay = inapp.totalDailyCount;
    if (maxPerDay == -1) return false;
    
    NSArray *counts = self.inAppCounts[inapp.Id];
    if ([counts[0] intValue] >= maxPerDay) return true;
    
    return false;
}

- (BOOL)canShow:(CTInAppNotification *)inapp {
    NSString *key = inapp.Id;
    if (!key) {
        return true;
    }
    // Evaluate freqency limits again (without Nth triggers)
    // in case queue the message was added multiple times before being displayed
    // or queue was paused and the message was added multiple times in the meantime
    if (![self.evaluationManager evaluateInAppFrequencyLimits:inapp]) {
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
                    NSString *key = [NSString stringWithFormat:@"%@", staleInApps[i]];
                    [self.inAppCounts removeObjectForKey:key];
                    CleverTapLogInternal(self.config.logLevel, @"%@: Purged inapp counts with key %@", self, key);
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
    // TODO: check for day change here?
    
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
    int shownToday = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY] withResetValue:0];
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

- (nonnull NSDictionary<NSString *,id> *)onBatchHeaderCreation {
    NSMutableDictionary *header = [NSMutableDictionary new];
    @try {
        header[CLTAP_INAPP_SHOWN_TODAY_META_KEY] = @([CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY] withResetValue:0]);

        NSMutableArray *arr = [NSMutableArray new];
        NSArray *keys = [self.inAppCounts allKeys];
        for (NSUInteger i = 0; i < keys.count; ++i) {
            NSArray *counts = self.inAppCounts[keys[i]];
            if (counts.count == 2) {
                // tlc: [[targetID, todayCount, lifetime]]
                [arr addObject:@[keys[i], counts[0], counts[1]]];
            }
        }
        
        header[CLTAP_INAPP_COUNTS_META_KEY] = arr;
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach FC to header: %@", self, e.debugDescription);
    }
    return header;
}

@end
