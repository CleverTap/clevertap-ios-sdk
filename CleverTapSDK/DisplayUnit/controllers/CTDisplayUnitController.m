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
    @synchronized (self) {
        NSArray *units = self.displayUnits;
        return units.count > 0 ? units : nil;
    }
}

- (CleverTapDisplayUnit *)getDisplayUnitForID:(NSString *)unitID {
    if (unitID.length == 0) return nil;
    @synchronized (self) {
        for (CleverTapDisplayUnit *displayUnit in self.displayUnits) {
            if ([displayUnit.unitID isEqualToString:unitID]) {
                return displayUnit;
            }
        }
    }
    return nil;
}

- (void)updateDisplayUnits:(NSArray<CleverTapDisplayUnit *> *)displayUnits {
    @synchronized (self) {
        _displayUnits = [displayUnits copy];
    }
}

- (void)reset {
    @synchronized (self) {
        _displayUnits = nil;
    }
}

- (NSArray *)displayUnits {
    if (!self.isInitialized) return nil;
    return _displayUnits;
}

@end
