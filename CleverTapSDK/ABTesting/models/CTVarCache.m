
#import "CTVarCache.h"

@interface CTVarCache() {}
@property (strong, nonatomic) NSMutableDictionary *vars;
@end

@implementation CTVarCache

- (instancetype)init {
    self = [super init];
    if (self) {
        _vars = [NSMutableDictionary new];
    }
    return self;
}

- (void)reset {
    @synchronized (self.vars) {
        for (CTVar *var in [self.vars allValues]) {
            [var clearValue];
        }
    }
}

- (void)registerVarWithName:(NSString*)name type:(CTVarType)type andValue:(id)value {
    @synchronized (self.vars) {
        CTVar *existing = self.vars[name];
        if (!existing) {
            self.vars[name] = [[CTVar alloc] initWithName:name type:type andValue:value];
        } else if (value != nil) {  // can't update using a nil value; if you want to remove the value use clearVarWithName
            [existing updateWithValue:value andType:type];
        }
    }
}

- (CTVar*)getVarWithName:(NSString*)name {
    @synchronized (self.vars) {
        return self.vars[name];
    }
}

- (void)clearVarWithName:(NSString*)name {
    @synchronized (self.vars) {
        CTVar *existing = self.vars[name];
        if (existing) {
           [existing clearValue];
        }
    }
}

- (NSArray<NSDictionary*>* _Nonnull)serializeVars {
    @synchronized (self.vars) {
        if (self.vars == nil) {
            return @[];
        }
        NSMutableArray *ret = [NSMutableArray new];
        for (CTVar *var in [self.vars allValues]) {
            [ret addObject:[var toJSON]];
        }
        return ret;
    }
}

@end
