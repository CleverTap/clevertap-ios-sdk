# Change Log
All notable changes to this project will be documented in this file.

### [Version 7.2.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/7.2.0) (May 27, 2025)

#### Added
- Introduces System App Functions (Open Url, App Rating, Push Permission Request - as mentioned [here](/docs/SystemInAppFunctions.md)) which can be triggered either as a button action within an in-app message or as a standalone campaign action in CleverTap, enriching client workflows.
- Adds support for Advanced InApp Builder templates. This feature enables easy creation of visually appealing in-app messages that seamlessly integrate with your app's look and feel. It includes support for non-intrusive HTML banners with flexible configuration options, triggered via in-app event-based actions.
- Upgrades the algorithm used for [encryption of PII data](https://github.com/CleverTap/clevertap-ios-sdk/blob/master/docs/Encryption.md), making it compliant with [OWASP](https://mas.owasp.org/MASTG/0x04g-Testing-Cryptography/). Uses Keychain for securely backing up encryption key on iOS 13+.

> ⚠️ **NOTE**
After upgrading the SDK to v7.2.0+, do not downgrade in subsequent app releases if you have enabled additional encryption. If you encounter any issues, please contact the CleverTap support team for assistance.

#### Fixed
- Fixes a bug where the TTL of in-app messages was compared with an int instead of NSTimeInterval.
- Improves in-app content display with updated layout guidelines, ensuring HTML views respect safe area boundaries on devices with notches and other screen features.
- Fixes a bug where certain webview resources were not cleaned up after HTML in-app messages were dismissed.

### [Version 7.1.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/7.1.1) (March 17, 2025)

#### Added
- Adds `dismissInAppNotification` action to dismiss custom HTML in-Apps

#### Fixed
- Fixes custom in-app device orientation check

### [Version 7.1.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/7.1.0) (January 21, 2025)

#### Added
- Adds support for triggering InApps based on first-time event filtering in multiple triggers. Now you can create campaign triggers that combine recurring and first-time events. For example: Trigger a campaign when "Charged" occurs (every time) OR "App Launched" occurs (first time only).
- Adds new user-level event log tracking system to store and manage user event history. New APIs include:
  - `getUserEventLog(:)`: Get details about a specific event
  - `getUserEventLogCount(:)`: Get count of times an event occurred
  - `getUserLastVisitTs()`: Get timestamp of user's last app visit
  - `getUserAppLaunchCount()`: Get total number of times user has launched the app
  - `getUserEventLogHistory()`: Get full event history for current user
- Adds `inAppNotificationDidShow:` to the `CleverTapInAppNotificationDelegate` delegate.

#### API Changes

- **Deprecated:**  The old event tracking APIs tracked events at the device level rather than the user level, making it difficult to maintain accurate user-specific event histories, especially in multi-user scenarios. The following methods have been deprecated in favor of new user-specific event tracking APIs that provide more accurate, user-level analytics. These deprecated methods will be removed in future versions with prior notice:
  - `eventGetDetail(:)`: Use `getUserEventLog()` instead for user-specific event details
  - `eventGetOccurrences(:)`: Use `getUserEventLogCount()` instead for user-specific event counts
  - `eventGetFirstTime(:)`: Use `getUserEventLog()` instead for user-specific first occurrence timestamp
  - `eventGetLastTime(:)`: Use `getUserEventLog()` instead for user-specific last occurrence timestamp
  - `userGetPreviousVisitTime()`: Use `getUserLastVisitTs()` instead for user-specific last visit timestamp
  - `userGetTotalVisits()`: Use `getUserAppLaunchCount()` instead for user-specific app launch count
  - `userGetEventHistory()`: Use `getUserEventLogHistory()` instead for user-specific event history

### [Version 7.0.3](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/7.0.3) (November 29, 2024)

#### Added
- Adds a method `setCredentials` for setting custom handshake domains.
- Adds support for previewing in-apps created through the new dashboard advanced builder.
- Adds parsing of urls for `open-url` action to track parameters in the url for `Notification Clicked` events in HTML in-app messages.
- Adds support for `promptForPushPermission` method in JS Interface and HTML in-apps.

#### Fixed
- Mitigates a potential crash related to the `CTValidationResultStack` class.
- Mitigates a potential crash on `[CTInAppHTMLViewController hideFromWindow:]`.
- Changes campaign triggering evaluation of event names, event properties, and profile properties to ignore letter case and whitespace.
- Fixes an issue where the `wzrk_c2a` value is passed as null to backend when we receive null for `callToAction` value in a webView message handler.

### [Version 7.0.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/7.0.2) (October 10, 2024)

#### Added
- Adds support for custom handshake domains.
- Adds support for custom code in-app templates definitions through a json scheme.

### [Version 7.0.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/7.0.1) (August 22, 2024)

#### Fixed
- Fixes a bug where some user properties were being sent with an incorrect prefix

### [Version 7.0.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/7.0.0) (August 07, 2024)

#### Added
- Adds support for Custom Code Templates. Please refer to the [Custom Code Templates doc](/docs/CustomCodeTemplates.md) to read more on how to integrate this in your app.
- Adds support for File Type Variables in Remote Config. Please refer to the [Remote Config Variables doc](/docs/Variables.md) to read more on how to integrate this in your app.
- Adds support for triggering in-app notifications on User Attribute Change.
- Adds the CleverTap SDK version in the JS interface for HTML in-app notifications.

#### Fixed
- Fix HTML view controller `CTInAppHTMLViewController` presented before scene became active.
- Use keyWindow supported orientations for `CTInAppDisplayViewController`.

### [Version 6.2.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/6.2.1) (April 12, 2024)

#### Fixed
- Fixes a build error related to privacy manifests when statically linking the SDK using Cocoapods.

### [Version 6.2.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/6.2.0) (April 4, 2024)

#### Changed
- Updates privacy manifests.

#### Fixed
- Fixes a bug where client side in-apps were not discarded when rendering status is set to "discard".

### [Version 6.1.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/6.1.0) (February 22, 2024)

#### Added
- Adds privacy manifests.

#### Fixed
- Fixes crash due to out of bounds in NSLocale implementation.

### [Version 6.0.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/6.0.0) (January 15, 2024)

#### Added
- Adds support for client-side in-apps.

#### Fixed
- Fixes a bug where some in-apps were not being dismissed.

### [Version 5.2.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.2.2) (November 21, 2023)

#### Fixed
- Fixes build warnings.
- Mitigates a potential crash when apps would go to the background.

### [Version 5.2.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.2.1) (September 29, 2023)

#### Added
- Adds support to enable `NSFileProtectionComplete` to secure App’s document directory.
- Adds support for Integration Debugger to show errors and events on the dashboard when `debugLevel` is set to 3.
- Adds support to send `locale` - lanugage and country data using NSLocale and Adds public API `setLocale` to set custom locale, for LP Parity.

#### Changed
- Updated logic to retrieve country code using NSLocale above iOS 16 as `CTCarrier` is deprecated above iOS 16 with no replacements, see [apple doc](https://developer.apple.com/documentation/coretelephony/ctcarrier)
- Updated logic to not send carrier name above iOS 16 in `CTCarrier` field.

#### Fixed
- Fixes a crash in iOS 17/Xcode 15 related to alert inapps.
- Fixes a failing `test_clevertap_instance_nscoding` test case.

### [Version 5.2.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.2.0) (August 16, 2023)

#### Added
- Adds support for encryption of PII data wiz. Email, Identity, Name and Phone. 
  Please refer to [Encryption.md](/docs/Encryption.md) file to read more on how to
  enable/disable encryption.
- Adds support for custom KV pairs common to all inbox messages in AppInbox.
- Adds sample SwiftUIStarter app to support CleverTap iOS SDK for SwiftUI, added steps to track screen views in SwiftUI. Refer to [SwiftUI doc](/docs/SwiftUI.md) for more details.

### [Version 5.1.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.1.2) (July 28, 2023)

#### Fixed
- Fixed a bug where the App Inbox would appear empty.

### [Version 5.1.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.1.1) (July 13, 2023)

#### Fixed
- Fixed Cocoapods Generated duplicate UUIDs warnings.

### [Version 5.1.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.1.0) (June 28, 2023)

#### Added
- Adds public methods of the `Leanplum` class from the `Leanplum` SDK.

#### Fixed
- Mitgates potential App Inbox errors.

### [Version 5.0.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.0.1) (May 17, 2023)

#### Breaking API Changes
- The `enableLocation` method has been removed and the `getLocationWithSuccess` method has been moved to a new module called `CleverTapLocation`. Please import this module via Cocoapods, SPM or manual integration. Please refer to the [Location doc](/docs/CleverTapLocation.md) for more details.
- The macro `CLEVERTAP_LOCATION` is no longer needed and has been removed.

### [Version 5.0.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/5.0.0) (May 05, 2023)

#### Added
- Adds support for Remote Config Variables. Please refer to the [Remote Config Variables doc](/docs/Variables.md) to read more on how to integrate this to your app.

#### Fixed
- Fixes a bug where the `getLocationWithSuccess` method would cause crashes.
- Adds minor improvements to saving session data in background state.
- Streamlines the argument key of `recordEventWithProps` in `CleverTapJSInterface`.

#### Deprecated
- The following methods related to Product Config and Feature Flags have been marked as deprecated in this release. These methods will be removed in the future with prior notice
    - Feature Flags
        - `- (void)ctFeatureFlagsUpdated;`
        - `- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue`
    - Product Config
        - `- (void)ctProductConfigFetched`
        - `- (void)ctProductConfigActivated`
        - `- (void)ctProductConfigInitialized`
        - `- (void)fetch`
        - `- (void)fetchWithMinimumInterval:(NSTimeInterval)minimumInterval`
        - `- (void)setMinimumFetchInterval:(NSTimeInterval)minimumFetchInterval`
        - `- (void)activate`
        - `- (void)fetchAndActivate`
        - `- (void)setDefaults:(NSDictionary<NSString *, NSObject *> *_Nullable)defaults`
        - `- (void)setDefaultsFromPlistFileName:(NSString *_Nullable)fileName`
        - `- (CleverTapConfigValue *_Nullable)get:(NSString* _Nonnull)key`
        - `- (NSDate *_Nullable)getLastFetchTimeStamp`
        - `- (void)reset`

### [Version 4.2.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.2.2) (April 03, 2023)

#### Fixed
- Fixed compilation errors in xcode 14.3+.
- Added guard rails to prevent crashes for background state tasks.

### [Version 4.2.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.2.1) (March 22, 2023)

#### Added
- Adds a public method `dismissAppInbox` to dismiss App Inbox.
- Adds a public method `enableLocation` for enabling location API in case of SPM.
- Adds a public method `markReadInboxMessagesForIDs` for marking multiple App Inbox messages as read by passing a collection of `messageID`s.
- Fixes a bug where CoreData would crash with threading inconsistency exceptions.
- Fixes a bug where the method `deleteInboxMessagesForIDs` would cause a crash when the message ID was null or invalid.

### [Version 4.2.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.2.0) (December 13, 2022)

#### Added
- Adds a new `CTLocalInApp` builder class to create half-interstitial & alert local in-apps.
- Adds below new public APIs for supporting push notification runtime permission.
    - `promptPushPrimer`, `promptForPushPermission`, and `getNotificationPermissionStatusWithCompletionHandler`
- Adds push permission callback method `onPushPermissionResponse` which returns true/false after user allow/deny notification permission.
- Refer [Push Primer doc](/docs/PushPrimer.md) for more details.
- Updated `SDWebImage` dependency.

### [Version 4.1.6](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.1.6) (November 28, 2022)

#### Added
- Adds a public instance method `deleteInboxMessagesforID` for deleting multiple App Inbox messages by passing a collection of `messageID`s.

#### Fixed
- Fixes a bug where embedded videos were not rendering in html inapp messages.
- Fixes a bug where incorrect events were being fired for Signed Call iOS SDK.

### [Version 4.1.5](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.1.5) (November 15, 2022)

#### Added
- Adds a class method `getGlobalInstance` to retrieve a CleverTap SDK instance for an account ID.

### [Version 4.1.4](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.1.4) (October 24, 2022)

#### Changed
- Allows additional special characters when setting a custom CleverTap ID.

### [Version 4.1.3](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.1.3) (October 11, 2022)

##### Fixed
- Fixes the value of `wzrk_c2a` key for image-only in-app notification CTAs.
- Possible fix for crashes related to profile caches.
- Updates support for CleverTap Signed Call iOS SDK.

### [Version 4.1.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.1.2) (September 16, 2022)

##### Fixed
- Fixes possible App Inbox crashes.
- Fixes NSKeyedUnarchiver console warnings

### [Version 4.1.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.1.1) (July 06, 2022)
  
##### Added
- Adds support to call `onUserLogin`, `profileIncrementValueBy`, `profileDecrementValueBy` methods in a WebView.
- Updates certificates for SSL Pinning.

##### Fixed
- Fixes possible App Inbox crashes.

### [Version 4.1.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.1.0) (June 16, 2022)
  
##### Added
- Adds analytics support for upcoming CleverTap Signed Call iOS SDK.
- `CleverTap.sharedInstance()?.profileRemoveValue(forKey: )` can now remove PII data like Email, Phone and Date Of Birth.

##### Fixed
- Fixes possible crashes by applying locks to make shared instance thread safe.
- Mitigates FileManager deprecated APIs.
- Mitigates UIKit deprecated APIs.


### [Version 4.0.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.0.1) (April 12, 2022)
  
##### Fixed
- Fixes deviceID so that it will be fetched from storage instead of memory variables.
- Fixes compile time errors when building sdk with CLEVERTAP_NO_INBOX_SUPPORT.
- Adds a check for uname() method when fetching platform name to avoid possible runtime crashes.

### [Version 4.0.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/4.0.0) (February 7, 2022)
  
##### Added
- Adds Custom Proxy Domain functionality for Push Impressions and Events
- Adds support for configurable CleverTap Profile identifiers

#### Changed
- Use `resource_bundle` instead of `resources` in podspec

### [Version 3.10.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.10.0) (Aug 23, 2021)

##### Added
- Adds public methods for suspending/discarding & resuming InApp Notifications
- Adds public methods to increment/decrement values set via User properties
- Custom Deep-link handling for App inbox, push notifications and in-app notifications

##### Changed
- Usage `clevertap-prod.com` instead of `wzrkt.com` 
- Usage `spiky.clevertap-prod.com` instead of `spiky.wzrkt.com`
- Refactor and Addresses iOS 15 beta fixes related to App inbox 
- Synchronize access for `deviceName` and `model` property

##### Fixed
- https://github.com/CleverTap/clevertap-ios-sdk/issues/103
- https://github.com/CleverTap/clevertap-ios-sdk/issues/137

### [Version 3.9.4](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.9.4) (May 17, 2021)

##### Added
- Adds `setFirstTabTitle` method to set the name of the first tab in App Inbox
- Adds `recordChargedEvent` to `CTJSInterface` class to allow raising Charged Event from JS
- Adds a feature to opt-out IDFV based on a flag in Info.plist or while setting up additional instances/configs

##### Changed
- Removes `profilePushGraphUser` and `profilePushGooglePlusUser` APIs

### [Version 3.9.3](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.9.3) (April 12, 2021)

##### Added
- Adds support for installation via Swift Package Manager
- Addresses - https://github.com/CleverTap/clevertap-ios-sdk/issues/70

##### Changed
- Refactored code related to `CTTelephonyNetworkInfo` to address - https://github.com/CleverTap/clevertap-ios-sdk/issues/103
- Removes Product Experiences (Screen AB/Dynamic Variables) related code

### [Version 3.9.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.9.2) (February 5, 2021)

##### Fixed
- Removes unknown JSON attributes while handling Test In-App Notification, Test App Inbox or Test Display Unit
- Makes `model` property `atomic` (thread-safe)
- Minor Performance improvements

### [Version 3.9.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.9.1) (October 8, 2020)

##### Added
- Adds TTL for In-Apps
- Allow choosing text(with colour) when no messages to display in App Inbox

##### Fixed
- Fixes misalignment of video for Interstitial In-Apps in landscape mode
- Handles header with icon misalignment in case of overflowing characters in portrait mode
- Handles In-App alignment when status bar is hidden

##### Changed
- Update minimum deployment target to iOS 9.0

### [Version 3.9.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.9.0) (August 29, 2020)

##### Added
- Adds support for Geofence

##### Changed
- Stop capturing IDFA and removes code that has the ability to access the device’s advertising identifier (IDFA)

### [Version 3.8.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.8.2) (August 4, 2020)

##### Fixed
- Removes radio listener `CTRadioAccessTechnologyDidChangeNotification` to fix the noticeable crashes in 13.x
- Fixes carthage build error on v3.8.1
  - Addresses - https://github.com/CleverTap/clevertap-ios-sdk/issues/72

##### Changed
- Use `serviceCurrentRadioAccessTechnology` over deprecated `currentRadioAccessTechnology` in CTTelephonyNetworkInfo

### [Version 3.8.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.8.1) (July 2, 2020)

- Adds public API to raise Notification Clicked event for Push Notifications
- Adds a callback to provide Push Notifications custom key-value pairs
- Performance improvements

### [Version 3.8.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.8.0) (May 11, 2020)
- Adds support for Product Config and Feature Flag as a part of Product Experiences feature
- Performance improvements

### [Version 3.7.3](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.7.3) (March 11, 2020)
- Adds public APIs for raising Notification Clicked and Viewed events for App Inbox
- Adds public APIS for marking inbox message as read and deleting inbox message per message ID
- Bug fixes and performance improvements

### [Version 3.7.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.7.2) (December 11, 2019)
- Adds support for Native Display
- Bug fixes and performance improvements

### [Version 3.7.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.7.1) (October 17, 2019)
- Bug fixes and performance improvements

### [Version 3.7.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.7.0) (September 25, 2019)
- Adds support for AB Tests. (in closed Beta)
- Adds support for SDWebImage version 5.1
- Disable Location API calls unless CLEVERTAP_LOCATION macro is set
- Bug fixes and performance improvements

### [Version 3.6.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.6.0) (May 30, 2019)
- Adds support for SDWebImage version 5.0 

### [Version 3.5.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.5.0) (May 17, 2019)
- Adds the ability to set a custom Device ID
- Adds the ability to record Notification Viewed event for Push Notifications
- Adds support to record events in a WebView
- Enables Javascript in Custom HTML In-Apps
- In-Apps and App Inbox Landscape layout improvements
- Fixes setting Facebook as the referrer from a Facebook login deeplink

### [Version 3.4.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.4.2) (March 3, 2019)
- Fix OnUserLogin bug

### [Version 3.4.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.4.1) (February 5, 2019)
- Added support for Landscape mode in custom HTML InApps and App Inbox
- Performance improvements for App Inbox

### [Version 3.4.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.4.0) (January 14, 2019)
- Adds support for App Inbox

### [Version 3.3.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.3.0) (October 26, 2018)
- Adds support for Native InApp Notifications

### [Version 3.2.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.2.2) (September 26, 2018)
- Update Build Info

### [Version 3.2.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.2.1) (September 26, 2018)
- Fix method swizzling issue

### [Version 3.2.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.2.0) (September 5, 2018)
- Adds support to create multiple instances
- Adds support for SSL-pinning
- Adds ability to go offline (disable sending logged events to server)
- Added support for integration via Carthage
- Moved from static to dynamic framework
- Various performance enhancements

### [Version 3.1.7](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.1.7) (May 3, 2018)
- Methods for GDPR compliance
- Various performance improvements

### [Version 3.1.6](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.1.6) (October 13, 2018)
- Fix AppEx deployment target in podspec

### [Version 3.1.5](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.1.5) (September 19, 2017)
- iOS 11/Xcode 9 update

### [Version 3.1.4](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.1.4) (June 30, 2017)
- Adds API to record Screen Views
- Adds tvOS support 
- Adds modulemap for Swift import

### [Version 3.1.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.1.2) (January 31, 2017)
- Various performance enhancements

### [Version 3.1.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.1.1) (December 15, 2016)
- Various performance enhancements

### [Version 3.1.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.1.0) (October 20, 2016)
- Various performance enhancements

### [Version 3.0.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/3.0.0) (September 24, 2016)
- iOS 10/Xcode 8 release, supports iOS versions 8+
- Adds support for Rich Push Notifications, App Extensions and watchOS apps

### [Version 2.2.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.2.2) (August 18, 2016)
- Fixes Xcode 8 -> Xcode 7 archiving issue

### [Version 2.2.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.2.1) (July 21, 2016)
- Patches NSDate handling in onUserLogin

### [Version 2.2.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.2.0) (July 19, 2016)
- Adds `onUserLogin` API to support multiple distinct user profiles per device
- Adds `getLocation` API

### [Version 2.1.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.1.2) (June 29, 2016)
- Fixes handling of deep links embedded in push notifications on app launch

### [Version 2.1.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.1.1) (June 24, 2016)
- Sending non primitive values for profile/event properties doesn’t abort the entire push (just skips that particular property)

### [Version 2.1.0](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.1.0) (May 08, 2016)
- Adds ability to receive InApp Notification button click callbacks with custom key-value pairs
- Adds support for dashboard analytics on specific InApp Notification button clicks

### [Version 2.0.10](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.10) (April 06, 2016)
- Adds support for Segment bundled integration
- Removes support for Segment webhook integration
- Fixes rare thread deadlock issue

### [Version 2.0.9](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.9) (March 15, 2016)
- Adds support for migrating from Parse.com push notifications
- Adds support for multi-value (JSONArray) user profile properties
- Adds support for In-App Notification display frequency capping

### [Version 2.0.7](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.7) (February 09, 2016)
- Handles obscure exception regarding UIViewController detection

### [Version 2.0.6](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.6) (February 03, 2016)
- Fixes extremely rare issue relating to CTTelephonyNetworkInfo

### [Version 2.0.5](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.5) (January 09, 2016)
- Added `setLocation` API: if your application is collecting location you can pass it to CleverTap for, among other things, more fine-grained geo-targeting and segmentation purposes
- Added support for Segment webhook/server-side integration

### [Version 2.0.4](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.4) (December 09, 2015)
- Dropped support for iOS 6 - only support 7.0 and above
- Added optional autoIntegrate method to automatically handle device token registration and
push notification/url referrer tracking, and set up a singleton instance of the CleverTap class. This is accomplished by proxying the AppDelegate and "inserting" a CleverTap AppDelegate behind the AppDelegate. The proxy will first call the AppDelegate and then call the CleverTap AppDelegate.
- Added notification of application code of User Profile synchronization via CleverTapSyncDelegate and/or NSNotification broadcast mechanism.
- Added ability to record custom error events: `recordErrorWithMessage:(NSString -)message andErrorCode:(int)code`

### [Version 2.0.2](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.2) (September 28, 2015)
- Added iOS 9/Xcode 7 bitcode support

### [Version 2.0.1](https://github.com/CleverTap/clevertap-ios-sdk/releases/tag/2.0.1) (September 5, 2015)
- We’re now CleverTap! All the existing APIs have been changed from WizRocket to CleverTap.


