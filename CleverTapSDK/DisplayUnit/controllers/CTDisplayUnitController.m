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

#pragma mark - CleverTapDisplayUnitCache

- (NSArray<CleverTapDisplayUnit *> *)getAllDisplayUnits {
    NSArray *units = self.displayUnits;
    return units ?: @[];
}

- (CleverTapDisplayUnit *)getDisplayUnitForID:(NSString *)unitID {
    if (unitID.length == 0) return nil;
    for (CleverTapDisplayUnit *displayUnit in self.displayUnits) {
        if ([displayUnit.unitID isEqualToString:unitID]) {
            return displayUnit;
        }
    }
    return nil;
}

- (void)updateDisplayUnits:(NSArray<NSDictionary *> *)displayUnits {
    [self _updateDisplayUnits:displayUnits];
}

- (void)reset {
    _displayUnits = nil;
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
}

- (NSArray *)displayUnits {
    if (!self.isInitialized) return nil;
    return _displayUnits;
}

@end
