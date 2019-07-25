#import "CTUtils.h"

@implementation CTUtils

+ (NSString *)dictionaryToJsonString:(NSDictionary *)dict {
    if (dict == nil) return nil;
    
    NSData *jsonData;
    @try {
        NSError *error;
        NSMutableDictionary *_cleaned = [NSMutableDictionary new];
        
        for (NSString *key in dict) {
            id value = dict[key];
            if ([value isKindOfClass:[NSDate class]]) {
                continue;
            }
            _cleaned[key] = value;
        }
        
        jsonData = [NSJSONSerialization dataWithJSONObject:_cleaned
                                                   options:0
                                                     error:&error];
        
        return jsonData != nil ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
        
    } @catch (NSException *e) {
        return nil;
    }
}

+ (NSString *)urlEncodeString:(NSString*)s {
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

@end
