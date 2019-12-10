#import "CTDisplayUnitController.h"
#import "CTPreferences.h"

@interface CTDisplayUnitController() {
}

@property (nonatomic, copy, readonly) NSString *accountId;
@property (atomic, copy) NSString *guid;

@property (nonatomic, copy, readwrite) NSArray *displayUnits;

@end

@implementation CTDisplayUnitController

- (instancetype)initWithAccountId:(NSString *)accountId guid:(NSString *)guid {
    self = [super init];
    if (self) {
        _isInitialized = YES;
        _accountId = accountId;
        _guid = guid;
    }
    return self;
}

- (void)updateDisplayUnits:(NSArray<NSDictionary *> *)displayUnits {
    [self _updateDisplayUnits:displayUnits];
}

// be sure to call off the main thread
- (void)_updateDisplayUnits:(NSArray<NSDictionary*> *)displayUnits {
    NSMutableArray *units = [NSMutableArray new];
    NSMutableArray *tempArray = [displayUnits mutableCopy];
    for (NSDictionary *obj in tempArray) {
        CleverTapDisplayUnit *displayUnit = [[CleverTapDisplayUnit alloc] initWithJSON:obj];
        [units addObject:displayUnit];
    }
    _displayUnits = units;
    [self notifyUpdate];
}

- (NSArray *)displayUnits {
    if (!self.isInitialized) return nil;
    return _displayUnits;
}

- (void)notifyUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(displayUnitsDidUpdate)]) {
        [self.delegate displayUnitsDidUpdate];
    }
}

@end
