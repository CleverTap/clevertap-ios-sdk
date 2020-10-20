#import <Foundation/Foundation.h>

@interface CTPropertySelectorParameterDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *type;

@end

@interface CTPropertySelectorDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly) NSString *selectorName;
@property (nonatomic, readonly) NSString *returnType;
@property (nonatomic, readonly) NSArray *parameters;

@end

@interface CTPropertyDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) BOOL readonly;
@property (nonatomic, readonly) BOOL nofollow;
@property (nonatomic, readonly) BOOL useKeyValueCoding;
@property (nonatomic, readonly) BOOL useInstanceVariableAccess;

@property (nonatomic, readonly) CTPropertySelectorDescription *getSelectorDescription;
@property (nonatomic, readonly) CTPropertySelectorDescription *setSelectorDescription;

- (BOOL)shouldReadPropertyValueForObject:(NSObject *)object;

- (NSValueTransformer *)valueTransformer;

@end

