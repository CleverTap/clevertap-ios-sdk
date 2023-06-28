#import <Foundation/Foundation.h>

@interface CleverTapJSInterface () {}
- (instancetype)initWithConfigForInApps:(CleverTapInstanceConfig *)config;

// SET ONLY WHEN THE USER INITIALISES A WEBVIEW WITH CT JS INTERFACE
@property (nonatomic, assign) BOOL wv_init;
@end
