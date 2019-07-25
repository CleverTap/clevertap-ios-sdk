
#import <Foundation/Foundation.h>

@interface CTUriHelper : NSObject

+ (NSDictionary *)getUrchinFromUri:(NSString *)uri withSourceApp:(NSString *)sourceApp;
+ (NSDictionary *)getQueryParameters:(NSURL *)url andDecode:(BOOL)decode;

@end
