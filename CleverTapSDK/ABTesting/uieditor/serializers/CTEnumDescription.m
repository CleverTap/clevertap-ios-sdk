#import "CTEnumDescription.h"

@implementation CTEnumDescription {
    NSMutableDictionary *_values;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {    
    if (dictionary[@"flag_set"] == nil || dictionary[@"base_type"] == nil || dictionary[@"values"] == nil) return nil;
    self = [super initWithDictionary:dictionary];
    if (self) {
        _flagSet = [dictionary[@"flag_set"] boolValue];
        _baseType = [dictionary[@"base_type"] copy];
        _values = [NSMutableDictionary dictionary];
        
        for (NSDictionary *value in dictionary[@"values"]) {
            _values[value[@"value"]] = value[@"display_name"];
        }
    }
    return self;
}

- (NSArray *)allValues {
    return _values.allKeys;
}


@end
