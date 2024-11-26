
#import <UIKit/UIKit.h>
#import "CTInAppUtils.h"
#import "CTConstants.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTUIUtils.h"
#endif

static NSDictionary<NSString *, NSNumber *> *_inAppTypeMap;
static NSDictionary<NSNumber *, NSString *> *_inAppTypeToStringMap;
static NSDictionary<NSString *, NSNumber *> *_inAppActionTypeStringToTypeMap;
static NSDictionary<NSNumber *, NSString *> *_inAppActionTypeTypeToStringMap;

@implementation CTInAppUtils

+ (NSDictionary<NSString *, NSNumber *> *)inAppTypeStringToTypeMap {
    if (_inAppTypeMap == nil) {
        _inAppTypeMap = @{
            CLTAP_INAPP_HTML_TYPE: @(CTInAppTypeHTML),
            @"interstitial": @(CTInAppTypeInterstitial),
            @"cover": @(CTInAppTypeCover),
            @"header-template": @(CTInAppTypeHeader),
            @"footer-template": @(CTInAppTypeFooter),
            @"half-interstitial": @(CTInAppTypeHalfInterstitial),
            @"alert-template": @(CTInAppTypeAlert),
            @"interstitial-image": @(CTInAppTypeInterstitialImage),
            @"half-interstitial-image": @(CTInAppTypeHalfInterstitialImage),
            @"cover-image": @(CTInAppTypeCoverImage),
            @"custom-code": @(CTInAppTypeCustom)
        };
    }
    return _inAppTypeMap;
}

+ (NSDictionary<NSNumber *, NSString *> *)inAppTypeTypeToStringMap {
    if (_inAppTypeToStringMap == nil) {
        NSDictionary *dict = [self inAppTypeStringToTypeMap];
        NSMutableDictionary *swapped = [NSMutableDictionary new];
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            swapped[value] = key;
        }];
        _inAppTypeToStringMap = [swapped copy];
    }
    return _inAppTypeToStringMap;
}

+ (CTInAppType)inAppTypeFromString:(NSString*)type {
    NSNumber *_type = type != nil ? [self inAppTypeStringToTypeMap][type] : @(CTInAppTypeUnknown);
    if (_type == nil) {
        _type = @(CTInAppTypeUnknown);
    }
    return [_type integerValue];
}

+ (NSString * _Nonnull)inAppTypeString:(CTInAppType)type {
    return self.inAppTypeTypeToStringMap[@(type)];
}

+ (NSDictionary<NSNumber *, NSString *> *)inAppActionTypeTypeToStringMap {
    if (_inAppActionTypeTypeToStringMap == nil) {
        NSDictionary *dict = [self inAppActionTypeStringToTypeMap];
        NSMutableDictionary *swapped = [NSMutableDictionary new];
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            swapped[value] = key;
        }];
        _inAppActionTypeTypeToStringMap = [swapped copy];
    }
    return _inAppActionTypeTypeToStringMap;
}

+ (NSDictionary<NSString *, NSNumber *> *)inAppActionTypeStringToTypeMap {
    if (_inAppActionTypeStringToTypeMap == nil) {
        _inAppActionTypeStringToTypeMap = @{
            @"close": @(CTInAppActionTypeClose),
            @"url": @(CTInAppActionTypeOpenURL),
            @"kv": @(CTInAppActionTypeKeyValues),
            @"custom-code": @(CTInAppActionTypeCustom),
            @"rfp": @(CTInAppActionTypeRequestForPermission)
        };
    }
    return _inAppActionTypeStringToTypeMap;
}

+ (CTInAppActionType)inAppActionTypeFromString:(NSString* _Nonnull)type {
    NSNumber *_type = type != nil ? [self inAppActionTypeStringToTypeMap][type] : @(CTInAppActionTypeUnknown);
    if (_type == nil) {
        _type = @(CTInAppActionTypeUnknown);
    }
    return [_type integerValue];
}

+ (NSString * _Nonnull)inAppActionTypeString:(CTInAppActionType)type {
    return self.inAppActionTypeTypeToStringMap[@(type)];
}

+ (NSBundle *)bundle {
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CTUIUtils bundle];
#endif
}

+ (NSString *)getXibNameForControllerName:(NSString *)controllerName {
#if CLEVERTAP_NO_INAPP_SUPPORT || TARGET_OS_TV
    return nil;
#else    
    NSMutableString *xib = [NSMutableString stringWithString:controllerName];
    BOOL landscape = [CTUIUtils isDeviceOrientationLandscape];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (landscape) {
            [xib appendString:@"~iphoneland"];
        } else {
            [xib appendString:@"~iphoneport"];
        }
    } else {
        if (landscape) {
            [xib appendString:@"~ipadland"];
        } else {
            [xib appendString:@"~ipad"];
        }
    }
    return [xib copy];
#endif
}

+ (NSMutableDictionary *)getParametersFromURL:(NSString *)urlString {
    NSMutableDictionary *mutableParams = [[NSMutableDictionary alloc] init];
    // Try to extract the parameters from the URL and overrite default dl if applicable
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSArray *comps = [urlString componentsSeparatedByString:@"?"];
    if ([comps count] >= 2) {
        // Extract the parameters and store in params dictionary
        NSString *query = comps[1];
        for (NSString *param in [query componentsSeparatedByString:@"&"]) {
            NSArray *elts = [param componentsSeparatedByString:@"="];
            if ([elts count] < 2) continue;
            params[elts[0]] = [elts[1] stringByRemovingPercentEncoding];
        }
        
        // Check for wzrk_c2a key, if present update its value after parsing with __dl__
        NSString *c2a = params[CLTAP_PROP_WZRK_CTA];
        if (c2a) {
            c2a = [c2a stringByRemovingPercentEncoding];
            NSArray *parts = [c2a componentsSeparatedByString:CLTAP_URL_PARAM_DL_SEPARATOR];
            if (parts && [parts count] == 2) {
                params[CLTAP_PROP_WZRK_CTA] = parts[0];
                mutableParams[@"deeplink"] = [NSURL URLWithString:parts[1]];
            }
        }
        
        mutableParams[@"params"] = [params mutableCopy];
    }
    
    return mutableParams;
}

@end
