#import "CTProductConfigController.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTPreferences.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapProductConfigPrivate.h"

@class CleverTapConfigValue;

@interface CTProductConfigController() {
    NSOperationQueue *_commandQueue;
}

@property (atomic, copy) NSString *guid;
@property (atomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSMutableDictionary *defaultConfig;
@property (nonatomic, strong) NSMutableDictionary *activeConfig;
@property (nonatomic, strong) NSMutableDictionary *fetchedConfig;
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
    
    self.fetchedConfig = [store mutableCopy];
    
    if (isNew) {
        [self _archiveData:productConfig sync:NO];
    }
    if (self.activateFetchedConfig) {
        [self activate];
    }
    self.activateFetchedConfig = NO;
    [self notifyUpdate];
}

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(productConfigDidUpdate)]) {
        [self.delegate productConfigDidUpdate];
    }
}

- (void)_updateActiveProductConfig:(BOOL)activated {
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
                CleverTapLogDebug(_config.logLevel, @"%@: error parsing product config value: %@", self, value);
                continue;
            }
            store[key] = [[CleverTapConfigValue alloc] initWithData:valueData];
            
        } @catch (NSException *e) {
            CleverTapLogDebug(_config.logLevel, @"%@: error parsing product config key-value: %@, %@", self, activeConfig, e.debugDescription);
            continue;
        }
    }
    self.activeConfig = [store mutableCopy];
}

- (NSString*)dataArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-product-config.plist", _config.accountId, _guid];
}

- (void)_unarchiveDataSync:(BOOL)sync {
    NSString *filePath = [self dataArchiveFileName];
    __weak CTProductConfigController *weakSelf = self;
    CTProductConfigOperationBlock opBlock = ^{
        NSArray *data = [CTPreferences unarchiveFromFile:filePath removeFile:NO];
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
        [CTPreferences archiveObject:data forFileName:filePath];
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

- (void)setDefaults:(NSDictionary<NSString *,NSObject *> *)defaults {
    _defaultConfig = [defaults copy];
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
    CleverTapLogDebug(_config.logLevel, @"%@: The plist file %@ could not be found ", self, fileName);
}

- (CleverTapConfigValue *_Nullable)get:(NSString* _Nonnull)key {
    if (!key ) {
        return [[CleverTapConfigValue alloc] initWithData:[NSData data]];
    }
    CleverTapConfigValue *value;
    if (self.activeConfig[key]) {
        value = self.activeConfig[key];
    } else if (self.defaultConfig[key]) {
        value = self.defaultConfig[key];
    } else {
        value = [[CleverTapConfigValue alloc] initWithData:[NSData data]];
    }
    return value;
}

@end
