#import <UIKit/UIKit.h>
#import "CTInAppUtils.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTInAppResources.h"
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
    if (!_type) {
        _type = @(CTInAppTypeUnknown);
    }
    return [_type integerValue];
}

+ (NSBundle *)bundle {
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CTInAppResources bundle];
#endif
}

+ (NSString *)XibNameForControllerName:(NSString *)controllerName {
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CTInAppResources XibNameForControllerName:controllerName];
#endif
}

+ (UIImage *)imageForName:(NSString *)name type:(NSString *)type {
#if CLEVERTAP_NO_INAPP_SUPPORT
    return nil;
#else
    return [CTInAppResources imageForName:name type:type];
#endif

}

+(UIColor * _Nullable)ct_colorWithHexString:(NSString *)string{
    
    return  [self ct_colorWithHexString:string withAlpha:1.0];
}

+ (UIColor * _Nullable)ct_colorWithHexString:(NSString *)string withAlpha:(CGFloat)alpha{
    
    if (![string isKindOfClass:[NSString class]] || [string length] == 0) {
        return [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    }
    
    // Convert hex string to an integer
    unsigned int hexint = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet
                                       characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexint];
    
    // Create color object, specifying alpha
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    
    return color;
    
}

@end
