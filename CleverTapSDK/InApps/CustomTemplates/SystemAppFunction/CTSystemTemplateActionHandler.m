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

- (void)promptPushPermission:(BOOL)fbSettings {
    if (pushPrimerManager.pushPermissionStatus == CTPushEnabled) {
        CleverTapLogStaticDebug(@"Push Notification permission is already granted.");
        return;
    }
    
    [pushPrimerManager promptForOSPushNotificationWithFallbackToSettings:fbSettings andSkipSettingsAlert:YES];
}

#pragma mark Open Url System App Function

- (void)handleOpenURL:(NSString *)action {
    if (action && action.length > 0) {
        @try {
            NSURL *actionURL = [NSURL URLWithString:action];
            [CTUtils runSyncMainQueue:^{
                [CTUIUtils openURL:actionURL forModule:@"OpenUrl System Template"];
            }];
        } @catch (NSException *e) {
            CleverTapLogStaticDebug(@"Error while getting URL: %@", [e debugDescription]);
        }
    } else {
        CleverTapLogStaticDebug(@"Open url system template doesn't have action URL");
    }
}

#pragma mark App Rating System App Function

- (void)promptAppRating {
    CTAppRatingHelper *appRatingHelper = [[CTAppRatingHelper alloc] init];
    [appRatingHelper requestRating];
}

@end
