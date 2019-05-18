#if !(TARGET_OS_TV)
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
@class CleverTapInstanceConfig;

/*!
 
 @abstract
 The `CleverTapJSInterface` class is a bridge to communicate between Webviews and CleverTap SDK. Calls to forward record events or set user properties fired within a Webview to CleverTap SDK.
 */

@interface CleverTapJSInterface : NSObject <WKScriptMessageHandler>

@property (nonatomic, strong) WKUserContentController *userContentController;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

@end
#endif

