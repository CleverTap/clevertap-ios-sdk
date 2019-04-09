#if !TARGET_OS_TV
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class CleverTapInstanceConfig;

@interface CleverTapJSInterface : NSObject <WKScriptMessageHandler>

@property (nonatomic, strong) WKUserContentController *userContentController;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

@end
#endif

