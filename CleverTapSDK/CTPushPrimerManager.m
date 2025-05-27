//
//  CTPushPrimerManager.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 04/07/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTPushPrimerManager.h"
#import "CTUtils.h"
#import "CTUIUtils.h"
#import "CTConstants.h"
#import "CTLocalInApp.h"
#import "CTInAppDisplayManager.h"

@interface CTPushPrimerManager () 
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@end

@implementation CTPushPrimerManager
@synthesize pushPermissionDelegate=_pushPermissionDelegate;

#if !CLEVERTAP_NO_INAPP_SUPPORT

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config inAppDisplayManager:(CTInAppDisplayManager*)inAppDisplayManagerObj dispatchQueueManager:(CTDispatchQueueManager*)dispatchQueueManager {
    
    if ((self = [super init])) {
        self.config = config;
        inAppDisplayManager = inAppDisplayManagerObj;
        self.dispatchQueueManager = dispatchQueueManager;

        self.pushPermissionStatus = CTPushNotKnown;
        [self checkAndUpdatePushPermissionStatusWithCompletion:^(CTPushPermissionStatus status) {
            self.pushPermissionStatus = status;
        }];
    }
    return self;
}

- (void)setPushPermissionDelegate:(id<CleverTapPushPermissionDelegate>)delegate {
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setPushPermissionDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapPushPermissionDelegate)]) {
        _pushPermissionDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Push Permission Delegate does not conform to the CleverTapPushPermissionDelegate protocol", self);
    }
}

- (id<CleverTapPushPermissionDelegate>)pushPermissionDelegate {
    return _pushPermissionDelegate;
}

- (void)promptPushPrimer:(NSDictionary *_Nonnull)json {
    if (@available(iOS 10.0, *)) {
        [self getNotificationPermissionStatusWithCompletionHandler:^(UNAuthorizationStatus status) {
            if (status == UNAuthorizationStatusNotDetermined || status == UNAuthorizationStatusDenied) {
                [self->inAppDisplayManager prepareNotificationForDisplay:json];
            } else {
                CleverTapLogDebug(self.config.logLevel, @"%@: Push Notification permission is already granted.", self);
            }
        }];
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: Push Notification is avaliable from iOS v10.0 or later", self);
    }
}

- (void)promptForPushPermission:(BOOL)isFallbackToSettings {
    [self promptForOSPushNotificationWithFallbackToSettings:isFallbackToSettings withCompletionBlock:nil];
}

- (void)getNotificationPermissionStatusWithCompletionHandler:(void (^)(UNAuthorizationStatus))completion {
    if (@available(iOS 10.0, *)) {
        [self.dispatchQueueManager runSerialAsync:^{
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings) {
                completion(settings.authorizationStatus);
            }];
        }];
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: Push Notification is avaliable from iOS v10.0 or later", self);
        completion(UNAuthorizationStatusDenied);
    }
}

- (void)notifyPushPermissionResponse:(BOOL)accepted {
    CleverTapLogInternal(self.config.logLevel, @"%@: Push Permission Response: %s", self, (accepted ? "accepted" : "denied"));
    if (self.pushPermissionDelegate && [self.pushPermissionDelegate respondsToSelector:@selector(onPushPermissionResponse:)]) {
        [self.pushPermissionDelegate onPushPermissionResponse:accepted];
    }
    
    // Update push permission status if it has changed.
    if (accepted) {
        self.pushPermissionStatus = CTPushEnabled;
    } else {
        self.pushPermissionStatus = CTPushNotEnabled;
    }
}

- (void)promptForOSPushNotificationWithFallbackToSettings:(BOOL)isFallbackToSettings
                                      withCompletionBlock:(void (^_Nullable)(BOOL presented))completion {
    __block BOOL pushPermissionPresented = NO;
    if (@available(iOS 10.0, *)) {
        [self.dispatchQueueManager runSerialAsync:^{
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings) {
                if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                    pushPermissionPresented = YES;
                    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                        if (granted) {
                            [self notifyPushPermissionResponse:YES];
                        } else {
                            [self notifyPushPermissionResponse:NO];
                        }
                        
                        if (!error) {
                            [CTUtils runSyncMainQueue: ^{
                                UIApplication *sharedApplication = [CTUIUtils getSharedApplication];
                                if (sharedApplication == nil) {
                                    return;
                                }

                                [sharedApplication registerForRemoteNotifications];
                            }];
                        } else {
                            CleverTapLogDebug(self.config.logLevel, @"%@: Error in request authorization for remote notification: %@", self, error);
                        }
                    }];
                } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                    if (isFallbackToSettings) {
                        [self openAppSettingsForPushNotification];
                    } else {
                        CleverTapLogDebug(self.config.logLevel, @"%@: Notification permission is denied. Please grant notification permission access in your app's settings to send notifications.", self);
                    }
                } else {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Push Notification permission is already granted.", self);
                }
                completion(pushPermissionPresented);
            }];
        }];
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: Push Notification is avaliable from iOS v10.0 or later", self);
        completion(NO);
    }
}

- (void)openAppSettingsForPushNotification {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (!url) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Unable to retrieve URL from OpenSettingsURL string", self);
        return;
    }

    [CTUtils runSyncMainQueue:^{
        [CTUIUtils openURL:url forModule:@"PushPermission"];
    }];
}

- (void)checkAndUpdatePushPermissionStatusWithCompletion:(void (^_Nonnull)(CTPushPermissionStatus status))completionHandler {
    if (@available(iOS 10.0, *)) {
        [self getNotificationPermissionStatusWithCompletionHandler: ^(UNAuthorizationStatus status) {
            if (status == UNAuthorizationStatusNotDetermined || status == UNAuthorizationStatusDenied) {
                completionHandler(CTPushNotEnabled);
            } else {
                completionHandler(CTPushEnabled);
            }
        }];
    } else {
        completionHandler(CTPushNotKnown);
    }
}
#endif

@end
