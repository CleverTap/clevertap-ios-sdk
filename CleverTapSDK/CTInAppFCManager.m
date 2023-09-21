#import "CTInAppFCManager.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTInAppNotification.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTInAppFCManager+Legacy.h"
#import "CTImpressionManager.h"

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

// Storage keys
NSString* const kKEY_COUNTS_PER_INAPP = @"counts_per_inapp";
NSString* const kKEY_COUNTS_SHOWN_TODAY = @"istc_inapp";
NSString* const kKEY_MAX_PER_DAY = @"istmcd_inapp";

@interface CTInAppFCManager (){}

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (atomic, copy) NSString *deviceId;

@property (atomic, strong) CTImpressionManager *impressionManager;

// id: [todayCount, lifetimeCount]
@property (atomic, strong) NSMutableDictionary *inAppCounts;

@end

@implementation CTInAppFCManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceId:(NSString *)deviceId {
    if (self = [super init]) {
        _config = config;
        _deviceId = deviceId;
        
        // TODO: init properly
        _impressionManager = [CTImpressionManager new];
        
        _inAppCounts = [[CTPreferences getObjectForKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]] mutableCopy];
        if (_inAppCounts == nil) {
            _inAppCounts = [NSMutableDictionary new];
        }
        
        [self migratePreferenceKeys];
        [self checkUpdateDailyLimits];
    }
    return self;
}

- (NSString *)storageKeyWithSuffix: (NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.config.accountId, suffix, self.deviceId];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.config.accountId, self.deviceId];
}

- (void)checkUpdateDailyLimits {
    NSString *today = [self todaysFormattedDate];
    if ([self shouldResetDailyCounters:today]) {
        [self resetDailyCounters:today];
    }
}

// TODO: use new counts
// TODO: create a new instance of the manager?
- (void)changeUserWithGuid:(NSString *)guid {
    _deviceId = guid;
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
    int globalSessionMax = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SESSION_MAX] withResetValue:1];
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
                                 [self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:0];
    int maxPerDayCount = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_MAX_PER_DAY] withResetValue:1];
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
    [CTPreferences putInt:perDay forKey:[self storageKeyWithSuffix:kKEY_MAX_PER_DAY]];
    [CTPreferences putInt:perSession forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SESSION_MAX]];
}

- (void)attachToHeader:(NSMutableDictionary *)header {
    @try {
        header[@"imp"] = @([CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:0]);

        NSMutableArray *arr = [NSMutableArray new];
        NSArray *keys = [self.inAppCounts allKeys];
        for (NSUInteger i = 0; i < keys.count; ++i) {
            NSArray *counts = self.inAppCounts[keys[i]];
            if (counts.count == 2) {
                // tlc: [[targetID, todayCount, lifetime]]
                [arr addObject:@[keys[i], counts[0], counts[1]]];
            }
        }
        
        header[@"tlc"] = arr;
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach FC to header: %@", self, e.debugDescription);
    }
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
                [CTPreferences putObject:self.inAppCounts forKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
            }
        } @catch (NSException *e) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Failed to purge out stale in-app counts - %@", self, e.debugDescription);
        }
    }
}

- (NSString *)todaysFormattedDate {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyyMMdd";
    return [formatter stringFromDate:[NSDate date]];
}

- (BOOL)shouldResetDailyCounters:(NSString *)today {
    NSString *lastUpdate = [CTPreferences getStringForKey:[self storageKeyWithSuffix:@"ict_date"] withResetValue:@"20140428"];
    return ![today isEqualToString:lastUpdate];
}

- (void)resetDailyCounters:(NSString *)today {
    // Dates have changed
    [CTPreferences putString:today forKey:[self storageKeyWithSuffix:@"ict_date"]];
    
    // Reset today count
    [CTPreferences putInt:0 forKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY]];
    
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
        [CTPreferences putObject:self.inAppCounts forKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
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
        [CTPreferences putObject:self.inAppCounts forKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
    }
}

- (void)incrementShownToday {
    int shownToday = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:0];
    [CTPreferences putInt:shownToday + 1 forKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY]];
}

@end
