#import "CTUIUtils.h"
#import "CTConstants.h"

#define CTSPMBundlePath @"/CleverTapSDK_CleverTapSDK.bundle/"

@implementation CTUIUtils

+ (NSBundle *)bundle {
    return [self bundle:self.class];
}

+ (NSBundle *)bundle:(Class)bundleClass {
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSBundle *sourceBundle = [NSBundle bundleForClass:bundleClass];

    // SPM
    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"CleverTapSDK_CleverTapSDK"
                                                                     ofType:@"bundle"]];
    // Cocopaods (static)
    bundle = bundle ? : [NSBundle bundleWithPath:[mainBundle pathForResource:@"CleverTapSDK"
                                                                      ofType:@"bundle"]];
    // Cocopaods (framework)
    bundle = bundle ? : [NSBundle bundleWithPath:[sourceBundle pathForResource:@"CleverTapSDK"
                                                                        ofType:@"bundle"]];
    return bundle ? : sourceBundle;
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

+ (UIWindow * _Nullable)getKeyWindow {
    UIWindow *keyWindow;
    if (@available(iOS 11.0, *)) {
        for (UIWindow *window in [CTUIUtils getSharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    }
    return keyWindow;
}

+ (CGFloat)getLeftMargin {
    CGFloat margin = 0;
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        for (UIWindow *window in [CTUIUtils getSharedApplication].windows) {
            if (window.isKeyWindow) {
                margin = window.safeAreaInsets.left;
                break;
            }
        }
    }
    return margin;
}

+ (BOOL)isUserInterfaceIdiomPad {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

#if !(TARGET_OS_TV)
+ (BOOL)isDeviceOrientationLandscape {
    UIInterfaceOrientation orientation;
    if (@available(iOS 15.0, *)) {
        orientation = [CTUIUtils getSharedApplication].windows.firstObject.windowScene.interfaceOrientation;
    } else if (@available(iOS 13.0, *)) {
        orientation = [CTUIUtils getSharedApplication].windows.firstObject.windowScene.interfaceOrientation;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        orientation = [[CTUIUtils getSharedApplication] statusBarOrientation];
#pragma clang diagnostic pop
    }
    BOOL landscape = UIInterfaceOrientationIsLandscape(orientation);
    return landscape;
}
#endif

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

+ (BOOL)runningInsideAppExtension {
    return [[self class] getSharedApplication] == nil;
}

+ (void)openURL:(NSURL *)ctaURL forModule:(NSString *)ctModule {
    UIApplication *sharedApplication = [[self class] getSharedApplication];
    if (sharedApplication == nil) {
        return;
    }
    CleverTapLogStaticDebug(@"%@: firing deep link: %@", ctModule, ctaURL);
    id dlURL;
    if (@available(iOS 10.0, *)) {
        if ([sharedApplication respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            NSMethodSignature *signature = [UIApplication
                                            instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
            NSInvocation *invocation = [NSInvocation
                                        invocationWithMethodSignature:signature];
            [invocation setTarget:sharedApplication];
            [invocation setSelector:@selector(openURL:options:completionHandler:)];
            NSDictionary *options = @{};
            id completionHandler = nil;
            dlURL = ctaURL;
            [invocation setArgument:&dlURL atIndex:2];
            [invocation setArgument:&options atIndex:3];
            [invocation setArgument:&completionHandler atIndex:4];
            [invocation invoke];
        } else {
            if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
                [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
            }
        }
    } else {
        if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
            [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
        }
    }
}

@end
