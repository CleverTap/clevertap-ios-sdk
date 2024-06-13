
#import <UIKit/UIKit.h>
#import "CTInAppUtils.h"
#import "CTConstants.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTUIUtils.h"
#endif

static NSDictionary *_inAppTypeMap;
static NSDictionary *_inAppActionTypeMap;

@implementation CTInAppUtils

+ (CTInAppType)inAppTypeFromString:(NSString*)type {
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
    
    NSNumber *_type = type != nil ? _inAppTypeMap[type] : @(CTInAppTypeUnknown);
    if (_type == nil) {
        _type = @(CTInAppTypeUnknown);
    }
    return [_type integerValue];
}

+ (CTInAppActionType)inAppActionTypeFromString:(NSString* _Nonnull)type {
    if (_inAppActionTypeMap == nil) {
        _inAppActionTypeMap = @{
            @"close": @(CTInAppActionTypeClose),
            @"url": @(CTInAppActionTypeOpenURL),
            @"kv": @(CTInAppActionTypeKeyValues),
            @"custom-code": @(CTInAppActionTypeCustom),
            @"rfp": @(CTInAppActionTypeRequestForPermission)
        };
    }
    
    NSNumber *_type = type != nil ? _inAppActionTypeMap[type] : @(CTInAppActionTypeUnknown);
    if (_type == nil) {
        _type = @(CTInAppActionTypeUnknown);
    }
    return [_type integerValue];
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

@end
