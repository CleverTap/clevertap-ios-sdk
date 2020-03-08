
#import "CTFeatureFlagsController.h"
#import "CTConstants.h"
#import "CTPreferences.h"

@interface CTFeatureFlagsController() {
    NSOperationQueue *_commandQueue;
}

@property (nonatomic, copy, readonly) NSString *accountId;
@property (atomic, copy) NSString *guid;

@end

typedef void (^CTFeatureFlagsOperationBlock)(void);

@implementation CTFeatureFlagsController

- (instancetype)initWithAccountId:(NSString *)accountId guid:(NSString *)guid {
    self = [super init];
    if (self) {
        _isInitialized = YES;
        _accountId = accountId;
        _guid = guid;
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
    // TODO
    CleverTapLogStaticInternal(@"updating Feature Flags: %@", featureFlags);
    // NSMutableArray *units = [NSMutableArray new];
    // NSMutableArray *tempArray = [displayUnits mutableCopy];
    //for (NSDictionary *obj in tempArray) {
        // do something
    //}
    if (isNew) {
        [self _archiveData:featureFlags sync:NO];
        [self notifyUpdate];
    }
}


- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(featureFlagsDidUpdate)]) {
        [self.delegate featureFlagsDidUpdate];
    }
}

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue {
    // TODO
    CleverTapLogStaticInternal(@"get Feature Flags: %@ with default: %i", key, defaultValue);
    return defaultValue;
}

- (NSString*)dataArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-feature-flags.plist", _accountId, _guid];
}

- (void)_unarchiveDataSync:(BOOL)sync {
    NSString *filePath = [self dataArchiveFileName];
     __weak CTFeatureFlagsController *weakSelf = self;
    CTFeatureFlagsOperationBlock opBlock = ^{
        NSArray *featureFlags = [CTPreferences unarchiveFromFile:filePath removeFile:NO];
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

@end
