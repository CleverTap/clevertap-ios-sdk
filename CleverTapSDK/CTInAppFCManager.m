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

@property (atomic, strong) NSMutableDictionary *dismissedThisSession;
@property (atomic, strong) NSMutableDictionary *shownThisSession;
@property (atomic, strong) NSNumber *shownThisSessionCount;

@property (atomic, strong) CTImpressionManager *impressionManager;

// id: [todayCount, lifetimeCount]
@property (atomic, strong) NSMutableDictionary *inAppCounts;

@end

@implementation CTInAppFCManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceId:(NSString *)deviceId {
    if (self = [super init]) {
        _config = config;
        _dismissedThisSession = [NSMutableDictionary new];
        _shownThisSession = [NSMutableDictionary new];
        _shownThisSessionCount = @0;
        _deviceId = deviceId;
        
        _impressionManager = [CTImpressionManager new];
        
        _inAppCounts = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
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
    return [NSString stringWithFormat:@"CTInAppFCManager:%@:%@", self.config.accountId, self.deviceId];
}

- (void)checkUpdateDailyLimits {
    NSString *today = [self todaysFormattedDate];
    if ([self shouldResetDailyCounters:today]) {
        [self resetDailyCounters:today];
    }
}

// TODO: create a new instance of the manager?
- (void)changeUserWithGuid:(NSString *)guid {
    self.dismissedThisSession = [NSMutableDictionary new];
    self.shownThisSession = [NSMutableDictionary new];
    self.shownThisSessionCount = @0;
    _deviceId = guid;
}

- (NSArray *)getInAppCountsFromPersistentStore:(NSObject *)inappID {
    NSDictionary *countsContainer = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
    if (self.config.isDefaultInstance && !countsContainer) {
        countsContainer = [CTPreferences getObjectForKey:[NSString stringWithFormat:@"%@:%@", kKEY_COUNTS_PER_INAPP, self.deviceId]];
    }
    if (!countsContainer) {
        countsContainer = @{};
    }
    NSArray *inappCounts = countsContainer[inappID];
    if (!inappCounts || [inappCounts count] != 2) {
        // protocol: todayCount, lifetimeCount
        inappCounts = @[@0, @0];
    }
    return inappCounts;
}

- (void)incrementInAppCountsInPersistentStore:(NSObject *)inappIDObject {
    NSString *inappID = [NSString stringWithFormat:@"%@", inappIDObject];
    NSMutableArray *counts = [[self getInAppCountsFromPersistentStore:inappID] mutableCopy];
    
    // protocol: todayCount, lifetimeCount
    counts[0] = @([counts[0] intValue] + 1);
    counts[1] = @([counts[1] intValue] + 1);
    
    NSDictionary *_countsContainer = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
    if (self.config.isDefaultInstance && !_countsContainer) {
        _countsContainer = [CTPreferences getObjectForKey:[NSString stringWithFormat:@"%@:%@", kKEY_COUNTS_PER_INAPP, self.deviceId]];
    }
    NSMutableDictionary *countsContainer = _countsContainer ? [_countsContainer mutableCopy] : [NSMutableDictionary new];
    countsContainer[inappID] = counts;
    [CTPreferences putObject:countsContainer forKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
}

- (BOOL)hasSessionCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return false;
    
    
    
    // TODO: dismissedThisSession should be removed
    // 1. Has this been dismissed?
    if (self.dismissedThisSession[inapp.Id]) return true;
    
    // 2. Has the session max count for this inapp been breached?
    int inAppMaxPerSession = inapp.maxPerSession >= 0 ? inapp.maxPerSession : 1000;
    int inAppPerSession = (int)[self.impressionManager perSession:inapp.Id];
    if (inAppPerSession >= inAppMaxPerSession) {
        return YES;
    }
    
    // 3. Have we shown enough of in-apps this session?
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
    
    NSArray *counts = [self getInAppCountsFromPersistentStore:inapp.Id];
    return [counts[1] intValue] >= inappLifetimeCount;
}

- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)inapp {
    if (!inapp.Id) return false;
    NSString *inappID = inapp.Id;
    
    // 1. Has the daily count maxed out globally?
    int shownTodayCount = 0;
    if (self.config.isDefaultInstance) {
        shownTodayCount = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:[CTPreferences getIntForKey:kKEY_COUNTS_SHOWN_TODAY withResetValue:0]];
    } else {
        shownTodayCount = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:0];
    }
    int maxPerDayCount = 1;
    if (self.config.isDefaultInstance) {
        maxPerDayCount = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_MAX_PER_DAY] withResetValue:[CTPreferences getIntForKey:kKEY_MAX_PER_DAY withResetValue:1]];
    } else {
        maxPerDayCount = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_MAX_PER_DAY] withResetValue:1];
    }
    if (shownTodayCount >= maxPerDayCount) return true;
    
    // 2. Has the daily count been maxed out for this inapp?
    int maxPerDay = inapp.totalDailyCount;
    if (maxPerDay == -1) return false;
    
    NSArray *counts = [self getInAppCountsFromPersistentStore:inappID];
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

