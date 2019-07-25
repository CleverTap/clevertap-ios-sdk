#import "CTInAppResources.h"

@implementation CTInAppResources

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:self.class];
}

+ (NSString *)XibNameForControllerName:(NSString *)controllerName {
#if (TARGET_OS_TV)
    return nil;
#else
    NSMutableString *xib = [NSMutableString stringWithString:controllerName];
    UIApplication *sharedApplication = [self getSharedApplication];
    BOOL landscape = UIInterfaceOrientationIsLandscape(sharedApplication.statusBarOrientation);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (landscape) {
            [xib appendString:@"~iphoneland"];
        } else {
            [xib appendString:@"~iphoneport"];
        }
    } else {
        if (landscape) {
            [xib appendString:@"~ipadland"];
        } else {
            [xib appendString:@"~ipad"];
        }
    }
    return [xib copy];
#endif
}

+ (UIImage *)imageForName:(NSString *)name type:(NSString *)type {
    NSString *imagePath = [[self bundle] pathForResource:name ofType:type];
    return [UIImage imageWithContentsOfFile:imagePath];
}

+ (UIApplication *)getSharedApplication {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return [UIApplication performSelector:@selector(sharedApplication)];
    }
    return nil;
}

@end
