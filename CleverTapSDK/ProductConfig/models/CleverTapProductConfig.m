#import "CleverTapProductConfigPrivate.h"

#define CLTAP_DEFAULT_MIN_CONFIG_INTERVAL 1
#define CLTAP_DEFAULT_MIN_CONFIG_RATE 5

@implementation CleverTapProductConfig

@synthesize delegate=_delegate;
@synthesize minConfigRate=_minConfigRate;
@synthesize minConfigInterval=_minConfigInterval;


- (instancetype _Nonnull)initWithPrivateDelegate:(id<CleverTapPrivateProductConfigDelegate>)delegate {
    self = [super init];
    if (self) {
        self.privateDelegate = delegate;
    }
    return self;
}

- (void)updateProductConfigWithOptions:(NSDictionary *)options {
    self.minConfigRate = [options[@"rc_n"] doubleValue];
    self.minConfigInterval = [options[@"rc_w"] doubleValue];
}

- (void)setMinConfigInterval:(NSTimeInterval)minConfigInterval {
    if (minConfigInterval <= 0) {
        _minConfigInterval = CLTAP_DEFAULT_MIN_CONFIG_INTERVAL;
    } else {
        _minConfigInterval = minConfigInterval;
    }
}

- (void)setMinConfigRate:(NSTimeInterval)minConfigRate {
    if (minConfigRate <= 0) {
        _minConfigRate = CLTAP_DEFAULT_MIN_CONFIG_RATE;
    } else {
        _minConfigRate = minConfigRate;
    }
}

- (NSTimeInterval)minConfigInterval {
    return _minConfigInterval;
}

- (NSTimeInterval)minConfigRate {
    return _minConfigRate;
}

- (void)setDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    [self.privateDelegate setProductConfigDelegate:delegate];
}

// TODO

- (void)fetch {
    // TODO: Throttling logic
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(fetchProductConfig)]) {
        [self.privateDelegate fetchProductConfig];
    }
}

- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval {
    // TODO:
}

- (void)activate {
    // TODO:
}

- (void)fetchAndActivate {
    // TODO: Throttling logic
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
    if (self.privateDelegate) {
        return [self.privateDelegate getProductConfig:key];
    }
    // TODO: Handle the config value
    CleverTapConfigValue *value;
    return value;
}

- (void)setMinimumFetchInterval:(NSTimeInterval)fetchInterval {
    self.minConfigInterval = fetchInterval;
}

// Getters TODO

@end
