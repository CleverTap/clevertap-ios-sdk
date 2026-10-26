# Xcode 27 / iOS 27 Support

This release makes the CleverTap iOS SDK build with **Xcode 27** and run on **iOS 27 / tvOS 27 / watchOS 27**. Two things changed that may require action in your app:

1. The **minimum deployment targets** were raised (Xcode 27 no longer builds targets below its supported range).
2. Apps must adopt the **UIScene lifecycle** (required by iOS/tvOS 26+ when built with the iOS 26/27 SDK).

---

## 1. Minimum deployment targets

Xcode 27 raised the minimum supported deployment targets, so the SDK minimums are now:

| Platform | Previous | New minimum |
| --- | --- | --- |
| iOS | 9.0 | **15.0** |
| tvOS | 9.0 | **15.0** |
| watchOS (`CleverTapWatchOS`) | 2.0 | **9.0** |

If your app targets a version below these, raise its deployment target to at least the new minimum. Xcode 27 fails the build with an error like:

```
error: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0,
but the range of supported deployment target versions is 15.0 to 27.x.
```

---

## 2. CocoaPods: bump your pod deployment targets

Xcode 27 fails to build **any** target below the new minimum — and that includes the SDK's dependencies (such as `SDWebImage`) and any other pods that still declare an older minimum. Setting `platform :ios, '15.0'` in your `Podfile` is not always enough, because each pod can carry its own lower deployment target.

Add a `post_install` hook to your `Podfile` that raises every generated pod target, then run `pod install` again:

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'CleverTap-iOS-SDK'
  # ...
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
```

> Already have a `post_install` block? Add the `IPHONEOS_DEPLOYMENT_TARGET` line inside it — don't declare a second `post_install`.

---

## 3. Adopt the UIScene lifecycle

Starting with iOS 26 / tvOS 26, apps built with the iOS 26/27 SDK **must** use the `UIScene` lifecycle. An app that still uses the legacy app-delegate, window-based lifecycle — an `AppDelegate` with a `window` property, a `UIMainStoryboardFile` in `Info.plist`, and no scene manifest — **crashes at launch** on iOS/tvOS 26 and later.

This is an app-side requirement (not a CleverTap SDK change), but your app must adopt it for CleverTap to run on iOS/tvOS 27.

### You don't need to do anything if

- Your app uses the **SwiftUI `App` lifecycle** (`@main struct … : App { WindowGroup { … } }`) — it is already scene-based.
- Your app already has a `UISceneDelegate` and a `UIApplicationSceneManifest`.

### If your app uses an app-delegate-only (storyboard) lifecycle

#### Step 1 — Add a scene manifest to `Info.plist`

Add `UIApplicationSceneManifest` and **remove** the existing `UIMainStoryboardFile` entry:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <!-- Swift: $(PRODUCT_MODULE_NAME).SceneDelegate   ObjC: SceneDelegate -->
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

#### Step 2 — Add a `SceneDelegate` that creates the window

Move window creation out of the app delegate and into a scene delegate.

**Swift**

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
        self.window = window
        window.makeKeyAndVisible()

        // Cold-start deep links arrive here now:
        connectionOptions.urlContexts.forEach { handle($0.url) }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Warm deep links arrive here instead of application(_:open:options:)
        URLContexts.forEach { handle($0.url) }
    }

    private func handle(_ url: URL) {
        // Your existing deep-link handling.
    }
}
```

**Objective-C**

```objc
@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) { return; }
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
}

@end
```

> The same pattern works for tvOS apps — `UIWindowScene` and `UIWindowSceneDelegate` are available on tvOS too.

#### Step 3 — Move deep-link / lifecycle callbacks to the scene delegate

Under the scene lifecycle these callbacks move off the app delegate. If your app (or your CleverTap deep-link handling) uses them, forward them:

| App delegate (legacy) | Scene delegate (new) |
| --- | --- |
| `application(_:open:options:)` | `scene(_:openURLContexts:)` |
| `application(_:continue:restorationHandler:)` | `scene(_:continue:)` |
| `applicationWillEnterForeground(_:)` | `sceneWillEnterForeground(_:)` |
| `applicationDidEnterBackground(_:)` | `sceneDidEnterBackground(_:)` |

**Unaffected:** CleverTap **push notifications** still go through `UNUserNotificationCenterDelegate` on the app delegate, and the CleverTap SDK's own UI (in-app notifications, App Inbox, etc.) already supports the scene lifecycle — no change needed there.

---

## Reference — sample apps

The sample apps in this repository show the full migration:

| Sample | Lifecycle | Scene change |
| --- | --- | --- |
| `SwiftStarter`, `ObjCStarter`, `SPMStarter` | UIKit (iOS) | `SceneDelegate` + scene manifest |
| `SwiftTvOS`, `ObjCTvOS` | UIKit (tvOS) | `SceneDelegate` + scene manifest |
| `SwiftUIStarter` | SwiftUI `App` | none (already scene-based) |
