#import <Foundation/Foundation.h>
#import "CTABTestUtils.h"

@interface CTVar : NSObject

- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name type:(CTVarType)type andValue:(id _Nullable)value;
- (void)updateWithValue:(id _Nonnull)value andType:(CTVarType)type;

- (void)clearValue;
- (NSNumber * _Nullable)numberValue;
- (NSString * _Nullable)stringValue;
- (NSArray<id>* _Nullable)arrayValue;
- (NSDictionary<NSString *, id>* _Nullable)dictionaryValue;
- (NSDictionary* _Nonnull)toJSON;

@end
