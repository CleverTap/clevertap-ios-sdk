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

@end
