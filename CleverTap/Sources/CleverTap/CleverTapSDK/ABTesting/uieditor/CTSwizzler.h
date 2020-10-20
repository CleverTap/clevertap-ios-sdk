#import <Foundation/Foundation.h>

#define MAPTABLE_ID(x) (__bridge id)((void *)x)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
typedef void (^swizzleBlock)();
#pragma clang diagnostic pop

@interface CTSwizzler : NSObject

+ (void)ct_swizzleSelector:(SEL)aSelector onClass:(Class)aClass withBlock:(swizzleBlock)block named:(NSString *)aName;
+ (void)ct_unswizzleSelector:(SEL)aSelector onClass:(Class)aClass named:(NSString *)aName;
+ (void)printSwizzles;

@end

