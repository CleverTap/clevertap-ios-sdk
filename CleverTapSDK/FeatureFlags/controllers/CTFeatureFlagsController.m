#import "CTFeatureFlagsController.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CleverTapInstanceConfig.h"

@interface CTFeatureFlagsController() {
    NSOperationQueue *_commandQueue;
}

@property (atomic, copy) NSString *guid;
@property (atomic, strong) CleverTapInstanceConfig *config;
@property (atomic) NSMutableDictionary<NSString *, NSNumber *> *store;

@property (nonatomic, weak) id<CTFeatureFlagsDelegate> _Nullable delegate;

@end

typedef void (^CTFeatureFlagsOperationBlock)(void);

@implementation CTFeatureFlagsController

- (instancetype _Nullable)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config
                                    guid:(NSString *_Nonnull)guid
                                delegate:(id<CTFeatureFlagsDelegate>_Nonnull)delegate {
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

- (void)updateFeatureFlags:(NSArray<NSDictionary *> *)featureFlags {
    [self _updateFeatureFlags:featureFlags isNew:YES];
}

// be sure to call off the main thread
- (void)_updateFeatureFlags:(NSArray<NSDictionary*> *)featureFlags isNew:(BOOL)isNew {
    CleverTapLogInternal(_config.logLevel, @"%@: updating feature flags: %@", self, featureFlags);
    NSMutableDictionary *store = [NSMutableDictionary new];
    for (NSDictionary *flag in featureFlags) {
        @try {
            store[flag[@"n"]] = [NSNumber numberWithBool: [flag[@"v"] boolValue]];
        } @catch (NSException *e) {
            CleverTapLogDebug(_config.logLevel, @"%@: error parsing feature flag: %@, %@", self, flag, e.debugDescription);
            continue;
        }
    }
    self.store = store;
    
    if (isNew) {
        [self _archiveData:featureFlags sync:NO];
    }
    [self notifyUpdate];
}

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(featureFlagsDidUpdate)]) {
        [self.delegate featureFlagsDidUpdate];
    }
}

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue {
    CleverTapLogInternal(_config.logLevel, @"%@: get feature flag: %@ with default: %i", self, key, defaultValue);
    @try {
        NSNumber *value = self.store[key];
        if (value != nil) {
            return [value boolValue];
        } else {
            CleverTapLogDebug(_config.logLevel, @"%@: feature flag %@ not found, returning default value", self, key);
            return defaultValue;
        }
    } @catch (NSException *e) {
        CleverTapLogDebug(_config.logLevel, @"%@: error parsing feature flag: %@ not found, returning default value", self, key);
        return defaultValue;
    }
}

- (NSString*)dataArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-feature-flags.plist", _config.accountId, _guid];
}

- (void)_unarchiveDataSync:(BOOL)sync {
    NSString *filePath = [self dataArchiveFileName];
    __weak CTFeatureFlagsController *weakSelf = self;
    CTFeatureFlagsOperationBlock opBlock = ^{
        NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [NSDictionary class], [NSNumber class], [NSString class], [NSMutableDictionary class], nil];
        NSArray *featureFlags = [CTPreferences unarchiveFromFile: filePath ofTypes: allowedClasses removeFile:NO];
        if (featureFlags) {
            [weakSelf _updateFeatureFlags:featureFlags isNew:NO];
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
    CTFeatureFlagsOperationBlock opBlock = ^{
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
    return [NSString stringWithFormat:@"CleverTap.%@.CTFeatureFlagsController", _config.accountId];
}

@end
