<p align="center">
  <img src="https://github.com/CleverTap/clevertap-segment-ios/blob/master/clevertap-logo.png" width="300"/>
</p>

# CleverTap iOS SDK  
[![CI Status](https://api.travis-ci.org/CleverTap/clevertap-ios-sdk.svg?branch=master)](https://travis-ci.org/CleverTap/clevertap-ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![Platform](https://img.shields.io/cocoapods/p/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
![iOS 8.0+](https://img.shields.io/badge/iOS-9.0%2B-blue.svg)
![tvOS 9.0+](https://img.shields.io/badge/tvOS-9.0%2B-blue.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## 👋 Introduction

The CleverTap iOS SDK for Mobile Customer Engagement and Analytics solutions

CleverTap brings together real-time user insights, an advanced segmentation engine, and easy-to-use marketing tools in one mobile marketing platform — giving your team the power to create amazing experiences that deepen customer relationships. Our intelligent mobile marketing platform provides the insights you need to keep users engaged and drive long-term retention and growth.

For more information check out our  [website](https://clevertap.com/ "CleverTap")  and  [documentation](https://developer.clevertap.com/docs/ "CleverTap Technical Documentation").

To get started, sign up [here](https://clevertap.com/live-product-demo/)

## 📋 Requirements
Following are required for using CleverTap iOS SDK -
- iOS 9.0 or later
- tvOS 9.0 or later
- Xcode 10.0 or later

## 🎉 Installation

### [CocoaPods](https://cocoapods.org)

For your iOS, App Extension target(s) and tvOS app, add the following to your Podfile:

  ```
  target 'YOUR_TARGET_NAME' do  
      pod 'CleverTap-iOS-SDK'  
  end     
  ```

  If your main app is also a watchOS Host, and you wish to capture custom events from your watchOS app, add this:

  ```
  target 'YOUR_WATCH_EXTENSION_TARGET_NAME' do  
      pod 'CleverTapWatchOS'  
  end
  ```

  Also, you will need to enable the preprocessor macro via your Podfile by adding this post install hook:

  ```
  post_install do |installer_representation|
      installer_representation.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 
              'CLEVERTAP_HOST_WATCHOS=1']
          end
     end
  end
  ```

Then run `pod install`.

### [Carthage](https://github.com/Carthage/Carthage)

CleverTap also supports `Carthage` to package your dependencies as a framework.

To integrate CleverTap into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "CleverTap/clevertap-ios-sdk"
```

Run `carthage update` to build the framework and drag the built `CleverTapSDK.framework` into your Xcode project.

Also, follow steps to link SDWebImage into your project

* In your Project, go to Carthage folder
* Select clevertap-ios-sdk under Checkouts
* Drag the built `SDWebImage.framework` from Vendors into your Frameworks and Libraries

### Manually

- Download the latest framework [release](https://github.com/CleverTap/clevertap-ios-sdk/releases). Unzip the download.

- Add the CleverTapSDK.xcodeproj to your Xcode Project, by dragging the CleverTapSDK.xcodeproj under the main project file.

- Embed the framework. Select your app.xcodeproj file. Under "General", add the CleverTapSDK framework as an embedded binary

## 🚀 Integration

#### Add your CleverTap account credentials

Update your .plist file:

* Create a key called **CleverTapAccountID** with a string value
* Create a key called **CleverTapToken** with a string value
* Insert the values from your CleverTap [Dashboard](https://dashboard.clevertap.com) -> Settings -> Integration Details.

For more details, refer to our [installation guide](https://developer.clevertap.com/docs/ios-quickstart-guide) for instructions on installing and using our iOS SDK in your project.

## 📲 Rich Push Notifications

Apart from Title and Message, you have the below-mentioned options to add to your iOS push notification. Please note that each of these is optional.
- [CTNotificationService](https://github.com/CleverTap/CTNotificationService)
- [CTNotificationContent](https://github.com/CleverTap/CTNotificationContent)

For more details, refer to our [Advanced iOS Push Notifications](https://developer.clevertap.com/docs/ios#section-advanced-ios-push-notifications) guide.

## 📍 Geofence 

CleverTap Geofence SDK provides Geofencing capabilities to CleverTap iOS SDK. To find the installation & integration steps for CleverTap Geofence SDK, click [here](https://github.com/CleverTap/clevertap-geofence-ios).

## 𝌡 Example Usage
* A [demo application](https://github.com/CleverTap/clevertap-ios-sdk/tree/master/ObjCStarter) showing the integration of our SDK in Objective-C language.
* A [demo application](https://github.com/CleverTap/clevertap-ios-sdk/tree/master/SwiftStarter) showing the integration of our SDK in Swift language.

## 🆕 Change Log

Refer to the [CleverTap iOS SDK Change Log](https://github.com/CleverTap/clevertap-ios-sdk/blob/master/CHANGELOG.md).

## 📄 License

CleverTap iOS SDK is released under the MIT license. See [LICENSE](https://github.com/CleverTap/clevertap-ios-sdk/blob/master/LICENSE) for details.


