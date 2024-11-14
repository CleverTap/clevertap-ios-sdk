#include <math.h>
#import "CTUtils.h"

@implementation CTUtils

+ (NSString *)urlEncodeString:(NSString*)s {
    if (!s) return nil;
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *) [s UTF8String];
    int sourceLen = (int) strlen((const char *) source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (BOOL)doesString:(NSString *)s startWith:(NSString *)prefix {
    @try {
        if (s.length < prefix.length) return NO;
        
        if (s != nil && ![s isEqualToString:@""] && prefix != nil && ![prefix isEqualToString:@""]) {
            return [[s substringToIndex:prefix.length] isEqualToString:prefix];
        }
    }
    @catch (NSException *exception) {
        // no-op
    }
    return NO;
}

+ (NSString *)deviceTokenStringFromData:(NSData *)tokenData {
    if (!tokenData || tokenData.length == 0) return nil;
    const unsigned *tokenBytes = [tokenData bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    NSString *deviceTokenString = [NSString stringWithFormat:@"%@", hexToken];
    return deviceTokenString;
}

+ (double)toTwoPlaces:(double)x {
    double result = x * 100;
    result = round(result);
    result = result / 100;
    return result;
}

+ (BOOL)isNullOrEmpty:(id)obj
{
    // Need to check for NSString to support RubyMotion.
    // Ruby String respondsToSelector(count) is true for count: in RubyMotion
    return obj == nil
    || ([obj respondsToSelector:@selector(length)] && [obj length] == 0)
    || ([obj respondsToSelector:@selector(count)]
        && ![obj isKindOfClass:[NSString class]] && [obj count] == 0);
}

+ (NSString *)jsonObjectToString:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                           options:0
                                                             error:&error];
        if (error) {
            return @"";
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    @catch (NSException *exception) {
        return @"";
    }
}

+ (NSString *)getKeyWithSuffix:(NSString *)suffix
                     accountID:(NSString *)accountID {
    return [NSString stringWithFormat:@"%@:%@", accountID, suffix];
}

+ (void)runSyncMainQueue:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (double)haversineDistance:(CLLocationCoordinate2D)coordinateA coordinateB:(CLLocationCoordinate2D)coordinateB {
    // The Earth radius ranges from a maximum of about 6378 km (equatorial)
    // to a minimum of about 6357 km (polar).
    // A globally-average value is usually considered to be 6371 km (6371e3).
    // This method uses 6378.2 km as the radius since this is the value
    // used by the backend and calculations should produce the same result.
    double EARTH_DIAMETER = 2 * 6378.2;
    
    double RAD_CONVERT = M_PI / 180;
    double phi1 = coordinateA.latitude * RAD_CONVERT;
    double phi2 = coordinateB.latitude * RAD_CONVERT;
    
    double delta_phi = (coordinateB.latitude - coordinateA.latitude) * RAD_CONVERT;
    double delta_lambda = (coordinateB.longitude - coordinateA.longitude) * RAD_CONVERT;
    
    double sin_phi = sin(delta_phi / 2);
    double sin_lambda = sin(delta_lambda / 2);
    
    double a = sin_phi * sin_phi + cos(phi1) * cos(phi2) * sin_lambda * sin_lambda;
    // Distance in km
    double distance = EARTH_DIAMETER * atan2(sqrt(a), sqrt(1 - a));
    return distance;
}

+ (NSNumber * _Nullable)numberFromString:(NSString * _Nullable)string {
    return [CTUtils numberFromString:string withLocale:nil];
}

+ (NSNumber * _Nullable)numberFromString:(NSString * _Nullable)string withLocale:(NSLocale * _Nullable)locale {
    if (string) {
        NSScanner *scanner = [NSScanner scannerWithString:string];
        if (locale) {
            [scanner setLocale:locale];
        }
        
        double d = 0;
        if ([scanner scanDouble:&d] && [scanner isAtEnd]) {
            return @(d);
        }
    }
    return nil;
}

+ (NSString * _Nullable)getNormalizedName:(NSString * _Nullable)name {
    if (name) {
        // Lowercase with English locale for consistent behavior with the backend
        // and across different device locales.
        NSString *normalizedName = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSLocale *englishLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        normalizedName = [normalizedName lowercaseStringWithLocale:englishLocale];
        normalizedName = [normalizedName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return normalizedName;
    }
    
    return nil;
}

+ (BOOL)areEqualNormalizedName:(NSString * _Nullable)firstName
                       andName:(NSString * _Nullable)secondName {
    if (firstName == nil && secondName == nil) {
        return YES;
    }
    
    if (firstName == nil || secondName == nil) {
        return NO;
    }
    
    NSString *normalizedFirstName = [CTUtils getNormalizedName:firstName];
    NSString *normalizedSecondName = [CTUtils getNormalizedName:secondName];
    
    return [normalizedFirstName isEqualToString:normalizedSecondName];
}

@end
