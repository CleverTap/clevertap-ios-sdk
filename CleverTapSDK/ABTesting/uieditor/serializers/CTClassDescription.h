#import "CTTypeDescription.h"

@interface CTClassDescription : CTTypeDescription

@property (nonatomic, readonly) CTClassDescription *superclassDescription;
@property (nonatomic, readonly) NSArray *propertyDescriptions;
@property (nonatomic, readonly) NSArray *delegateDetails;

- (instancetype)initWithSuperclassDescription:(CTClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary;

- (BOOL)isDescriptionForKindOfClass:(Class)aClass;

@end

@interface CTDelegateDetail : NSObject

@property (nonatomic, readonly) NSString *selectorName;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

