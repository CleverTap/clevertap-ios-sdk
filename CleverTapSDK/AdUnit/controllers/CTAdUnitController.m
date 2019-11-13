#import "CTAdUnitController.h"
#import "CTPreferences.h"

@interface CTAdUnitController() {
}

@property (nonatomic, copy, readonly) NSString *accountId;
@property (atomic, copy) NSString *guid;

@property (nonatomic, copy, readwrite) NSArray *adUnitIDs;
@property (nonatomic, copy, readwrite) NSArray *adUnits;

@end

@implementation CTAdUnitController

- (instancetype)initWithAccountId:(NSString *)accountId guid:(NSString *)guid {
    self = [super init];
    if (self) {
        _isInitialized = YES;
        _accountId = accountId;
        _guid = guid;
    }
    return self;
}

- (void)updateAdUnit:(NSArray<NSDictionary *> *)adUnits {
    [self _updateAdUnit:adUnits];
}

// be sure to call off the main thread
- (void)_updateAdUnit:(NSArray<NSDictionary*> *)adUnits {
    NSMutableArray *ids = [NSMutableArray new];
    NSMutableArray *units = [NSMutableArray new];
    
    NSMutableArray *tempArray = [adUnits mutableCopy];
    for (NSDictionary *obj in tempArray) {
        CleverTapAdUnit *adUnit = [[CleverTapAdUnit alloc] initWithJSON:obj.allValues[0]];
        [ids addObject:obj.allKeys[0]];
        [units addObject:adUnit];
    }
    _adUnitIDs = ids;
    _adUnits = units;
    [self notifyUpdate];
}

- (NSArray *)adUnits {
    if (!self.isInitialized) return nil;
    return _adUnits;
}

- (NSArray <CleverTapAdUnit *> *)adUnitIDs {
    if (!self.isInitialized) return nil;
    return _adUnitIDs;
}

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adUnitsDidUpdate)]) {
        [self.delegate adUnitsDidUpdate];
    }
}

@end
