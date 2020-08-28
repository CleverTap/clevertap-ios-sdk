# Change Log
All notable changes to this project will be documented in this file.

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


