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

/**
 * Get the CT normalized version of an event or a property name.
 */
+ (NSString * _Nullable)getNormalizedName:(NSString * _Nullable)name;

/**
 * Check if two event/property names are equal with applied CT normalization
 */
+ (BOOL)areEqualNormalizedName:(NSString * _Nullable)firstName andName:(NSString * _Nullable)secondName;

@end
