#import "CTTypeDescription.h"

@implementation CTTypeDescription

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy];
    }
    return self;
}

@end
