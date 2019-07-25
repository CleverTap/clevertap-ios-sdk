
#import "CTUriHelper.h"

@implementation CTUriHelper

+ (NSDictionary *)getUrchinFromUri:(NSString *)uri withSourceApp:(NSString *)sourceApp {
    NSMutableDictionary *referrer = [[NSMutableDictionary alloc] init];
    @try {
        // Don't care for null values - they won't be added anyway
        if (sourceApp != nil && ![sourceApp isEqualToString:@""] && ![sourceApp hasPrefix:@"fb"]) {
            referrer[@"referrer"] = sourceApp;
        }
        @try {
            NSString *source = [self getUtmOrWzrkValue:@"source" fromURI:uri];
            referrer[@"us"] = source;
        }
        @catch (NSException *exception) {}
        @try {
            NSString *medium = [self getUtmOrWzrkValue:@"medium" fromURI:uri];
            referrer[@"um"] = medium;
        }
        @catch (NSException *exception) {}
        @try {
            NSString *campaign = [self getUtmOrWzrkValue:@"campaign" fromURI:uri];
            referrer[@"uc"] = campaign;
        }
        @catch (NSException *exception) {}
        
        NSString *wm = [self getWzrkValueForKey:@"medium" fromURI:uri];
        
        if (wm != nil) {
            NSString *regexString = @"^email$|^social$|^search$";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self matches %@", regexString];
            BOOL isStringValid = [predicate evaluateWithObject:wm];
            if (isStringValid)
                referrer[@"wm"] = wm;
        }
    } @catch (NSException *ignore) {
        // Won't happen
    }
    return referrer;
}

+ (NSString *)getUtmOrWzrkValue:(NSString *)utmKey fromURI:(NSString *)uri {
    // Give preference to utm_*, else, try to look for wzrk_*
    NSString *value;
    if ((value = [self getUtmValueForKey:utmKey fromURI:uri]) != nil
        || (value = [self getWzrkValueForKey:utmKey fromURI:uri]) != nil)
        return value;
    else
        return nil;
}

+ (NSString *)getWzrkValueForKey:(NSString *)key fromURI:(NSString *)uri {
    key = [NSString stringWithFormat:@"wzrk_%@", key];
    id value = [self getValueForKey:key fromURI:uri];
    if ([value isKindOfClass:[NSString class]] && [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        value = nil;
    }
    return value;
}

+ (NSString *)getUtmValueForKey:(NSString *)key fromURI:(NSString *)uri {
    key = [NSString stringWithFormat:@"utm_%@", key];
    id value = [self getValueForKey:key fromURI:uri];
    if ([value isKindOfClass:[NSString class]] && [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        value = nil;
    }
    return value;
}

+ (NSDictionary *)getQueryParameters:(NSURL *)url andDecode:(BOOL)decode {
    if (!url) return @{};
    
    @try {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        for (NSString *param in [[url query] componentsSeparatedByString:@"&"]) {
            NSArray *elts = [param componentsSeparatedByString:@"="];
            if ([elts count] < 2) continue;
            
            if (decode) {
                params[elts[0]] = [elts[1] stringByRemovingPercentEncoding];
            } else {
                params[elts[0]] = elts[1];
            }
        }
        return params;
    } @catch (NSException *e) {
        return @{};
    }
}

+ (NSString *)getValueForKey:(NSString *)key fromURI:(NSString *)uri {
    @try {
        NSDictionary *params = [self getQueryParameters:[NSURL URLWithString:uri] andDecode:false];
        NSString *value = params[key];
        return value;
    } @catch (NSException *e) {
        return nil;
    }
}

@end
