
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTUIUtils : NSObject

+ (NSBundle *)bundle;
+ (NSBundle *)bundle:(Class)bundleClass;
+ (UIApplication * _Nullable)getSharedApplication;
+ (UIWindow * _Nullable)getKeyWindow;
#if !(TARGET_OS_TV)
+ (BOOL)isDeviceOrientationLandscape;
#endif
+ (BOOL)isUserInterfaceIdiomPad;
+ (CGFloat)getLeftMargin;

+ (UIImage *)getImageForName:(NSString *)name;

+ (UIColor *)ct_colorWithHexString:(NSString *)string;
+ (UIColor *)ct_colorWithHexString:(NSString *)string withAlpha:(CGFloat)alpha;

+ (BOOL)runningInsideAppExtension;
+ (void)openURL:(NSURL *)ctaURL forModule:(NSString *)ctModule;

@end

NS_ASSUME_NONNULL_END
