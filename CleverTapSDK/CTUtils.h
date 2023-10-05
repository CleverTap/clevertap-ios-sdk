#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CTUtils : NSObject

+ (NSString *)dictionaryToJsonString:(NSDictionary *)dict;
+ (NSString *)urlEncodeString:(NSString*)s;
+ (BOOL)doesString:(NSString *)s startWith:(NSString *)prefix;
+ (NSString *)deviceTokenStringFromData:(NSData *)tokenData;
+ (double)toTwoPlaces:(double)x;
+ (BOOL)isNullOrEmpty:(id)obj;
+ (NSString *)jsonObjectToString:(id)object;
+ (UIApplication *)getSharedApplication;
+ (BOOL)runningInsideAppExtension;
+ (void)runSyncMainQueue:(void (^)(void))block;
+ (void)openURL:(NSURL *)ctaURL forModule:(NSString *)module;
@end
