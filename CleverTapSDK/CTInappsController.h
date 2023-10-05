//
//  CTInappsController.h
//  Pods
//
//  Created by Akash Malhotra on 03/07/23.
//

#import <Foundation/Foundation.h>
#import "CTInAppFCManager.h"
#import "CleverTapInAppNotificationDelegate.h"
#import "CTDispatchQueueManager.h"
#import "CTDeviceInfo.h"
#import "CTMetadata.h"
#import "CTValidationResultStack.h"
@class CTPushPrimerManager;

typedef NS_ENUM(NSInteger, CleverTapInAppRenderingStatus) {
    CleverTapInAppSuspend,
    CleverTapInAppDiscard,
    CleverTapInAppResume,
};

@interface CTInappsController : NSObject {
    CTPushPrimerManager *pushPrimerManager;
}

@property (nonatomic, assign) CleverTapInAppRenderingStatus inAppRenderingStatus;
@property (atomic, weak) id <CleverTapInAppNotificationDelegate> _Nullable inAppNotificationDelegate;
@property (nonatomic, assign) BOOL isAppForeground;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config inAppFCManager:(CTInAppFCManager* _Nonnull)inAppFCManager dispatchQueueManager:(CTDispatchQueueManager* _Nonnull)dispatchQueueManager deviceInfo:(CTDeviceInfo* _Nonnull)deviceInfo metadata:(CTMetadata* _Nonnull)metadata validationResultStack:(CTValidationResultStack* _Nonnull)validationResultStack;

- (void)_showNotificationIfAvailable;
- (void)_resumeInAppNotifications;
- (void)_showInAppNotificationIfAny;
- (void)prepareNotificationForDisplay:(NSDictionary* _Nonnull)jsonObj;
- (void)setInAppNotificationDelegate:(id <CleverTapInAppNotificationDelegate> _Nullable)delegate;
- (BOOL)didHandleInAppTestFromPushNotificaton:(NSDictionary* _Nullable)notification;
- (void)setPushPrimerManager:(CTPushPrimerManager* _Nonnull)pushPrimerManagerObj;
- (void)clearInApps;

@end
