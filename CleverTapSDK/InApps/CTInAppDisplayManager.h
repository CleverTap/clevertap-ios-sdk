//
//  CTInAppDisplayManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 3.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInAppNotificationDelegate.h"
#import "CTInAppFCManager.h"
#import "CTDeviceInfo.h"
#import "CleverTap.h"
#import "CTPushPrimerManager.h"
#import "CTInAppStore.h"
#import "CTFileDownloader.h"
#import "CTCustomTemplatesManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CleverTapInAppRenderingStatus) {
    CleverTapInAppSuspend,
    CleverTapInAppDiscard,
    CleverTapInAppResume,
};

@interface CTInAppDisplayManager : NSObject {
    __weak CTPushPrimerManager *pushPrimerManager;
}

@property (atomic, weak) id <CleverTapInAppNotificationDelegate> _Nullable inAppNotificationDelegate;
@property (nonatomic, assign, readonly) CleverTapInAppRenderingStatus inAppRenderingStatus;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithCleverTap:(CleverTap * _Nonnull)instance
                            dispatchQueueManager:(CTDispatchQueueManager * _Nonnull)dispatchQueueManager
                            inAppFCManager:(CTInAppFCManager *)inAppFCManager
                         impressionManager:(CTImpressionManager *)impressionManager
                                inAppStore:(CTInAppStore *)inAppStore
                          templatesManager:(CTCustomTemplatesManager *)templatesManager
                            fileDownloader:(CTFileDownloader *)fileDownloader;

- (void)setPushPrimerManager:(CTPushPrimerManager* _Nonnull)pushPrimerManagerObj;
- (void)prepareNotificationForDisplay:(NSDictionary* _Nonnull)jsonObj;
- (BOOL)didHandleInAppTestFromPushNotificaton:(NSDictionary* _Nullable)notification;
- (BOOL)isTemplateRegistered:(NSDictionary *)inAppJSON;

- (void)_addInAppNotificationsToQueue:(NSArray *)inappNotifs;
- (void)_showNotificationIfAvailable;
- (void)_suspendInAppNotifications;
- (void)_discardInAppNotifications;
- (void)_resumeInAppNotifications;
- (void)_showInAppNotificationIfAny;

@end

NS_ASSUME_NONNULL_END
