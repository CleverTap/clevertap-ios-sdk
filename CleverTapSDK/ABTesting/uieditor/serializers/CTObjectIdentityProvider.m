#import "CTObjectIdentityProvider.h"
#import "CTObjectSequenceGenerator.h"

@implementation CTObjectIdentityProvider {
    NSMapTable *_objectToIdentifierMap;
    CTObjectSequenceGenerator *_objectSequence;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _objectToIdentifierMap = [NSMapTable weakToStrongObjectsMapTable];
        _objectSequence = [[CTObjectSequenceGenerator alloc] init];
    }
    return self;
}

- (NSString *)identifierForObject:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    NSString *identifier = [_objectToIdentifierMap objectForKey:object];
    if (identifier == nil) {
        identifier = [NSString stringWithFormat:@"$%" PRIi32, [_objectSequence nextValue]];
        [_objectToIdentifierMap setObject:identifier forKey:object];
    }
    return identifier;
}


@end
