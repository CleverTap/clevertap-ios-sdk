#import <TargetConditionals.h>
// Live Activities is an iOS-only feature — the whole category is excluded from tvOS.
#if !TARGET_OS_TV
#import <Foundation/Foundation.h>
#import "CleverTap.h"
#import "CTLiveActivityDataQueue.h"

NS_ASSUME_NONNULL_BEGIN

/**
 CleverTap Live Activities — internal bridge. Not an API you call.

 There is no Objective-C Live Activities API. This category declares no methods.
 All it does is say that `CleverTap` conforms to the internal
 `CTLiveActivityDataQueue` protocol, so the Swift manager can queue events and
 tokens. `CleverTap+LiveActivities.m` implements that conformance.

 Everything an app calls lives in `CleverTap+LiveActivities.swift` and is
 Swift-only: `registerPushToStart`, and both forms of
 `recordLiveActivityImpression` / `recordLiveActivityClicked`.

 Why there is no `@objc` here: `registerPushToStart` takes an
 `Activity<Attributes>` generic, which Objective-C cannot express at all. And
 marking the others `@objc` would make the generated `CleverTapSDK-Swift.h`
 import the module umbrella, which breaks apps that link the SDK statically
 (Flutter / React Native without `use_frameworks!`).

 If an Objective-C app delegate needs to report a click,
 wrap the Swift call in a small `@objc` class of your own.

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
