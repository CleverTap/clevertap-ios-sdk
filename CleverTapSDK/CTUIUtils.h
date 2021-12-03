
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTUIUtils : NSObject

+ (NSBundle *)bundle;
+ (NSBundle *)bundle:(Class)bundleClass;
+ (UIApplication * _Nullable)getSharedApplication;

+ (UIImage *)getImageForName:(NSString *)name;

+ (UIColor *)ct_colorWithHexString:(NSString *)string;
+ (UIColor *)ct_colorWithHexString:(NSString *)string withAlpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
