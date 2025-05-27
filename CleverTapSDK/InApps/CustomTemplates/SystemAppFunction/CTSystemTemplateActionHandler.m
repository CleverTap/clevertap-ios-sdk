//
//  CTSystemTemplateActionHandler.m
//  CleverTapSDK
//
//  Created by Nishant Kumar on 27/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSystemTemplateActionHandler.h"
#import "CTConstants.h"
#import "CTUtils.h"
#import "CTUIUtils.h"
#if __has_include(<CleverTapSDK/CleverTapSDK-Swift.h>)
#import <CleverTapSDK/CleverTapSDK-Swift.h>
#else
#import "CleverTapSDK-Swift.h"
#endif

@implementation CTSystemTemplateActionHandler

#pragma mark Push Permission System App Function

- (void)setPushPrimerManager:(CTPushPrimerManager *)pushPrimerManagerObj {
    pushPrimerManager = pushPrimerManagerObj;
}

- (void)promptPushPermission:(BOOL)fbSettings withCompletionBlock:(void (^_Nonnull)(BOOL presented))completion {
    if (pushPrimerManager.pushPermissionStatus == CTPushEnabled) {
        CleverTapLogStaticDebug(@"Push Notification permission is already granted.");
        completion(NO);
        return;
    }
    
    [pushPrimerManager promptForOSPushNotificationWithFallbackToSettings:fbSettings withCompletionBlock:completion];
}

#pragma mark Open Url System App Function

- (BOOL)handleOpenURL:(NSString *)action {
    if (!(action && action.length > 0)) {
        CleverTapLogStaticDebug(@"Open URL system template doesn't have an action URL");
        return NO;
    }
    
    NSURL *actionURL = [NSURL URLWithString:action];
    if (!actionURL) {
        CleverTapLogStaticDebug(@"Unable to retrieve URL from Open Url action string: %@", action);
        return NO;
    }
    
    [CTUtils runSyncMainQueue:^{
        [CTUIUtils openURL:actionURL forModule:@"OpenUrl System Template"];
    }];
    return YES;
}

#pragma mark App Rating System App Function

- (void)promptAppRatingWithCompletionBlock:(void (^_Nonnull)(BOOL presented))completion; {
    [CTAppRatingHelper requestRatingWithCompletion:completion];
}

@end