- (void)didDismiss:(CTInAppNotification *)inapp {
    if (!inapp.Id) return;
    self.dismissedThisSession[inapp.Id] = @TRUE;
}

- (void)resetSession {
    [self.dismissedThisSession removeAllObjects];
    [self.shownThisSession removeAllObjects];
    self.shownThisSessionCount = @0;
}

- (void)didShow:(CTInAppNotification *)inapp {
    if (!inapp.Id) return;
    self.shownThisSessionCount = @(self.shownThisSessionCount.intValue + 1);
    if (self.shownThisSession[inapp.Id]) {
        self.shownThisSession[inapp.Id] = @([self.shownThisSession[inapp.Id] intValue] + 1);
    } else {
        self.shownThisSession[inapp.Id] = @1;
    }
    [self incrementInAppCountsInPersistentStore:inapp.Id];
    int shownToday = (int) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:0];
    [CTPreferences putInt:shownToday + 1 forKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY]];
}

- (void)updateLimitsPerDay:(int)perDay andPerSession:(int)perSession {
    [CTPreferences putInt:perDay forKey:[self storageKeyWithSuffix:kKEY_MAX_PER_DAY]];
    [CTPreferences putInt:perSession forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SESSION_MAX]];
}

- (void)attachToHeader:(NSMutableDictionary *)header {
    @try {
        if (self.config.isDefaultInstance) {
            header[@"imp"] = @([CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:[CTPreferences getIntForKey:kKEY_COUNTS_SHOWN_TODAY withResetValue:0]]);
        } else {
            header[@"imp"] = @([CTPreferences getIntForKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY] withResetValue:0]);
        }
        // tlc: [[targetID, todayCount, lifetime]]
        
        NSMutableArray *arr = [NSMutableArray new];
        NSDictionary *countsContainer = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
        if (self.config.isDefaultInstance && !countsContainer) {
            countsContainer = [CTPreferences getObjectForKey:[NSString stringWithFormat:@"%@:%@", kKEY_COUNTS_PER_INAPP, self.deviceId]];
        }
        NSArray *keys = [countsContainer allKeys];
        for (int i = 0; i < keys.count; ++i) {
            NSArray *counts = countsContainer[keys[(NSUInteger) i]];
            if (counts.count == 2) {
                [arr addObject:@[keys[(NSUInteger) i], counts[0], counts[1]]];
            }
        }
        
        header[@"tlc"] = arr;
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach FC to header: %@", self, e.debugDescription);
    }
}

- (void)processResponse:(NSDictionary *)response {
    if (!response || !response[@"inapp_stale"] || ![response[@"inapp_stale"] isKindOfClass:[NSArray class]]) return;
    @try {
        NSDictionary *_countsContainer = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
        if (self.config.isDefaultInstance && !_countsContainer) {
            _countsContainer = [CTPreferences getObjectForKey:[NSString stringWithFormat:@"%@:%@", kKEY_COUNTS_PER_INAPP, self.deviceId]];
        }
        NSMutableDictionary *countsContainer = _countsContainer ? [_countsContainer mutableCopy] : [NSMutableDictionary new];
        if (!countsContainer) return;
        NSArray *stale = response[@"inapp_stale"];
        for (int i = 0; i < [stale count]; i++) {
            NSString *key = [NSString stringWithFormat:@"%@", stale[i]];
            [countsContainer removeObjectForKey:key];
            CleverTapLogInternal(self.config.logLevel, @"%@: Purged inapp counts with key %@", self, key);
        }
        [CTPreferences putObject:countsContainer forKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to purge out stale in-app counts - %@", self, e.debugDescription);
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

- (void)recordImpression {
    // record impression for limits
    // record impression for session
    // record impression for day
    // record impression in tlc counts
}

@end
