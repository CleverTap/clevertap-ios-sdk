#import "CleverTapProductConfigPrivate.h"
#import "CleverTapInstanceConfig.h"
#import "CTPreferences.h"
#import "CTConstants.h"

#define CLTAP_DEFAULT_FETCH_CALLS 5
#define CLTAP_DEFAULT_FETCH_WINDOW_LENGTH 60

NSString* const kLAST_FETCH_TS_KEY = @"CLTAP_LAST_FETCH_TS_KEY";

@interface CleverTapProductConfig() {
}

@property (atomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CleverTapProductConfig

@synthesize delegate=_delegate;
@synthesize fetchConfigCalls=_fetchConfigCalls;
@synthesize fetchConfigWindowLength=_fetchConfigWindowLength;
@synthesize lastFetchTs=_lastFetchTs;
@synthesize minimumFetchConfigInterval=_minimumFetchConfigInterval;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config privateDelegate:(id<CleverTapPrivateProductConfigDelegate>_Nonnull)delegate {
    self = [super init];
    if (self) {
        _config = config;
        _privateDelegate = delegate;
        [self initProductConfigSetting];
    }
    return self;
}

- (void)initProductConfigSetting {
    self.fetchConfigCalls = CLTAP_DEFAULT_FETCH_CALLS;
    self.fetchConfigWindowLength = CLTAP_DEFAULT_FETCH_WINDOW_LENGTH;
    _lastFetchTs = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLAST_FETCH_TS_KEY config: _config] withResetValue:0];
}

- (void)updateProductConfigWithOptions:(NSDictionary *)options {
    self.fetchConfigCalls = [options[@"rc_n"] integerValue];
    self.fetchConfigWindowLength = [options[@"rc_w"] integerValue];
}

- (void)resetProductConfigSettings {
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:kLAST_FETCH_TS_KEY config: _config]];
    [self initProductConfigSetting];
}

- (void)updateProductConfigWithLastFetchTs:(NSTimeInterval)lastFetchTs {
    self.lastFetchTs = lastFetchTs;
}

- (void)setFetchConfigCalls:(NSInteger)fetchConfigCalls {
    if (fetchConfigCalls <= 0) {
        _fetchConfigCalls = CLTAP_DEFAULT_FETCH_CALLS;
    } else {
        _fetchConfigCalls = fetchConfigCalls;
    }
}

- (NSInteger)fetchConfigCalls {
    return _fetchConfigCalls;
}

- (void)setFetchConfigWindowLength:(NSInteger)fetchConfigWindowLength {
    if (fetchConfigWindowLength <= 0) {
        _fetchConfigWindowLength = CLTAP_DEFAULT_FETCH_WINDOW_LENGTH;
    } else {
        _fetchConfigWindowLength = fetchConfigWindowLength;
    }
}

- (NSInteger)fetchConfigWindowLength {
    return _fetchConfigWindowLength;
}

- (void)setMinimumFetchConfigInterval:(NSTimeInterval)minimumFetchConfigInterval {
    _minimumFetchConfigInterval = minimumFetchConfigInterval;
}

- (NSTimeInterval)minimumFetchConfigInterval{
    return _minimumFetchConfigInterval;
}

- (void)setLastFetchTs:(NSTimeInterval)lastFetchTs {
    _lastFetchTs = lastFetchTs;
    [self persistLastFetchTs];
}

- (NSTimeInterval)lastFetchTs {
    return _lastFetchTs;
}

- (void)setDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    [self.privateDelegate setProductConfigDelegate:delegate];
}

#pragma mark - Persist Product Config Settings

- (void)persistLastFetchTs {
    [CTPreferences putInt:self.lastFetchTs forKey:[CTPreferences storageKeyWithSuffix:kLAST_FETCH_TS_KEY config: _config]];
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
        CleverTapLogStaticDebug(@"Fetch Error: Product Config is throttled, try again in %ds", (int)(minimumInterval - [self timeSinceLastRequest]));
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

- (void)reset {
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(resetProductConfig)]) {
        [self resetProductConfigSettings];
        [self.privateDelegate resetProductConfig];
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

- (NSDate *)getLastFetchTimeStamp {
    NSTimeInterval lastFetchTime = self.lastFetchTs;
    return [NSDate dateWithTimeIntervalSince1970:lastFetchTime];
}


#pragma mark - Throttling

- (BOOL)shouldThrottleWithMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval {
    return [self timeSinceLastRequest] > minimumFetchInterval;
}

- (NSInteger)getMinimumFetchInterval {
    NSInteger serverMinimumFetchInterval = round((self.fetchConfigWindowLength/self.fetchConfigCalls)*60);
    NSInteger sdkMinimumFetchInterval = round(self.minimumFetchConfigInterval);
    return MAX(sdkMinimumFetchInterval, serverMinimumFetchInterval);
}

- (NSInteger)timeSinceLastRequest {
    NSTimeInterval timeSinceLastRequest = [NSDate new].timeIntervalSince1970 - self.lastFetchTs;
    return round(timeSinceLastRequest);
}

@end
