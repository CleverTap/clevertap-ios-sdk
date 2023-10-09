//
//  CleverTap+InAppsResponseHandler.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 9.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTPreferences.h"
#import "CTInAppDisplayManager.h"
#import "CTInAppFCManager.h"
#import "CTUIUtils.h"
#import "CTConstants.h"
#import "CleverTapInternal.h"

@implementation CleverTap(InAppsResponseHandler)

- (void)handleInAppResponse:(NSDictionary *)jsonResp {
    if (!self.config.analyticsOnly && ![CTUIUtils runningInsideAppExtension]) {
        // Parse global limits
        NSNumber *perSession = jsonResp[CLTAP_INAPP_GLOBAL_CAP_SESSION_JSON_RESPONSE_KEY];
        if (perSession == nil) {
            perSession = @10;
        }
        NSNumber *perDay = jsonResp[CLTAP_INAPP_GLOBAL_CAP_DAY_JSON_RESPONSE_KEY];
        if (perDay == nil) {
            perDay = @10;
        }
        [self.inAppFCManager updateGlobalLimitsPerDay:perDay.intValue andPerSession:perSession.intValue];
        
        // Parse SS notifications
        NSArray *ssInAppNotifs = jsonResp[CLTAP_INAPP_SS_JSON_RESPONSE_KEY];
        if (ssInAppNotifs) {
            // TODO: save to in-app store
        }
        
        // Parse CS notifications
        NSArray *csInAppNotifs = jsonResp[CLTAP_INAPP_CS_JSON_RESPONSE_KEY];
        if (csInAppNotifs) {
            // TODO: save to in-app store
        }
        
        // Parse in-app Mode
        NSString *mode = jsonResp[CLTAP_INAPP_MODE_JSON_RESPONSE_KEY];
        [self.inAppStore setMode:mode];
        
        // Parse SS App Launched notifications
        NSArray *inAppNotifsAppLaunched = jsonResp[CLTAP_INAPP_SS_APP_LAUNCHED_JSON_RESPONSE_KEY];
        if (inAppNotifsAppLaunched) {
            @try {
                [self.inAppEvaluationManager evaluateOnAppLaunchedServerSide:inAppNotifsAppLaunched];
            } @catch (NSException *e) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Error evaluating App Launched notifications JSON: %@", self, e.debugDescription);
            }
        }
        
        // Handle stale in-apps
        @try {
            NSArray *stale = jsonResp[CLTAP_INAPP_STALE_JSON_RESPONSE_KEY];
            [self.inAppFCManager removeStaleInAppCounts:stale];
        } @catch (NSException *ex) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Failed to handle inapp_stale update: %@", self, ex.debugDescription)
        }
        
        // Parse in-app notifications to be displayed
        NSArray *inappsJSON = jsonResp[CLTAP_INAPP_JSON_RESPONSE_KEY];
        
        if (self.inAppDisplayManager.inAppRenderingStatus == CleverTapInAppDiscard) {
            CleverTapLogDebug(self.config.logLevel, @"%@: InApp Notifications are set to be discarded, not saving and showing the InApp Notification", self);
            return;
        }
        if (inappsJSON) {
            NSMutableArray *inappNotifs;
            @try {
                inappNotifs = [[NSMutableArray alloc] initWithArray:inappsJSON];
            } @catch (NSException *e) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing InApps JSON: %@", self, e.debugDescription);
            }
            
            // Add all the new notifications to the queue
            if (inappNotifs && [inappNotifs count] > 0) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Processing new InApps: %@", self, inappNotifs);
                [self.inAppDisplayManager _addInAppNotificationsToQueue:inappNotifs];
            }
        }
    }
}

@end
