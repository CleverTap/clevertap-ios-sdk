
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTUIUtils : NSObject

+ (NSBundle *)bundle;
+ (NSBundle *)bundle:(Class)bundleClass;
+ (UIApplication *_Nullable)getSharedApplication;

+ (UIImage *)imageForName:(NSString *)name type:(NSString *)type;

+ (UIColor *_Nullable)ct_colorWithHexString:(NSString *_Nonnull)string;
+ (UIColor *_Nullable)ct_colorWithHexString:(NSString *_Nonnull)string withAlpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
