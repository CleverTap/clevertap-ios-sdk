#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CTUtils : NSObject

+ (NSString *)urlEncodeString:(NSString*)s;
+ (BOOL)doesString:(NSString *)s startWith:(NSString *)prefix;
+ (NSString *)deviceTokenStringFromData:(NSData *)tokenData;
+ (double)toTwoPlaces:(double)x;
+ (BOOL)isNullOrEmpty:(id)obj;
+ (NSString *)jsonObjectToString:(id)object;
+ (NSString *)getKeyWithSuffix:(NSString *)suffix accountID:(NSString *)accountID;
+ (void)runSyncMainQueue:(void (^)(void))block;
+ (double)haversineDistance:(CLLocationCoordinate2D)coordinateA coordinateB:(CLLocationCoordinate2D)coordinateB;
+ (NSNumber * _Nullable)numberFromString:(NSString * _Nullable)string;
+ (NSNumber * _Nullable)numberFromString:(NSString * _Nullable)string withLocale:(NSLocale * _Nullable)locale;

@end
