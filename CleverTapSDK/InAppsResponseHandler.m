//
//  InAppsResponseHandler.m
//  Pods
//
//  Created by Akash Malhotra on 03/07/23.
//

#import "InAppsResponseHandler.h"
#import "CleverTapInternal.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTUtils.h"

@interface InAppsResponseHandler ()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTInAppFCManager *inAppFCManager;
@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@property (nonatomic, strong) CTInappsController *inappsController;
@end

@implementation InAppsResponseHandler

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig *)config inAppFCManager:(CTInAppFCManager*)inAppFCManager dispatchQueueManager:(CTDispatchQueueManager*)dispatchQueueManager inappsController:(CTInappsController*)inappsController {
    
    if ((self = [super init])) {
        self.config = config;
        self.inAppFCManager = inAppFCManager;
        self.dispatchQueueManager = dispatchQueueManager;
        self.inappsController = inappsController;
    }
    return self;
}

- (void)processResponse:(NSDictionary*)jsonResp {
    
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (!self.config.analyticsOnly && ![CTUtils runningInsideAppExtension]) {
        NSNumber *perSession = jsonResp[@"imc"];
        if (perSession == nil) {
            perSession = @10;
        }
        NSNumber *perDay = jsonResp[@"imp"];
        if (perDay == nil) {
            perDay = @10;
        }
        [self.inAppFCManager updateLimitsPerDay:perDay.intValue andPerSession:perSession.intValue];
        
        NSArray *inappsJSON = jsonResp[CLTAP_INAPP_JSON_RESPONSE_KEY];
        
        if (self.inappsController.inAppRenderingStatus == CleverTapInAppDiscard) {
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
                @try {
                    NSMutableArray *inapps = [[NSMutableArray alloc] initWithArray:[CTPreferences getObjectForKey:[CTPreferences storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY config: self.config]]];
                    for (int i = 0; i < [inappNotifs count]; i++) {
                        @try {
                            NSMutableDictionary *inappNotif = [[NSMutableDictionary alloc] initWithDictionary:inappNotifs[(NSUInteger) i]];
                            [inapps addObject:inappNotif];
                        } @catch (NSException *e) {
                            CleverTapLogInternal(self.config.logLevel, @"%@: Malformed InApp notification", self);
                        }
                    }
                    // Commit all the changes
                    [CTPreferences putObject:inapps forKey:[CTPreferences storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY config: self.config]];
                    
                    // Fire the first notification, if any
                    [self.dispatchQueueManager runOnNotificationQueue:^{
                        [self.inappsController _showNotificationIfAvailable];
                    }];
                } @catch (NSException *e) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: InApp notification handling error: %@", self, e.debugDescription);
                }
                // Handle inapp_stale
                @try {
                    [self.inAppFCManager processResponse:jsonResp];
                } @catch (NSException *ex) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Failed to handle inapp_stale update: %@", self, ex.debugDescription)
                }
            }
        }
    }
#endif
}

@end
