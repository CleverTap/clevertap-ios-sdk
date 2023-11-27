#import <Foundation/Foundation.h>
#import "CleverTap.h"
#import "CTInAppEvaluationManager.h"
#import "CTInAppFCManager.h"
#import "CTInAppStore.h"
#import "CTSessionManager.h"

@class CTInAppDisplayManager;

@interface CleverTap (Internal)

typedef NS_ENUM(NSInteger, CleverTapEventType) {
    CleverTapEventTypePage,
    CleverTapEventTypePing,
    CleverTapEventTypeProfile,
    CleverTapEventTypeRaised,
    CleverTapEventTypeData,
    CleverTapEventTypeNotificationViewed,
    CleverTapEventTypeFetch,
};

@property (nonatomic, strong, readonly) CTInAppDisplayManager * _Nullable inAppDisplayManager;
@property (nonatomic, strong, readonly) CTInAppEvaluationManager * _Nullable inAppEvaluationManager;
@property (nonatomic, strong, readonly) CTInAppFCManager * _Nullable inAppFCManager;
@property (nonatomic, strong, readonly) CTInAppStore * _Nullable inAppStore;
@property (nonatomic, strong, readonly) CTImpressionManager * _Nullable impressionManager;
@property (nonatomic, assign, readonly) BOOL isAppForeground;
@property (nonatomic, strong, readonly) CTDeviceInfo * _Nonnull deviceInfo;
@property (atomic, strong, readonly) CTSessionManager * _Nonnull sessionManager;

+ (NSMutableDictionary<NSString *, CleverTap *> * _Nullable)getInstances;

- (void)recordInAppNotificationStateEvent:(BOOL)clicked
                          forNotification:(CTInAppNotification * _Nonnull)notification andQueryParameters:(NSDictionary * _Nullable)params;

- (id <CleverTapURLDelegate> _Nullable)urlDelegate;

@end
