#import <Foundation/Foundation.h>

@interface CTLogger : NSObject

+ (void)setDebugLevel:(int)level;
+ (int)getDebugLevel;
+ (void)logInternalError:(NSException *)e;
@end
