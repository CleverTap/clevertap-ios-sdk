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
    @try {
        NSString *js = [NSString stringWithFormat:@"window.cleverTapIOSSDKVersion = %@;", WR_SDK_REVISION];
        WKUserScript *wkScript = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        return wkScript;
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception creating version script: %@", [self class], exception);
        return nil;
    }
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    // Ensure we're on the main thread for UI operations
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self userContentController:userContentController didReceiveScriptMessage:message];
        });
        return;
    }
    
    @try {
        // Validate input parameters
        if (!message || !message.body) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Received invalid script message", [self class]);
            return;
        }
        
        if (![message.body isKindOfClass:[NSDictionary class]]) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Script message body is not a dictionary: %@", [self class], message.body);
            return;
        }
        
        NSDictionary *messageBody = (NSDictionary *)message.body;
        
        // Validate config and get CleverTap instance safely
        CleverTap *cleverTap = [self getCleverTapInstance];
        if (!cleverTap) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Could not get CleverTap instance", [self class]);
            return;
        }
        
        if (_wv_init && cleverTap.config) {
            cleverTap.config.wv_init = YES;
        }
        
        [self handleMessageFromWebview:messageBody forInstance:cleverTap];
        
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception handling script message: %@", [self class], exception);
    }
}

- (CleverTap *)getCleverTapInstance {
    @try {
        CleverTap *cleverTap = nil;
        
        if (!self.config || self.config.isDefaultInstance) {
            cleverTap = [CleverTap sharedInstance];
        } else {
            cleverTap = [CleverTap instanceWithConfig:self.config];
        }
        
        return cleverTap;
        
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception getting CleverTap instance: %@", [self class], exception);
        return nil;
    }
}

- (void)handleMessageFromWebview:(NSDictionary<NSString *,id> *)message forInstance:(CleverTap *)cleverTap {
    @try {
        // Validate parameters
        if (!message || !cleverTap) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for handling webview message", [self class]);
            return;
        }
        
        NSString *action = [message objectForKey:@"action"];
        if (!action || ![action isKindOfClass:[NSString class]]) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid or missing action in webview message", [self class]);
            return;
        }
        
        // Handle different actions with proper error checking
        if ([action isEqualToString:@"recordEventWithProps"]) {
            [self handleRecordEventWithProps:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profilePush"]) {
            [self handleProfilePush:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileSetMultiValues"]) {
            [self handleProfileSetMultiValues:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileAddMultiValue"]) {
            [self handleProfileAddMultiValue:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileAddMultiValues"]) {
            [self handleProfileAddMultiValues:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileRemoveValueForKey"]) {
            [self handleProfileRemoveValueForKey:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileRemoveMultiValue"]) {
            [self handleProfileRemoveMultiValue:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileRemoveMultiValues"]) {
            [self handleProfileRemoveMultiValues:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"recordChargedEvent"]) {
            [self handleRecordChargedEvent:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"onUserLogin"]) {
            [self handleOnUserLogin:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileIncrementValueBy"]) {
            [self handleProfileIncrementValueBy:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"profileDecrementValueBy"]) {
            [self handleProfileDecrementValueBy:message forInstance:cleverTap];
        } else if ([action isEqualToString:@"triggerInAppAction"]) {
            [self handleTriggerInAppAction:message];
        } else if ([action isEqualToString:@"dismissInAppNotification"]) {
            [self handleDismissInAppNotification];
        } else if ([action isEqualToString:@"promptForPushPermission"]) {
            [self handlePromptForPushPermission:message forInstance:cleverTap];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Unknown action received: %@", [self class], action);
        }
        
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception handling webview message: %@", [self class], exception);
    }
}

#pragma mark - Action Handlers

- (void)handleRecordEventWithProps:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id event = message[@"event"];
        id properties = message[@"properties"];
        
        if (event && [event isKindOfClass:[NSString class]]) {
            [cleverTap recordEvent:event withProps:properties];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid event parameter for recordEventWithProps", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleRecordEventWithProps: %@", [self class], exception);
    }
}

- (void)handleProfilePush:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id properties = message[@"properties"];
        if (properties) {
            [cleverTap profilePush:properties];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Missing properties for profilePush", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfilePush: %@", [self class], exception);
    }
}

- (void)handleProfileSetMultiValues:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id values = message[@"values"];
        id key = message[@"key"];
        
        if (values && key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileSetMultiValues:values forKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for profileSetMultiValues", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileSetMultiValues: %@", [self class], exception);
    }
}

- (void)handleProfileAddMultiValue:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id value = message[@"value"];
        id key = message[@"key"];
        
        if (value && key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileAddMultiValue:value forKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for profileAddMultiValue", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileAddMultiValue: %@", [self class], exception);
    }
}

