#import <Foundation/Foundation.h>
#import "CTVar.h"

@interface CTVarCache : NSObject

- (void)registerVarWithName:(NSString* _Nonnull)name type:(CTVarType)type andValue:(id _Nullable)value;
- (CTVar* _Nullable)getVarWithName:(NSString* _Nonnull)name;
- (void)clearVarWithName:(NSString* _Nonnull)name;
- (void)reset;
- (NSArray<NSDictionary*>* _Nonnull)serializeVars;

@end
