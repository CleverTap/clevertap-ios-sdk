#import "CleverTapProductConfigPrivate.h"
#import "CleverTapInstanceConfig.h"
#import "CTPreferences.h"
#import "CTConstants.h"

#define CLTAP_DEFAULT_FETCH_CALLS 5
#define CLTAP_DEFAULT_FETCH_WINDOW_LENGTH 60

NSString* const kFETCH_CONFIG_WINDOW_LENGTH_KEY = @"CLTAP_FETCH_CONFIG_WINDOW_LENGTH_KEY";
NSString* const kFETCH_CONFIG_CALLS_KEY = @"CLTAP_FETCH_CONFIG_CALLS_KEY";
NSString* const kLAST_FETCH_TS_KEY = @"CLTAP_LAST_FETCH_TS_KEY";


@interface CleverTapProductConfig() {
}

@property (atomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CleverTapProductConfig

@synthesize delegate=_delegate;
@synthesize fetchConfigCalls=_fetchConfigCalls;
@synthesize fetchConfigWindowLength=_fetchConfigWindowLength;
@synthesize minimumFetchConfigInterval=_minimumFetchConfigInterval;

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
    _fetchConfigCalls = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kFETCH_CONFIG_CALLS_KEY] withResetValue:CLTAP_DEFAULT_FETCH_CALLS];
    _fetchConfigWindowLength = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kFETCH_CONFIG_WINDOW_LENGTH_KEY] withResetValue:CLTAP_DEFAULT_FETCH_WINDOW_LENGTH];
    _lastFetchTs = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_FETCH_TS_KEY] withResetValue:0];
}

- (void)updateProductConfigWithOptions:(NSDictionary *)options {
    self.fetchConfigCalls = [options[@"rc_n"] doubleValue];
    self.fetchConfigWindowLength = [options[@"rc_w"] doubleValue];
}

- (void)updateProductConfigWithLastFetchTs:(NSTimeInterval)lastFetchTs {
    self.lastFetchTs = lastFetchTs;
    [self persistLastFetchTs];
}

- (void)setFetchConfigCalls:(NSTimeInterval)fetchConfigCalls {
    if (fetchConfigCalls <= 0) {
        _fetchConfigCalls = CLTAP_DEFAULT_FETCH_CALLS;
    } else {
        _fetchConfigCalls = fetchConfigCalls;
    }
    [self persistFetchConfigCalls];
}

- (NSTimeInterval)fetchConfigCalls {
    return _fetchConfigCalls;
}

- (void)setFetchConfigWindowLength:(NSTimeInterval)fetchConfigWindowLength {
    if (fetchConfigWindowLength <= 0) {
        _fetchConfigWindowLength = CLTAP_DEFAULT_FETCH_WINDOW_LENGTH;
    } else {
        _fetchConfigWindowLength = fetchConfigWindowLength;
    }
    [self persistFetchConfigWindowLength];
}

- (NSTimeInterval)fetchConfigWindowLength {
    return _fetchConfigWindowLength;
}

- (void)setMinimumFetchConfigInterval:(NSTimeInterval)minimumFetchConfigInterval {
    _minimumFetchConfigInterval = minimumFetchConfigInterval;
}

- (NSTimeInterval)minimumFetchConfigInterval{
    return _minimumFetchConfigInterval;
}

- (void)setDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    [self.privateDelegate setProductConfigDelegate:delegate];
}

#pragma mark - Persist Product Config Settings

- (void)persistFetchConfigWindowLength {
    [CTPreferences putInt:self.fetchConfigWindowLength forKey:[self storageKeyWithSuffix:kFETCH_CONFIG_WINDOW_LENGTH_KEY]];
}

- (void)persistFetchConfigCalls {
    [CTPreferences putInt:self.fetchConfigCalls forKey:[self storageKeyWithSuffix:kFETCH_CONFIG_CALLS_KEY]];
}

- (void)persistLastFetchTs {
    [CTPreferences putInt:self.lastFetchTs forKey:[self storageKeyWithSuffix:kLAST_FETCH_TS_KEY]];
}

- (NSString *)storageKeyWithSuffix: (NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@",  _config.accountId, suffix];
}

#pragma mark - Public Apis

- (void)fetch {
    [self fetchWithMinimumInterval:[self getMinimumFetchInterval]];
}

- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval {
    if ([self shouldThrottleWithMinimumFetchInterval:minimumInterval])  {
        if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(fetchProductConfig)]) {
            [self.privateDelegate fetchProductConfig];
        }
    } else {
        CleverTapLogStaticDebug(@"FetchError: Product Config is throttled.");
    }
}

- (void)setMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval {
    self.minimumFetchConfigInterval = minimumFetchInterval;
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

- (BOOL)shouldThrottleWithMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval {
    return [self timeSinceLastRequest] > minimumFetchInterval;
}

- (NSInteger)getMinimumFetchInterval {
    NSInteger sdkMinimumFetchInterval = round((self.fetchConfigWindowLength/self.fetchConfigCalls)*60);
    NSInteger userMinimumFetchInterval = round(self.minimumFetchConfigInterval);
    return MAX(sdkMinimumFetchInterval, userMinimumFetchInterval);
}

- (NSInteger)timeSinceLastRequest {
    // TODO: remove this
    NSTimeInterval timeSinceLastRequest = [NSDate new].timeIntervalSince1970 - self.lastFetchTs;
    return round(timeSinceLastRequest);
}

@end
