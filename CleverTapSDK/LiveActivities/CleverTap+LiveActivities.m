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

@end
