
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

+ (CTInAppType)inAppTypeFromString:(NSString *_Nonnull)type;
+ (NSString * _Nonnull)inAppTypeString:(CTInAppType)type;
+ (CTInAppActionType)inAppActionTypeFromString:(NSString *_Nonnull)type;
+ (NSString * _Nonnull)inAppActionTypeString:(CTInAppActionType)type;
+ (NSBundle * _Nullable)bundle;
+ (NSString * _Nullable)getXibNameForControllerName:(NSString * _Nonnull)controllerName;
 /**
  * Extracts the parameters from the URL and extracts the deeplink from the call to action if applicable.
  * @param url The URL to process.
  * @return Returns a dictionary with "deeplink" and "params" keys holding the respective values.
  */
+ (NSMutableDictionary * _Nonnull)getParametersFromURL:(NSString * _Nonnull)url;

@end
