#import "CTObjectSerializerConfig.h"
#import "CTTypeDescription.h"
#import "CTEnumDescription.h"
#import "CTClassDescription.h"

@implementation CTObjectSerializerConfig {
    NSDictionary *_classes;
    NSDictionary *_enums;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSMutableDictionary *classDescriptions = [NSMutableDictionary dictionary];
        for (NSDictionary *dict in dictionary[@"classes"]) {
            NSString *superclassName = dict[@"superclass"];
            CTClassDescription *superclassDescription = superclassName ? classDescriptions[superclassName] : nil;
            CTClassDescription *classDescription = [[CTClassDescription alloc] initWithSuperclassDescription:superclassDescription
                                                                                                  dictionary:dict];
            classDescriptions[classDescription.name] = classDescription;
        }
        
        NSMutableDictionary *enumDescriptions = [NSMutableDictionary dictionary];
        for (NSDictionary *dict in dictionary[@"enums"]) {
            CTEnumDescription *enumDescription = [[CTEnumDescription alloc] initWithDictionary:dict];
            enumDescriptions[enumDescription.name] = enumDescription;
        }
        
        _classes = [classDescriptions copy];
        _enums = [enumDescriptions copy];
    }
    
    return self;
}

- (NSArray *)classDescriptions {
    return _classes.allValues;
}

- (CTEnumDescription *)enumWithName:(NSString *)name {
    return _enums[name];
}

- (CTClassDescription *)classWithName:(NSString *)name {
    return _classes[name];
}

- (CTTypeDescription *)typeWithName:(NSString *)name {
    CTEnumDescription *enumDescription = [self enumWithName:name];
    if (enumDescription) {
        return enumDescription;
    }
    
    CTClassDescription *classDescription = [self classWithName:name];
    if (classDescription) {
        return classDescription;
    }
    return nil;
}

@end