- (void)handleProfileAddMultiValues:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id values = message[@"values"];
        id key = message[@"key"];
        
        if (values && key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileAddMultiValues:values forKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for profileAddMultiValues", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileAddMultiValues: %@", [self class], exception);
    }
}

- (void)handleProfileRemoveValueForKey:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id key = message[@"key"];
        
        if (key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileRemoveValueForKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid key parameter for profileRemoveValueForKey", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileRemoveValueForKey: %@", [self class], exception);
    }
}

- (void)handleProfileRemoveMultiValue:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id value = message[@"value"];
        id key = message[@"key"];
        
        if (value && key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileRemoveMultiValue:value forKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for profileRemoveMultiValue", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileRemoveMultiValue: %@", [self class], exception);
    }
}

- (void)handleProfileRemoveMultiValues:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id values = message[@"values"];
        id key = message[@"key"];
        
        if (values && key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileRemoveMultiValues:values forKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for profileRemoveMultiValues", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileRemoveMultiValues: %@", [self class], exception);
    }
}

- (void)handleRecordChargedEvent:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id chargeDetails = message[@"chargeDetails"];
        id items = message[@"items"];
        
        if (chargeDetails) {
            [cleverTap recordChargedEventWithDetails:chargeDetails andItems:items];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Missing chargeDetails for recordChargedEvent", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleRecordChargedEvent: %@", [self class], exception);
    }
}

- (void)handleOnUserLogin:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id properties = message[@"properties"];
        if (properties) {
            [cleverTap onUserLogin:properties];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Missing properties for onUserLogin", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleOnUserLogin: %@", [self class], exception);
    }
}

- (void)handleProfileIncrementValueBy:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id value = message[@"value"];
        id key = message[@"key"];
        
        if (value && key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileIncrementValueBy:value forKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for profileIncrementValueBy", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileIncrementValueBy: %@", [self class], exception);
    }
}

- (void)handleProfileDecrementValueBy:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        id value = message[@"value"];
        id key = message[@"key"];
        
        if (value && key && [key isKindOfClass:[NSString class]]) {
            [cleverTap profileDecrementValueBy:value forKey:key];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Invalid parameters for profileDecrementValueBy", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleProfileDecrementValueBy: %@", [self class], exception);
    }
}

- (void)handleTriggerInAppAction:(NSDictionary *)message {
    @try {
        id actionJson = message[@"actionJson"];
        id callToAction = message[@"callToAction"];
        id buttonId = message[@"buttonId"];
        
        [self triggerInAppAction:actionJson callToAction:callToAction buttonId:buttonId];
        
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleTriggerInAppAction: %@", [self class], exception);
    }
}

- (void)handleDismissInAppNotification {
    @try {
        // Check if controller is still valid before calling
        if (self.controller && [self.controller respondsToSelector:@selector(hide:)]) {
            [self.controller hide:YES];
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Controller is nil or doesn't respond to hide:", [self class]);
        }
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handleDismissInAppNotification: %@", [self class], exception);
    }
}

- (void)handlePromptForPushPermission:(NSDictionary *)message forInstance:(CleverTap *)cleverTap {
    @try {
        // Hide controller first if available
        if (self.controller && [self.controller respondsToSelector:@selector(hide:)]) {
            [self.controller hide:NO];
        }
        
        id showFallbackSettings = message[@"showFallbackSettings"];
        if (showFallbackSettings) {
            [cleverTap promptForPushPermission:showFallbackSettings];
        } else {
            [cleverTap promptForPushPermission:@(YES)]; // Default to YES
        }
        
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in handlePromptForPushPermission: %@", [self class], exception);
    }
}

- (void)triggerInAppAction:(NSDictionary *)actionJson callToAction:(NSString *)callToAction buttonId:(NSString *)buttonId {
    @try {
        if (!actionJson) {
            CleverTapLogDebug(self.config.logLevel, @"%@: action JSON is nil.", [self class]);
            return;
        }
        
        // Validate controller
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
            // Ensure the controller still responds to the selector
            if ([self.controller respondsToSelector:@selector(triggerInAppAction:callToAction:buttonId:)]) {
                [self.controller triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
            } else {
                CleverTapLogDebug(self.config.logLevel, @"%@: controller doesn't respond to triggerInAppAction:callToAction:buttonId:", [self class]);
            }
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: error creating action from action JSON: %@.", [self class], action.error);
        }
        
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception in triggerInAppAction: %@", [self class], exception);
    }
}

- (void)dealloc {
    // Clean up any remaining references
    _controller = nil;
    _config = nil;
}

@end
