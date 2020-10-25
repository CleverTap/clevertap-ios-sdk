#import "CTTypeDescription.h"

@interface CTEnumDescription : CTTypeDescription

@property (nonatomic, assign, getter=isFlagsSet, readonly) BOOL flagSet;
@property (nonatomic, copy, readonly) NSString *baseType;

- (NSArray *)allValues;

@end

