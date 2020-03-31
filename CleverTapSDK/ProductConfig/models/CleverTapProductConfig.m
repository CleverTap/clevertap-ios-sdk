#import "CleverTapProductConfigPrivate.h"
#import "CTConstants.h"

#define CLTAP_DEFAULT_FETCH_RATE 5
#define CLTAP_DEFAULT_FETCH_TIME_INTERVAL 60

@implementation CleverTapProductConfig

@synthesize delegate=_delegate;
@synthesize minFetchConfigRate=_minFetchConfigRate;
@synthesize minFetchConfigInterval=_minFetchConfigInterval;

- (instancetype _Nonnull)initWithPrivateDelegate:(id<CleverTapPrivateProductConfigDelegate>)delegate {
    self = [super init];
    if (self) {
        self.privateDelegate = delegate;
    }
    return self;
}

- (void)updateProductConfigWithOptions:(NSDictionary *)options {
    self.minFetchConfigRate = [options[@"rc_n"] doubleValue];
    self.minFetchConfigInterval = [options[@"rc_w"] doubleValue];
}

- (void)updateProductConfigWithLastFetchTs:(NSTimeInterval)lastFetchTs {
    self.lastFetchTimeInterval = lastFetchTs;
}

- (void)setMinFetchConfigRate:(NSTimeInterval)minFetchConfigRate {
    if (minFetchConfigRate <= 0) {
        _minFetchConfigRate = CLTAP_DEFAULT_FETCH_RATE;
    } else {
        _minFetchConfigRate = minFetchConfigRate;
    }
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
}

- (NSTimeInterval)minFetchConfigInterval {
    return _minFetchConfigInterval;
}

- (void)setDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    [self.privateDelegate setProductConfigDelegate:delegate];
}

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
    // TODO: 
}

- (void)setMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval {
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
        NSTimeInterval timeSinceLastRequest = [NSDate new].timeIntervalSince1970 - self.lastFetchTimeInterval;
        return timeSinceLastRequest > (self.minFetchConfigInterval / self.minFetchConfigRate);
    }
    return NO;
}

@end
