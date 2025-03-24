#import <Foundation/Foundation.h>
#if !(TARGET_OS_TV)
#import <WebKit/WebKit.h>

@class CleverTapInstanceConfig;
@class CTInAppDisplayViewController;
/*!
 @abstract
 The `CleverTapJSInterface` class is a bridge to communicate between Webviews and CleverTap SDK. Calls to forward record events or set user properties fired within a Webview to CleverTap SDK.
 */

@interface CleverTapJSInterface : NSObject <WKScriptMessageHandler>

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

@end
#endif

