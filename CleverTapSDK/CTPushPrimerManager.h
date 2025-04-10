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

typedef NS_ENUM(NSInteger, CTPushPermissionStatus){
    CTPushNotKnown = 0,
    CTPushEnabled = 1,
    CTPushNotEnabled = 2
};

@interface CTPushPrimerManager : NSObject {
    CTInAppDisplayManager *inAppDisplayManager;
}

@property (atomic, weak) id <CleverTapPushPermissionDelegate> _Nullable pushPermissionDelegate;
@property (nonatomic) CTPushPermissionStatus pushPermissionStatus;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config inAppDisplayManager:(CTInAppDisplayManager* _Nonnull)inAppDisplayManagerObj dispatchQueueManager:(CTDispatchQueueManager* _Nonnull)dispatchQueueManager;

- (void)setPushPermissionDelegate:(id<CleverTapPushPermissionDelegate> _Nullable)delegate;
- (void)promptPushPrimer:(NSDictionary *_Nonnull)json;
- (void)promptForOSPushNotificationWithFallbackToSettings:(BOOL)isFallbackToSettings
                                      withCompletionBlock:(void (^_Nullable)(BOOL presented))completion;
- (void)getNotificationPermissionStatusWithCompletionHandler:(void (^_Nonnull)(UNAuthorizationStatus))completion API_AVAILABLE(ios(10.0));
- (void)notifyPushPermissionResponse:(BOOL)accepted;
- (void)checkAndUpdatePushPermissionStatusWithCompletion:(void (^_Nonnull)(CTPushPermissionStatus status))completionHandler;
@end

