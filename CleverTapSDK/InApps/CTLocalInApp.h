#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CTLocalInAppType) {
    ALERT,
    HALF_INTERSTITIAL
};

/*!
 
 @abstract
 The `CTLocalInApp` represents the builder class to display local in-app.
 */
@interface CTLocalInApp : NSObject

/*!
 @method
 
 @abstract
 Initializes and returns an instance of the CTLocalInApp.
 
 @discussion
 This method have all parameters as required fields.
 
 @param inAppType the local in-app type, ALERT or HALF_INTERSTITIAL
 @param titleText in-app title text
 @param messageText in-app message text
 @param followDeviceOrientation If YES, in-app will display in both orientation. If NO, in-app will not display in landscape orientation
 @param positiveBtnText in-app positive button text, eg "Allow"
 @param negativeBtnText in-app negative button text, eg "Cancel"
 */
- (instancetype)initWithInAppType:(CTLocalInAppType)inAppType
                        titleText:(NSString *)titleText
                      messageText:(NSString *)messageText
          followDeviceOrientation:(BOOL)followDeviceOrientation
                  positiveBtnText:(NSString *)positiveBtnText
                  negativeBtnText:(NSString *)negativeBtnText;

/**
 Returns NSDictionary having all local in-app settings as key-value pair.
 */
- (NSDictionary *)getLocalInAppSettings;

/* -----------------
 * Optional methods.
 * -----------------
 */
- (void)setBackgroundColor:(NSString *)backgroundColor;
- (void)setTitleTextColor:(NSString *)titleTextColor;
- (void)setMessageTextColor:(NSString *)messageTextColor;
- (void)setBtnBorderRadius:(NSString *)btnBorderRadius;
- (void)setBtnTextColor:(NSString *)btnTextColor;
- (void)setBtnBorderColor:(NSString *)btnBorderColor;
- (void)setBtnBackgroundColor:(NSString *)btnBackgroundColor;
- (void)setImageUrl:(NSString *)imageUrl;

/**
 If fallbackToSettings is YES and permission is denied, then we fallback to app’s notification settings.
 If fallbackToSettings is NO, then we just throw a log saying permission is denied.
 */
- (void)setFallbackToSettings:(BOOL)fallbackToSettings;

/**
 If skipAlert is YES, then we skip the settings alert dialog shown before opening app notification settings.
 */
- (void)setSkipSettingsAlert:(BOOL)skipAlert;

@end

NS_ASSUME_NONNULL_END
