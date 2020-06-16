
#import <CleverTapSDK/CleverTap.h>

NS_ASSUME_NONNULL_BEGIN

@interface CleverTap (Tests)

- (void)recordAppLaunched:(NSString *)caller;

- (void)_asyncSwitchUser:(NSDictionary *)properties
          withCachedGuid:(NSString *)cachedGUID
          andCleverTapID:(NSString *)cleverTapID
               forAction:(NSString*)action;

typedef NS_ENUM(NSInteger, CleverTapEventType) {
    CleverTapEventTypePage,
    CleverTapEventTypePing,
    CleverTapEventTypeProfile,
    CleverTapEventTypeRaised,
    CleverTapEventTypeData,
    CleverTapEventTypeNotificationViewed,
    CleverTapEventTypeFetch,
};

- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type;

- (void)setIsAppForeground:(BOOL)value;

@end

NS_ASSUME_NONNULL_END
