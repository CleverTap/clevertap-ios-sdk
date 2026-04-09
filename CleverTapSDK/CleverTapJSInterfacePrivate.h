#import <Foundation/Foundation.h>

#if !(TARGET_OS_TV)
@interface CleverTapJSInterface () {}
- (instancetype)initWithConfigForInApps:(CleverTapInstanceConfig *)config fromController:(CTInAppDisplayViewController *)controller;

// SET ONLY WHEN THE USER INITIALISES A WEBVIEW WITH CT JS INTERFACE
@property (nonatomic, assign) BOOL wv_init;

- (WKUserScript *)versionScript;

@end
#endif // !(TARGET_OS_TV)
