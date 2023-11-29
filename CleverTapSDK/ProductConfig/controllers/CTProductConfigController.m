#import "CTProductConfigController.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapProductConfigPrivate.h"
#import "CTUtils.h"

@class CleverTapConfigValue;

@interface CTProductConfigController() {
    NSOperationQueue *_commandQueue;
}

@property (atomic, copy) NSString *guid;
@property (atomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSDictionary *defaultConfig;
@property (nonatomic, strong) NSDictionary *fetchedConfig;
@property (atomic, strong) NSDictionary *activeConfig;
@property (atomic, assign) BOOL activateFetchedConfig;

@property (nonatomic, weak) id<CTProductConfigDelegate> _Nullable delegate;

@end

typedef void (^CTProductConfigOperationBlock)(void);

@implementation CTProductConfigController

- (instancetype _Nullable)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config
                                    guid:(NSString *_Nonnull)guid
                                delegate:(id<CTProductConfigDelegate>_Nonnull)delegate {
    self = [super init];
    if (self) {
        _isInitialized = YES;
        _config = config;
        _guid = guid;
        _delegate = delegate;
        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        [self _unarchiveDataSync:YES];
        [self notifyInitUpdate];
    }
    return self;
}

// be sure to call off the main thread
- (void)updateProductConfig:(NSArray<NSDictionary *> *)productConfig {
    [self _updateProductConfig:productConfig isNew:YES];
}

// be sure to call off the main thread
- (void)_updateProductConfig:(NSArray<NSDictionary*> *)productConfig isNew:(BOOL)isNew {
    CleverTapLogInternal(_config.logLevel, @"%@: updating product config: %@", self, productConfig);
    NSMutableDictionary *store = [NSMutableDictionary new];
    
    for (NSDictionary *kv in productConfig) {
        @try {
            store[kv[@"n"]] = kv[@"v"];
        } @catch (NSException *e) {
            CleverTapLogDebug(_config.logLevel, @"%@: error parsing product config key-value: %@, %@", self, kv, e.debugDescription);
            continue;
        }
    }
    
    self.fetchedConfig = [NSDictionary dictionaryWithDictionary:store];
    
    if (isNew) {
        [self _archiveData:productConfig sync:NO];
        [self notifyFetchUpdate];
    }
    
    if (self.activateFetchedConfig) {
        [self activate];
    }
}

- (void)_updateActiveProductConfig:(BOOL)activated {
    CleverTapLogInternal(_config.logLevel, @"%@: activating product config", self);
    self.activeConfig = [NSMutableDictionary new];
    NSMutableDictionary *store = [NSMutableDictionary new];
    NSMutableDictionary *activeConfig = [NSMutableDictionary new];
    
    // handle default config
    if (self.defaultConfig && self.defaultConfig != nil) {
        [activeConfig addEntriesFromDictionary:self.defaultConfig];
    }
    
    // handle fetched config if activated
    if (activated && self.fetchedConfig && self.fetchedConfig != nil) {
        [activeConfig addEntriesFromDictionary:self.fetchedConfig];
    }
    
    // handle active config
    for (NSString *key in activeConfig) {
        @try {
            NSObject *value = activeConfig[key];
            NSData *valueData;
            if ([value isKindOfClass:[NSData class]]) {
                valueData = (NSData *)value;
            } else if ([value isKindOfClass:[NSString class]]) {
                valueData = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([value isKindOfClass:[NSNumber class]]) {
                NSString *strValue = [(NSNumber *)value stringValue];
                valueData = [(NSString *)strValue dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([value isKindOfClass:[NSDate class]]) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                NSString *strValue = [dateFormatter stringFromDate:(NSDate *)value];
                valueData = [(NSString *)strValue dataUsingEncoding:NSUTF8StringEncoding];
            } else {
                CleverTapLogDebug(_config.logLevel, @"%@: error setting product config value: %@", self, value);
                continue;
            }
            store[key] = [[CleverTapConfigValue alloc] initWithData:valueData];
        } @catch (NSException *e) {
            CleverTapLogDebug(_config.logLevel, @"%@: error parsing product config key-value: %@, %@", self, activeConfig, e.debugDescription);
            continue;
        }
    }
    self.activeConfig = [NSDictionary dictionaryWithDictionary:store];
    self.activateFetchedConfig = NO;
    if (activated) {
        [self notifyActivateUpdate];
    } else {
        [self notifyFetchUpdate];
    }
}

#pragma mark - Delegates

+ (void)runSyncMainQueue:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)notifyInitUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(productConfigDidInitialize)]) {
        [CTUtils runSyncMainQueue:^{
            [self.delegate productConfigDidInitialize];
        }];
    }
}

