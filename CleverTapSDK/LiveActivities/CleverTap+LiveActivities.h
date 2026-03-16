#import <Foundation/Foundation.h>
#import "CleverTap.h"
#import "CTLiveActivityDataQueue.h"

NS_ASSUME_NONNULL_BEGIN

/**
 CleverTap Live Activities — Objective-C API surface.

 The primary Live Activities APIs (`launchActivity`, `resumeActivities`,
 `registerPushToStart`) are implemented as **Swift generic methods** and are
 available via `CleverTap+LiveActivities.swift`. They cannot be expressed as
 Objective-C methods because they accept `Activity<Attributes>` generic types
 from ActivityKit (a Swift-only framework).

 This category conforms `CleverTap` to the internal `CTLiveActivityDataQueue`
 protocol, bridging the Swift Live Activities manager to the ObjC-only
 `pushLiveActivityData:` method.

 `recordLiveActivityClickedWithTag:activityType:` is exposed to Objective-C
 via `@objc` in `CleverTap+LiveActivities.swift` and does not need a separate
 category declaration here.

 ## Swift integration (all flows)

 See `CleverTap+LiveActivities.swift` for the full Swift API:

 ### Local flow (iOS 16.2+)
 ```swift
 // 1. Register on app launch to resume any active activities
 if #available(iOS 16.2, *) {
     CleverTap.sharedInstance()?.resumeActivities(Activity<OrderAttributes>.self)
 }

 // 2. After calling Activity<T>.request(...)
 if #available(iOS 16.2, *) {
     CleverTap.sharedInstance()?.launchActivity("order-\(orderId)", activity: activity)
 }
 ```

 ### Push-to-Start flow (iOS 17.2+)
 ```swift
 // Must be called early in didFinishLaunchingWithOptions
 if #available(iOS 17.2, *) {
     CleverTap.sharedInstance()?.registerPushToStart(
         Activity<OrderAttributes>.self,
         name: "OrderAttributes"
     )
 }
 ```
 */
@interface CleverTap (LiveActivities) <CTLiveActivityDataQueue>

@end

NS_ASSUME_NONNULL_END
