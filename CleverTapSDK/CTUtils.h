#import <Foundation/Foundation.h>

@interface CTUtils : NSObject

+ (NSString *)dictionaryToJsonString:(NSDictionary *)dict;
+ (NSString *)urlEncodeString:(NSString*)s;
+ (BOOL)doesString:(NSString *)s startWith:(NSString *)prefix;
+ (NSString *)deviceTokenStringFromData:(NSData *)tokenData;
+ (double)toTwoPlaces:(double)x;
+ (BOOL)isNullOrEmpty:(id)obj;
+ (NSString *)jsonObjectToString:(id)object;
@end