- (void)notifyFetchUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(productConfigDidFetch)]) {
        [CTUtils runSyncMainQueue:^{
            [self.delegate productConfigDidFetch];
        }];
    }
}

- (void)notifyActivateUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(productConfigDidActivate)]) {
        [CTUtils runSyncMainQueue:^{
            [self.delegate productConfigDidActivate];
        }];
    }
}


#pragma mark - Storage operations

- (NSString*)dataArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-product-config.plist", _config.accountId, _guid];
}

- (void)_unarchiveDataSync:(BOOL)sync {
    NSString *filePath = [self dataArchiveFileName];
    __weak CTProductConfigController *weakSelf = self;
    CTProductConfigOperationBlock opBlock = ^{
        NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [NSDictionary class], nil];
        NSArray *data = [CTPreferences unarchiveFromFile: filePath ofTypes: allowedClasses removeFile: YES];
        if (data) {
            [weakSelf _updateProductConfig:data isNew:NO];
        }
    };
    if (sync) {
        opBlock();
    } else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
        _commandQueue.suspended = NO;
        [_commandQueue addOperation:operation];
    }
}

- (void)_archiveData:(NSArray*)data sync:(BOOL)sync {
    NSString *filePath = [self dataArchiveFileName];
    CTProductConfigOperationBlock opBlock = ^{
        [CTPreferences archiveObject:data forFileName:filePath config:self->_config];
    };
    if (sync) {
        opBlock();
    } else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
        _commandQueue.suspended = NO;
        [_commandQueue addOperation:operation];
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@.CTProductConfigController", _config.accountId];
}


#pragma mark - Product Config APIs

- (void)activate {
    [self _updateActiveProductConfig:YES];
}

- (void)fetchAndActivate {
    self.activateFetchedConfig = YES;
}

- (void)reset {
    self.defaultConfig = [NSDictionary new];
    self.activeConfig = [NSDictionary new];
    self.fetchedConfig = [NSDictionary new];
    [self _archiveData:[NSArray new] sync:NO];
}

- (void)setDefaults:(NSDictionary<NSString *,NSObject *> *)defaults {
    _defaultConfig = defaults;
    [self _updateActiveProductConfig:NO];
}

- (void)setDefaultsFromPlistFileName:(NSString *_Nullable)fileName {
    NSArray *bundles = @[ [NSBundle mainBundle], [NSBundle bundleForClass:[self class]] ];
    for (NSBundle *bundle in bundles) {
        NSString *plistFile = [bundle pathForResource:fileName ofType:@"plist"];
        if (plistFile) {
            NSDictionary *defaultConfig = [[NSDictionary alloc] initWithContentsOfFile:plistFile];
            if (defaultConfig) {
                [self setDefaults:defaultConfig];
            }
            return;
        }
    }
    CleverTapLogDebug(_config.logLevel, @"%@: The plist file %@ could not be found", fileName, self);
}

- (CleverTapConfigValue *_Nullable)get:(NSString* _Nonnull)key {
    CleverTapLogInternal(_config.logLevel, @"%@: get product config for key: %@", self, key);
    @try {
        if (!key) {
            CleverTapLogDebug(_config.logLevel, @"%@: product config key not found", self);
            return [[CleverTapConfigValue alloc] initWithData:[NSData data]];
        }
        CleverTapConfigValue *value = self.activeConfig[key];
        if (value) {
            return value;
        } else {
            CleverTapLogDebug(_config.logLevel, @"%@: product config for key %@ not found", self, key);
            return [[CleverTapConfigValue alloc] initWithData:[NSData data]];
        }
    } @catch (NSException *e) {
        CleverTapLogDebug(_config.logLevel, @"%@: error parsing product config for key: %@ not found", self, key);
        return [[CleverTapConfigValue alloc] initWithData:[NSData data]];
    }
}

@end
