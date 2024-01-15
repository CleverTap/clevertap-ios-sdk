//
//  CTPushPrimerManager.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 04/07/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTap+PushPermission.h"
#import "CleverTapInstanceConfig.h"
#import "CTDispatchQueueManager.h"
@class CTInAppDisplayManager;

@interface CTPushPrimerManager : NSObject {
    CTInAppDisplayManager *inAppDisplayManager;
}

@property (atomic, weak) id <CleverTapPushPermissionDelegate> _Nullable pushPermissionDelegate;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config inAppDisplayManager:(CTInAppDisplayManager* _Nonnull)inAppDisplayManagerObj dispatchQueueManager:(CTDispatchQueueManager* _Nonnull)dispatchQueueManager;

- (void)setPushPermissionDelegate:(id<CleverTapPushPermissionDelegate> _Nullable)delegate;
- (void)promptPushPrimer:(NSDictionary *_Nonnull)json;
- (void)promptForOSPushNotificationWithFallbackToSettings:(BOOL)isFallbackToSettings andSkipSettingsAlert:(BOOL)skipSettingsAlert;
- (void)getNotificationPermissionStatusWithCompletionHandler:(void (^_Nonnull)(UNAuthorizationStatus))completion;
- (void)notifyPushPermissionResponse:(BOOL)accepted;
@end

