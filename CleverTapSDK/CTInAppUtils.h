
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CTInAppType){
    CTInAppTypeUnknown,
    CTInAppTypeHTML,
    CTInAppTypeInterstitial,
    CTInAppTypeHalfInterstitial,
    CTInAppTypeCover,
    CTInAppTypeHeader,
    CTInAppTypeFooter,
    CTInAppTypeAlert,
    CTInAppTypeInterstitialImage,
    CTInAppTypeHalfInterstitialImage,
    CTInAppTypeCoverImage,
};

@interface CTInAppUtils : NSObject

+ (CTInAppType)inAppTypeFromString:(NSString*_Nonnull)type;
+ (NSBundle *_Nullable)bundle;
+ (NSString *_Nullable)getXibNameForControllerName:(NSString *_Nonnull)controllerName;
+ (UIColor *_Nullable)ct_colorWithHexString:(NSString *_Nonnull)string;
+ (UIColor *_Nullable)ct_colorWithHexString:(NSString *_Nonnull)string withAlpha:(CGFloat)alpha;

@end
