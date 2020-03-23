#import "CTProductConfigController.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CleverTapInstanceConfig.h"

@class CleverTapConfigValue;

@interface CTProductConfigController() {
    NSOperationQueue *_commandQueue;
}

@property (atomic, copy) NSString *guid;
@property (atomic, strong) CleverTapInstanceConfig *config;
@property (atomic) NSMutableDictionary *store;  // TODO
@property (nonatomic, strong) NSDictionary<NSString *, NSObject *> *defaultConfig;
@property (nonatomic, strong) NSDictionary<NSString *, NSObject *> *activatedConfig;

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
            // store[kv[@"n"]] = [NSNumber numberWithBool: [flag[@"v"] boolValue]]; // TODO
//            self.store[kv[@"n"]] = [[CleverTapConfigValue alloc] initWithData:kv[@"v"]];
        } @catch (NSException *e) {
            CleverTapLogDebug(_config.logLevel, @"%@: error parsing product config key-value: %@, %@", self, kv, e.debugDescription);
            continue;
        }
    }
    self.store = store;

    if (isNew) {
        [self _archiveData:productConfig sync:NO];
    }
    [self notifyUpdate];
}

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(productConfigDidUpdate)]) {
        [self.delegate productConfigDidUpdate];
    }
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

- (void)setDefaults:(NSDictionary<NSString *,NSObject *> *)defaults {
    _defaultConfig = [defaults copy];
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
    // TODO: implement
    CleverTapConfigValue *value;
    return value;
}

@end
