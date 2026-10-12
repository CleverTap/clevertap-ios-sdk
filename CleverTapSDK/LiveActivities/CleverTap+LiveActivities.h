#import <TargetConditionals.h>
// Live Activities is an iOS-only feature — the whole category is excluded from tvOS.
#if !TARGET_OS_TV
#import <Foundation/Foundation.h>
#import "CleverTap.h"
#import "CTLiveActivityDataQueue.h"

NS_ASSUME_NONNULL_BEGIN

/**
 CleverTap Live Activities — Objective-C API surface.

 The primary Live Activities API (`registerPushToStart`) is implemented as a
 **Swift generic method** and is available via `CleverTap+LiveActivities.swift`.
 It cannot be expressed as an Objective-C method because it accepts
 `Activity<Attributes>` generic types from ActivityKit (a Swift-only framework).

 This category conforms `CleverTap` to the internal `CTLiveActivityDataQueue`
 protocol, bridging the Swift Live Activities manager to the ObjC-only
 `pushLiveActivityData:` method.

 The impression / click APIs (`recordLiveActivityImpression(wzrk:)` /
 `recordLiveActivityClicked(wzrk:)`) are exposed to Objective-C via `@objc` in
 `CleverTap+LiveActivities.swift` and do not need a separate declaration here.

 ## Swift integration — Push-to-Start (iOS 17.2+)
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
#endif // !TARGET_OS_TV — Live Activities
