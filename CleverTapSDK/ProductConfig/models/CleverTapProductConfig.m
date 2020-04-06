#import "CleverTapProductConfigPrivate.h"
#import "CleverTapInstanceConfig.h"
#import "CTPreferences.h"
#import "CTConstants.h"

#define CLTAP_DEFAULT_FETCH_RATE 5
#define CLTAP_DEFAULT_FETCH_TIME_INTERVAL 60

NSString* const kMIN_FETCH_INTERVAL_KEY = @"CLTAP_MIN_FETCH_INTERVAL_KEY";
NSString* const kMIN_FETCH_RATE_KEY = @"CLTAP_MIN_FETCH_RATE_KEY";
NSString* const kLAST_FETCH_TS_KEY = @"CLTAP_LAST_FETCH_TS_KEY";

@interface CleverTapProductConfig() {
}

@property (atomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CleverTapProductConfig

@synthesize delegate=_delegate;
@synthesize minFetchConfigRate=_minFetchConfigRate;
@synthesize minFetchConfigInterval=_minFetchConfigInterval;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config privateDelegate:(id<CleverTapPrivateProductConfigDelegate>_Nonnull)delegate {
    self = [super init];
    if (self) {
        _config = config;
        _privateDelegate = delegate;
        [self initConfigSetting];
    }
    return self;
}

- (void)initConfigSetting {
    _minFetchConfigRate = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kMIN_FETCH_RATE_KEY] withResetValue:CLTAP_DEFAULT_FETCH_RATE];
    _minFetchConfigInterval = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kMIN_FETCH_INTERVAL_KEY] withResetValue:CLTAP_DEFAULT_FETCH_TIME_INTERVAL];
    _lastFetchTs = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_FETCH_TS_KEY] withResetValue:0];
}

- (void)updateProductConfigWithOptions:(NSDictionary *)options {
    self.minFetchConfigRate = [options[@"rc_n"] doubleValue];
    self.minFetchConfigInterval = [options[@"rc_w"] doubleValue];
}

- (void)updateProductConfigWithLastFetchTs:(NSTimeInterval)lastFetchTs {
    self.lastFetchTs = lastFetchTs;
    [self persistLastFetchTs];
}

- (void)setMinFetchConfigRate:(NSTimeInterval)minFetchConfigRate {
    if (minFetchConfigRate <= 0) {
        _minFetchConfigRate = CLTAP_DEFAULT_FETCH_RATE;
    } else {
        _minFetchConfigRate = minFetchConfigRate;
    }
    [self persistMinFetchConfigRate];
}

- (NSTimeInterval)minFetchConfigRate {
    return _minFetchConfigRate;
}

- (void)setMinFetchConfigInterval:(NSTimeInterval)minFetchConfigInterval {
    if (minFetchConfigInterval <= 0) {
        _minFetchConfigInterval = CLTAP_DEFAULT_FETCH_TIME_INTERVAL;
    } else {
        _minFetchConfigInterval = minFetchConfigInterval;
    }
    [self persistMinFetchConfigInterval];
}

- (NSTimeInterval)minFetchConfigInterval {
    return _minFetchConfigInterval;
}

- (void)setDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    [self.privateDelegate setProductConfigDelegate:delegate];
}

#pragma mark - Persist Product Config Settings

- (void)persistMinFetchConfigInterval {
    [CTPreferences putInt:self.minFetchConfigInterval forKey:[self storageKeyWithSuffix:kMIN_FETCH_INTERVAL_KEY]];
}

- (void)persistMinFetchConfigRate {
    [CTPreferences putInt:self.minFetchConfigRate forKey:[self storageKeyWithSuffix:kMIN_FETCH_RATE_KEY]];
}

- (void)persistLastFetchTs {
    [CTPreferences putInt:self.lastFetchTs forKey:[self storageKeyWithSuffix:kLAST_FETCH_TS_KEY]];
}

- (NSString *)storageKeyWithSuffix: (NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@",  _config.accountId, suffix];
}

#pragma mark - Public Apis

- (void)fetch {
    if ([self shouldThrottle])  {
        if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(fetchProductConfig)]) {
            [self.privateDelegate fetchProductConfig];
        }
    } else {
        CleverTapLogStaticDebug(@"FetchError: Product Config is throttled.");
    }
}

- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval {
    // TODO: if zero always call fetch
    self.minFetchConfigInterval = minimumInterval;
    [self fetch];
}

- (void)setMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval {
    // TODO: @peter minimum Fetch Interval measure unit
    // TODO: over write always with arp values fix
    if (minimumFetchInterval > self.minFetchConfigInterval) {
        self.minFetchConfigInterval = minimumFetchInterval;
    } else {
        CleverTapLogStaticDebug(@"Minimum Fetch Interval Error: Unable to set provided minimum fetch interval %f:", minimumFetchInterval);
    }
}

- (void)activate {
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(activateProductConfig)]) {
        [self.privateDelegate activateProductConfig];
    }
}

- (void)fetchAndActivate {
    [self fetch];
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(fetchAndActivateProductConfig)]) {
        [self.privateDelegate fetchAndActivateProductConfig];
    }
    
}

- (void)setDefaults:(NSDictionary<NSString *, NSObject *> *_Nullable)defaults {
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(setDefaultsProductConfig:)]) {
        [self.privateDelegate setDefaultsProductConfig:defaults];
    }
}

- (void)setDefaultsFromPlistFileName:(NSString *_Nullable)fileName {
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(setDefaultsFromPlistFileNameProductConfig:)]) {
        [self.privateDelegate setDefaultsFromPlistFileNameProductConfig:fileName];
    }
}

- (CleverTapConfigValue *)get:(NSString *)key {
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(getProductConfig:)]) {
        return [self.privateDelegate getProductConfig:key];
    }
    return nil;
}

#pragma mark - Throttling

- (BOOL)shouldThrottle {
    if ((_minFetchConfigRate > 0) && (_minFetchConfigInterval > 0)) {
        return [self timeSinceLastRequest] > (self.minFetchConfigInterval / self.minFetchConfigRate);
    }
    return NO;
}

- (int)timeSinceLastRequest {
    NSTimeInterval timeSinceLastRequest = [NSDate new].timeIntervalSince1970 - self.lastFetchTs;
    long seconds = lroundf(timeSinceLastRequest);
    return (seconds % 3600) / 60;
}

@end
