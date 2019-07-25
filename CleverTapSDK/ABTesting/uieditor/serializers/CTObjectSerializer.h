#import <Foundation/Foundation.h>

@class CTClassDescription;
@class CTObjectSerializerContext;
@class CTObjectSerializerConfig;
@class CTObjectIdentityProvider;

@interface CTObjectSerializer : NSObject

- (instancetype)initWithConfiguration:(CTObjectSerializerConfig *)configuration
        objectIdentityProvider:(CTObjectIdentityProvider *)objectIdentityProvider;

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject;

@end

