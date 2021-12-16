#import <Foundation/Foundation.h>
#import <CleverTapSDK/CleverTap.h>

@interface CleverTap (Tests)

+(void)notfityTestAppLaunch;
-(NSDictionary*)getBatchHeader;

@end
