#import <Foundation/Foundation.h>
#import <CleverTapSDK/CleverTap.h>
#import "CTValidationResult.h"

@interface CleverTap (Tests)

typedef NS_ENUM(NSInteger, CleverTapEventType) {
    CleverTapEventTypePage,
    CleverTapEventTypePing,
    CleverTapEventTypeProfile,
    CleverTapEventTypeRaised,
    CleverTapEventTypeData,
    CleverTapEventTypeNotificationViewed,
    CleverTapEventTypeFetch,
};
- (NSDictionary *)getCachedGUIDs;
+ (void)notfityTestAppLaunch;
- (NSDictionary*)getBatchHeader;
- (void)pushValidationResults:(NSArray<CTValidationResult *> * _Nonnull )results;
- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type;

@end
