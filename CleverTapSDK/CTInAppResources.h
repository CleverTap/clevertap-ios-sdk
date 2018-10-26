#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppResources : NSObject

+ (NSBundle *)bundle;
+ (NSString *)XibNameForControllerName:(NSString *)controllerName;
+ (UIImage *)imageForName:(NSString *)name type:(NSString *)type;
+ (UIApplication *)getSharedApplication;
@end

NS_ASSUME_NONNULL_END
