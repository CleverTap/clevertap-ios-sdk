#import "CTAdUnitController.h"
#import "CTPreferences.h"

@interface CTAdUnitController() {
}

@property (nonatomic, copy, readonly) NSString *accountId;
@property (atomic, copy) NSString *guid;

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

- (void)updateAdUnits:(NSArray<NSDictionary *> *)adUnits {
    [self _updateAdUnits:adUnits];
}

// be sure to call off the main thread
- (void)_updateAdUnits:(NSArray<NSDictionary*> *)adUnits {
    NSMutableArray *units = [NSMutableArray new];
    NSMutableArray *tempArray = [adUnits mutableCopy];
    for (NSDictionary *obj in tempArray) {
        CleverTapAdUnit *adUnit = [[CleverTapAdUnit alloc] initWithJSON:obj];
        [units addObject:adUnit];
    }
    _adUnits = units;
    [self notifyUpdate];
}

- (NSArray *)adUnits {
    if (!self.isInitialized) return nil;
    return _adUnits;
}

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(adUnitsDidUpdate)]) {
        [self.delegate adUnitsDidUpdate];
    }
}

@end
