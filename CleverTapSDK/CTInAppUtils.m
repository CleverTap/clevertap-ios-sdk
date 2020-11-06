
#import <UIKit/UIKit.h>
#import "CTInAppUtils.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTUIUtils.h"
#endif

static NSDictionary *_inAppTypeMap;

@implementation CTInAppUtils

+ (CTInAppType)inAppTypeFromString:(NSString*)type {
    if (_inAppTypeMap == nil) {
        _inAppTypeMap = @{
            @"custom-html": @(CTInAppTypeHTML),
            @"interstitial": @(CTInAppTypeInterstitial),
            @"cover": @(CTInAppTypeCover),
            @"header-template": @(CTInAppTypeHeader),
            @"footer-template": @(CTInAppTypeFooter),
            @"half-interstitial": @(CTInAppTypeHalfInterstitial),
            @"alert-template": @(CTInAppTypeAlert),
            @"interstitial-image": @(CTInAppTypeInterstitialImage),
            @"half-interstitial-image": @(CTInAppTypeHalfInterstitialImage),
            @"cover-image": @(CTInAppTypeCoverImage)
        };
    }
    
    NSNumber *_type = type != nil ? _inAppTypeMap[type] : @(CTInAppTypeUnknown);
    if (_type == nil) {
        _type = @(CTInAppTypeUnknown);
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
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CTUIUtils XibNameForControllerName:controllerName];
#endif
}

@end
