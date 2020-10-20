#import <Foundation/Foundation.h>

@interface NSInvocation (CTHelper)

- (void)ct_setArgumentsFromArray:(NSArray *)argumentArray;
- (id)ct_returnValue;

@end

