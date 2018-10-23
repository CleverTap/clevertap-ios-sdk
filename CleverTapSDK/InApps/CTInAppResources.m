#import "CTInAppResources.h"

@implementation CTInAppResources

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:self.class];
}

+ (NSString *)XibNameForControllerName:(NSString *)controllerName {
    NSMutableString *xib = [NSMutableString stringWithString:controllerName];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [xib appendString:@"~iphoneport"];
    } else {
        [xib appendString:@"~ipad"];
    }
    return [xib copy];
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
