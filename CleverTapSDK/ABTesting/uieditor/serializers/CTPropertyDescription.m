#import "CTPropertyDescription.h"

@implementation CTPropertySelectorParameterDescription

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (dictionary[@"name"] == nil || dictionary[@"type"] == nil) return nil;
    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy];
        _type = [dictionary[@"type"] copy];
    }
    return self;
}

@end

@implementation CTPropertySelectorDescription

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {

    if (dictionary[@"selector"] == nil || dictionary[@"parameters"] == nil) return nil;

    self = [super init];
    if (self) {
        _selectorName = [dictionary[@"selector"] copy];
        NSMutableArray *parameters = [NSMutableArray arrayWithCapacity:[dictionary[@"parameters"] count]];
        for (NSDictionary *parameter in dictionary[@"parameters"]) {
            [parameters addObject:[[CTPropertySelectorParameterDescription alloc] initWithDictionary:parameter]];
        }
        _parameters = [parameters copy];
        _returnType = [dictionary[@"result"][@"type"] copy]; // optional
    }
    return self;
}

@end

@interface CTPropertyDescription ()

@property (nonatomic, readonly) NSPredicate *predicate;

@end

@implementation CTPropertyDescription

+ (NSValueTransformer *)valueTransformerForType:(NSString *)typeName {
    for (NSString *toTypeName in @[@"NSDictionary", @"NSNumber", @"NSString"]) {
        NSString *toTransformerName = [NSString stringWithFormat:@"CT%@From%@ValueTransformer", toTypeName, typeName];
        NSValueTransformer *toTransformer = [NSValueTransformer valueTransformerForName:toTransformerName];
        if (toTransformer) {
            return toTransformer;
        }
    }
    return [NSValueTransformer valueTransformerForName:@"CTPassThroughValueTransformer"];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    
    if (!dictionary[@"name"]) return nil;
    
    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy]; // required
        _useInstanceVariableAccess = [dictionary[@"use_ivar"] boolValue]; // Optional
        _readonly = [dictionary[@"readonly"] boolValue]; // Optional
        _nofollow = [dictionary[@"nofollow"] boolValue]; // Optional
        
        NSString *predicateFormat = dictionary[@"predicate"]; // Optional
        if (predicateFormat) {
            _predicate = [NSPredicate predicateWithFormat:predicateFormat];
        }
        
        NSDictionary *get = dictionary[@"get"];
        if (get == nil) {
            if (!dictionary[@"type"]) return nil;
            get = @{
                    @"selector": _name,
                    @"result": @{
                            @"type": dictionary[@"type"],
                            @"name": @"value"
                            },
                    @"parameters": @[]
                    };
        }
        
        NSDictionary *set = dictionary[@"set"];
        if (set == nil && _readonly == NO) {
            if (!dictionary[@"type"]) return nil; 
            set = @{
                    @"selector": [NSString stringWithFormat:@"set%@:", _name.capitalizedString],
                    @"parameters": @[
                            @{
                                @"name": @"value",
                                @"type": dictionary[@"type"]
                                }
                            ]
                    };
        }
        
        _getSelectorDescription = [[CTPropertySelectorDescription alloc] initWithDictionary:get];
        if (set) {
            _setSelectorDescription = [[CTPropertySelectorDescription alloc] initWithDictionary:set];
        } else {
            _readonly = YES;
        }
        
        BOOL useKVC = (dictionary[@"use_kvc"] == nil ? YES : [dictionary[@"use_kvc"] boolValue]) && _useInstanceVariableAccess == NO;
        _useKeyValueCoding = useKVC &&
        _getSelectorDescription.parameters.count == 0 &&
        (_setSelectorDescription == nil || _setSelectorDescription.parameters.count == 1);
    }
    
    return self;
}

- (NSString *)type{
    return _getSelectorDescription.returnType;
}

- (NSValueTransformer *)valueTransformer {
    return [[self class] valueTransformerForType:self.type];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p name='%@' type='%@' %@>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.type, self.readonly ? @"readonly" : @""];
}

- (BOOL)shouldReadPropertyValueForObject:(NSObject *)object {
    if (_nofollow) {
        return NO;
    }
    if (_predicate) {
        return [_predicate evaluateWithObject:object];
    }
    return YES;
}

@end
