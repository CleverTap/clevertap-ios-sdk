#import "CleverTapJSInterface.h"
#import "CleverTap.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CleverTapJSInterfacePrivate.h"

#import "CTConstants.h"
#import "CTNotificationAction.h"
#import "CTInAppDisplayViewController.h"

#import "CleverTapBuildInfo.h"
#import "CleverTap+PushPermission.h"

@interface CleverTapJSInterface (){}

@property (nonatomic, strong) CleverTapInstanceConfig *config;
// The controller initializes the CleverTapJSInterface and retains it hence this property needs to be weak
@property (nonatomic, weak) CTInAppDisplayViewController *controller;

@end

@implementation CleverTapJSInterface

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    if (self = [super init]) {
        _config = config;
        _wv_init = YES;
    }
    return self;
}

- (instancetype)initWithConfigForInApps:(CleverTapInstanceConfig *)config fromController:(CTInAppDisplayViewController *)controller {
    if (self = [super init]) {
        _config = config;
        _controller = controller;
    }
    return self;
}

- (WKUserScript *)versionScript {
    NSString *js = [NSString stringWithFormat:@"window.cleverTapIOSSDKVersion = %@;", WR_SDK_REVISION];
    WKUserScript *wkScript = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    return wkScript;
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        CleverTap *cleverTap;
        if (!self.config || self.config.isDefaultInstance){
            cleverTap = [CleverTap sharedInstance];
        } else {
            cleverTap = [CleverTap instanceWithConfig:self.config];
        }
        if (cleverTap) {
            if (_wv_init) {
                cleverTap.config.wv_init = YES;
            }
            [self handleMessageFromWebview:message.body forInstance:cleverTap];
        }
    }
}

- (void)handleMessageFromWebview:(NSDictionary<NSString *,id> *)message forInstance:(CleverTap *)cleverTap {
    NSString *action = [message objectForKey:@"action"];
    if ([action isEqual:@"recordEventWithProps"]) {
        [cleverTap recordEvent: message[@"event"] withProps: message[@"properties"]];
    } else if ([action isEqual: @"profilePush"]) {
        [cleverTap profilePush: message[@"properties"]];
    } else if ([action isEqual: @"profileSetMultiValues"]) {
        [cleverTap profileSetMultiValues: message[@"values"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileAddMultiValue"]) {
        [cleverTap profileAddMultiValue: message[@"value"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileAddMultiValues"]) {
        [cleverTap profileAddMultiValues: message[@"values"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileRemoveValueForKey"]) {
        [cleverTap profileRemoveValueForKey: message[@"key"]];
    } else if ([action isEqual: @"profileRemoveMultiValue"]) {
        [cleverTap profileRemoveMultiValue: message[@"value"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileRemoveMultiValues"]) {
        [cleverTap profileRemoveMultiValues: message[@"values"] forKey: message[@"key"]];
    } else if ([action isEqual: @"recordChargedEvent"]) {
        [cleverTap recordChargedEventWithDetails: message[@"chargeDetails"] andItems: message[@"items"]];
    } else if ([action isEqual: @"onUserLogin"]) {
        [cleverTap onUserLogin: message[@"properties"]];
    } else if ([action isEqual: @"profileIncrementValueBy"]) {
        [cleverTap profileIncrementValueBy: message[@"value"] forKey: message[@"key"]];
    } else if ([action isEqual: @"profileDecrementValueBy"]) {
        [cleverTap profileDecrementValueBy: message[@"value"] forKey: message[@"key"]];
    } else if ([action isEqual: @"triggerInAppAction"]) {
        [self triggerInAppAction:message[@"actionJson"] callToAction:message[@"callToAction"] buttonId:message[@"buttonId"]];
    } else if ([action isEqual: @"promptForPushPermission"]) {
        if (self.controller) {
            [self.controller hide:NO];
        }
        [cleverTap promptForPushPermission:message[@"showFallbackSettings"]];
    }
}

- (void)triggerInAppAction:(NSDictionary *)actionJson callToAction:(NSString *)callToAction buttonId:(NSString *)buttonId {
    if (!actionJson) {
        CleverTapLogDebug(self.config.logLevel, @"%@: action JSON is nil.", [self class]);
        return;
    }
    if (!self.controller) {
        CleverTapLogDebug(self.config.logLevel, @"%@: display view controller is nil.", [self class]);
        return;
    }
    
    // Check for NSNull in case null is passed from the WebView message
    if ([callToAction isKindOfClass:[NSNull class]]) {
        callToAction = nil;
    }
    if ([buttonId isKindOfClass:[NSNull class]]) {
        buttonId = nil;
    }
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithJSON:actionJson];
    if (action && !action.error) {
        [self.controller triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: error creating action from action JSON: %@.", [self class], action.error);
    }
}

@end
