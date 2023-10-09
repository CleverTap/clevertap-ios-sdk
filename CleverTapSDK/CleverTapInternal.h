#import <Foundation/Foundation.h>
#import "CleverTap.h"
#import "CTInAppEvaluationManager.h"
#import "CTInAppFCManager.h"

typedef NS_ENUM(NSInteger, CleverTapEventType) {
    CleverTapEventTypePage,
    CleverTapEventTypePing,
    CleverTapEventTypeProfile,
    CleverTapEventTypeRaised,
    CleverTapEventTypeData,
    CleverTapEventTypeNotificationViewed,
    CleverTapEventTypeFetch,
};

@interface CleverTap (Internal) {}

@property (nonatomic, strong, readonly) CTInAppDisplayManager * _Nullable inAppDisplayManager;
@property (nonatomic, strong, readonly) CTInAppEvaluationManager * _Nullable inAppEvaluationManager;
@property (nonatomic, strong, readonly) CTInAppFCManager * _Nullable inAppFCManager;
@property (nonatomic, assign, readonly) BOOL isAppForeground;
@property(strong, nonatomic, nullable) CleverTapFetchInappsBlock fetchInappsBlock;

+ (NSMutableDictionary<NSString *, CleverTap *> * _Nullable)getInstances;

- (void)recordInAppNotificationStateEvent:(BOOL)clicked
                          forNotification:(CTInAppNotification * _Nonnull)notification andQueryParameters:(NSDictionary * _Nullable)params;

- (id <CleverTapURLDelegate> _Nullable)urlDelegate;

- (void)setBatchSentDelegate:(id <CTBatchSentDelegate> _Nullable)delegate;

- (void)addAttachToHeaderDelegate:(id<CTAttachToHeaderDelegate> _Nonnull)delegate;
- (void)removeAttachToHeaderDelegate:(id<CTAttachToHeaderDelegate> _Nonnull)delegate;

- (void)addSwitchUserDelegate:(id<CTSwitchUserDelegate> _Nonnull)delegate;
- (void)removeSwitchUserDelegate:(id<CTSwitchUserDelegate> _Nonnull)delegate;

@end
