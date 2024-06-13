
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
    CTInAppTypeCustom
};

typedef NS_ENUM(NSUInteger, CTInAppActionType){
    CTInAppActionTypeUnknown,
    CTInAppActionTypeClose,
    CTInAppActionTypeOpenURL,
    CTInAppActionTypeKeyValues,
    CTInAppActionTypeCustom,
    CTInAppActionTypeRequestForPermission
};

@interface CTInAppUtils : NSObject

+ (CTInAppType)inAppTypeFromString:(NSString* _Nonnull)type;
+ (CTInAppActionType)inAppActionTypeFromString:(NSString* _Nonnull)type;
+ (NSBundle *_Nullable)bundle;
+ (NSString *_Nullable)getXibNameForControllerName:(NSString *_Nonnull)controllerName;

@end
