
#import "CTUIUtils.h"

#define CTSPMBundlePath @"/CleverTapSDK_CleverTapSDK.bundle/"

@implementation CTUIUtils

+ (NSBundle *)bundle {
    return [self bundle:self.class];
}

+ (NSBundle *)bundle:(Class)bundleClass {
    NSString *spmBundleAt = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:CTSPMBundlePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:spmBundleAt]) {
        return [NSBundle bundleWithPath:spmBundleAt];
    }
    return [NSBundle bundleForClass:bundleClass];
}

+ (UIImage *)getImageForName:(NSString *)name {
    return [UIImage imageNamed:name inBundle:[self bundle] compatibleWithTraitCollection:nil];
}

+ (UIApplication * _Nullable)getSharedApplication {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return [UIApplication performSelector:@selector(sharedApplication)];
    }
    return nil;
}

+ (UIColor *)ct_colorWithHexString:(NSString *)string {
    return  [self ct_colorWithHexString:string withAlpha:1.0];
}

+ (UIColor *)ct_colorWithHexString:(NSString *)string withAlpha:(CGFloat)alpha {
    
    if (![string isKindOfClass:[NSString class]] || [string length] == 0) {
        return [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    }
    
    // Convert hex string to an integer
    unsigned int hexint = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet
                                       characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexint];
    
    // Create color object, specifying alpha
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    
    return color;
}

@end
