#import <Foundation/Foundation.h>

@interface CTUtils : NSObject
+ (NSString *)urlEncodeString:(NSString*)s;
+ (BOOL)doesString:(NSString *)s startWith:(NSString *)prefix;
+ (NSString *)deviceTokenStringFromData:(NSData *)tokenData;
+ (double)toTwoPlaces:(double)x;
+ (BOOL)isNullOrEmpty:(id)obj;
+ (NSString *)jsonObjectToString:(id)object;
+ (NSString *)getKeyWithSuffix:(NSString *)suffix accountID:(NSString *)accountID;
@end
