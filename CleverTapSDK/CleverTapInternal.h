#import <Foundation/Foundation.h>
#import "CleverTap.h"

typedef NS_ENUM(NSInteger, CleverTapEventType) {
    CleverTapEventTypePage,
    CleverTapEventTypePing,
    CleverTapEventTypeProfile,
    CleverTapEventTypeRaised,
    CleverTapEventTypeData,
    CleverTapEventTypeNotificationViewed,
    CleverTapEventTypeFetch,
};

@interface CleverTap () {}
@property (nonatomic, strong) CTInAppDisplayManager *inAppDisplayManager;

- (void)setBatchSentDelegate:(id <CTBatchSentDelegate> _Nullable)delegate;
- (void)addAttachToHeaderDelegate:(id<CTAttachToHeaderDelegate>)delegate;
- (void)removeAttachToHeaderDelegate:(id<CTAttachToHeaderDelegate>)delegate;

- (void)addSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate;

- (void)removeSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate;

@property (nonatomic, assign) BOOL isAppForeground;

- (id <CleverTapURLDelegate> _Nullable)urlDelegate;
- (void)recordInAppNotificationStateEvent:(BOOL)clicked
                          forNotification:(CTInAppNotification *)notification andQueryParameters:(NSDictionary *)params;
+ (NSMutableDictionary<NSString*, CleverTap*>*)getInstances;
@end
