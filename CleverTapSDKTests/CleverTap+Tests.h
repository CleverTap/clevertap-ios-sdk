#import <Foundation/Foundation.h>
#import "CleverTap.h"
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
-(NSDictionary*)getBatchHeader;
- (void)pushValidationResults:(NSArray<CTValidationResult *> * _Nonnull )results;
- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type;

@end
