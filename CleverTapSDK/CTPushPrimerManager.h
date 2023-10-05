//
//  CTPushPrimerManager.h
//  Pods
//
//  Created by Akash Malhotra on 04/07/23.
//

#import <Foundation/Foundation.h>
#import "CleverTap+PushPermission.h"
#import "CleverTapInstanceConfig.h"
#import "CTDispatchQueueManager.h"
@class CTInappsController;

@interface CTPushPrimerManager : NSObject {
    CTInappsController *inappsController;
}

@property (atomic, weak) id <CleverTapPushPermissionDelegate> _Nullable pushPermissionDelegate;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config inappsController:(CTInappsController* _Nonnull)inappsControllerObj dispatchQueueManager:(CTDispatchQueueManager* _Nonnull)dispatchQueueManager;

- (void)setPushPermissionDelegate:(id<CleverTapPushPermissionDelegate> _Nullable)delegate;
- (void)promptPushPrimer:(NSDictionary *_Nonnull)json;
- (void)promptForOSPushNotificationWithFallbackToSettings:(BOOL)isFallbackToSettings andSkipSettingsAlert:(BOOL)skipSettingsAlert;
- (void)getNotificationPermissionStatusWithCompletionHandler:(void (^_Nonnull)(UNAuthorizationStatus))completion;
- (void)notifyPushPermissionResponse:(BOOL)accepted;
@end

