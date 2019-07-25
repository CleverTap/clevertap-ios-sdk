

# CleverTap iOS SDK  
[![CI Status](https://api.travis-ci.org/CleverTap/clevertap-ios-sdk.svg?branch=master)](https://travis-ci.org/CleverTap/clevertap-ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![Platform](https://img.shields.io/cocoapods/p/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

The CleverTap iOS SDK for App Analytics and Engagement

CleverTap combines real-time customer insights, an advanced segmentation engine, and powerful engagement tools into one intelligent marketing platform.

For more information check out our [website](https://clevertap.com "CleverTap") and [documentation](http://support.clevertap.com "CleverTap Technical Documentation").

## Setup #

1. Sign Up

    [Sign up](https://clevertap.com/sign-up) for a free account.  

2.  Install the Framework 

    Starting with v3.0.0, the SDK adds support for App Extensions and watchOS apps.  Starting with v3.1.3, the SDK adds support for tvOS.

    - **Install Using [CocoaPods](http://cocoapods.org)**

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
    

    - **Install Using [Carthage](https://github.com/Carthage/Carthage)** 

        CleverTap also supports `Carthage` to package your dependencies as a framework.

        To integrate CleverTap into your Xcode project using Carthage, specify it in your `Cartfile`:

        ```
        github "CleverTap/clevertap-ios-sdk"
        ```

        Run `carthage update` to build the framework and drag the built `CleverTapSDK.framework` into your Xcode project.


    - **Manually Install the Framework** 

      For just the basic SDK functionality in your main app:

        - Download the latest framework [release](https://github.com/CleverTap/clevertap-ios-sdk/releases). Unzip the download.

        - Add the CleverTapSDK.xcodeproj to your Xcode Project, by dragging the CleverTapSDK.xcodeproj under the main project file.

        - Embed the framework. Select your app.xcodeproj file. Under "General", add the CleverTapSDK framework as an embedded binary

3. Add Your CleverTap Account Credentials 

    Update your .plist file:

    * Create a key called CleverTapAccountID with a string value
    * Create a key called CleverTapToken with a string value
    * Insert the values from your CleverTap [Dashboard](https://dashboard.clevertap.com) -> Settings -> Integration Details.

For more details, Please refer to our [installation guide](https://developer.clevertap.com/docs/ios-quickstart-guide) for instructions on installing and using our iOS SDK in your project.

## Example Usage #

* A [demo application](https://github.com/CleverTap/clevertap-ios-sdk/tree/master/ObjCStarter) showing the integration of our SDK in Objective-C language.
* A [demo application](https://github.com/CleverTap/clevertap-ios-sdk/tree/master/SwiftStarter) showing the integration of our SDK in Swift language.

## Changelog #

Check out the CleverTap iOS SDK [Change Log](https://github.com/CleverTap/clevertap-ios-sdk/blob/master/CHANGELOG.md) here.

## Questions? #

 If you have questions or concerns, you can reach out to the CleverTap support team at [support@clevertap.com](mailto:support@clevertap.com).
 
 ## License #

Check out the CleverTap iOS SDK [License](https://github.com/CleverTap/clevertap-ios-sdk/blob/master/LICENSE) here.

