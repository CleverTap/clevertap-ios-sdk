#import <Foundation/Foundation.h>

@class CTEnumDescription;
@class CTClassDescription;
@class CTTypeDescription;

@interface CTObjectSerializerConfig : NSObject

@property (nonatomic, readonly) NSArray *classDescriptions;
@property (nonatomic, readonly) NSArray *enumDescriptions;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (CTTypeDescription *)typeWithName:(NSString *)name;
- (CTEnumDescription *)enumWithName:(NSString *)name;
- (CTClassDescription *)classWithName:(NSString *)name;

@end
