#import <TargetConditionals.h>
// Live Activities is an iOS-only feature — the whole implementation is excluded from tvOS.
#if !TARGET_OS_TV
#import "CleverTap+LiveActivities.h"
#import "CleverTapInternal.h"

// MARK: - CTLiveActivityDataQueue conformance
// Bridges CTLiveActivityDataQueue to the internal pushLiveActivityData: method
// which is only visible to ObjC (declared in CleverTapInternal.h).
//
// NOTE: recordLiveActivityClickedWithTag:activityType: is implemented in Swift
// (CleverTap+LiveActivities.swift) to avoid importing the Swift-generated
// bridging header from this file.
@implementation CleverTap (LiveActivities)

- (void)enqueueLiveActivityData:(NSDictionary *)data {
    [self pushLiveActivityData:data];
}

- (void)recordLiveActivityEventNamed:(NSString *)eventName data:(NSDictionary *)data {
    [self pushLiveActivityEventNamed:eventName data:data];
}

- (void)recordLiveActivityViewedEventWithData:(NSDictionary *)wzrk {
    [self pushLiveActivityViewedEventWithData:wzrk];
}

- (void)recordLiveActivityClickedEventWithData:(NSDictionary *)wzrk {
    [self pushLiveActivityClickedEventWithData:wzrk];
}

- (void)registerLiveActivitySwitchUserDelegate:(id)delegate {
    [self addLiveActivitySwitchUserDelegate:delegate];
}

@end

#endif // !TARGET_OS_TV — Live Activities
