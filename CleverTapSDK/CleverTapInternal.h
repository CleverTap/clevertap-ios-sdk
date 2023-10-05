#import <Foundation/Foundation.h>

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
+ (NSMutableDictionary<NSString*, CleverTap*>*)getInstances;
- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type;
- (id<CleverTapURLDelegate>)urlDelegate;
@end
