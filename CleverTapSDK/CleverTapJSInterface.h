#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class CleverTapInstanceConfig;

@interface CleverTapJSInterface : NSObject

@property (nonatomic, strong) WKUserContentController *ctUserContentController;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

@end
