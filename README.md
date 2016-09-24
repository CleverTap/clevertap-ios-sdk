
[![CleverTap Logo](http://staging.support.wizrocket.com.s3-website-eu-west-1.amazonaws.com/images/CleverTap_logo.png)](http:www.clevertap.com)

# CleverTap iOS SDK  
[![CI Status](http://img.shields.io/travis/CleverTap/clevertap-ios-sdk.svg?style=flat)](https://travis-ci.org/CleverTap/clevertap-ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![Platform](https://img.shields.io/cocoapods/p/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)

The CleverTap iOS SDK for App Personalization and Engagement  

CleverTap is the next generation app engagement platform. It enables marketers to identify, engage and retain users and provides developers with unprecedented code-level access to build dynamic app experiences for multiple user groups. CleverTap includes out-of-the-box prescriptive campaigns, omni-channel messaging, uninstall data and the industry's largest FREE messaging tier.

For more information check out our [website](https://clevertap.com "CleverTap") and [documentation](http://support.clevertap.com "CleverTap Technical Documentation").

## Getting Started

1. Sign Up

    [Sign up](https://clevertap.com/sign-up) for a free account.  

2.  Install the Framework

    Starting with v3.0.0, the SDK adds support for App Extensions and watchOS apps via separate SDK target builds.

    - **Install Using [CocoaPods](http://cocoapods.org)**

        For just the basic SDK functionality in your main app, add the following to your Podfile:

        ```
        target 'YOUR_TARGET_NAME' do  
            pod 'CleverTap-iOS-SDK'  
         end     
         ```

        If your main app is also a watchOS Host, and you wish to capture custom events from your watchOS app, add this (instead of the basic SDK):

        ```
        target 'YOUR_TARGET_NAME' do  
            pod 'CleverTap-iOS-SDK', :subspecs => ['HostWatchOS']  
        end  
        ```

        and this:

        ```
        target 'YOUR_WATCH_EXTENSION_TARGET_NAME' do  
             pod 'CleverTapWatchOS'  
        end
        ```
        
        If you wish to capture custom events from your main App Extension target(s), also add the following to your Podfile:

        ```
        target 'YOUR_APP_EXTENSION_TARGET_NAME' do  
            pod 'CleverTap-iOS-SDK', :subspecs => ['AppExtension']  
        end
        ```

        Then run `pod install`.

        [See example Podfile here](https://github.com/CleverTap/ios-10-demo/blob/master/Podfile)


    - **Manually Install the Framework** 

        For just the basic SDK functionality in your main app:

         - Download the latest framework [release](https://github.com/CleverTap/clevertap-ios-sdk/releases). Unzip the download.

         - Add the CleverTapSDK.framework to your Xcode Project, by dragging the CleverTapSDK.framework directory into your Project Navigator.

         - Add the following frameworks to your Xcode Project: 
            - SystemConfiguration
            - CoreTelephony
            - UIKit
            - CoreLocation

        If your main app is also a watchOS Host, and you wish to capture custom events from your watchOS app:
        
        - follow the steps above, but add CleverTapSDK.hostwatchos.framework instead of CleverTapSDK.framework.
        - add [the CleverTapWatchOS Swift framework](https://github.com/CleverTap/clevertap-ios-sdk/tree/master/CleverTapWatchOS) to your watchOS Extension target(s). 

        If you also wish to capture custom events from your main App Extension target(s):

        - add the CleverTapSDK.appex.framework to those target(s)

3. Add Your CleverTap Account Credentials

    Update your .plist file:

    * Create a key called CleverTapAccountID with a string value
    * Create a key called CleverTapToken with a string value
    * Insert the values from your CleverTap [Dashboard](https://dashboard.clevertap.com) -> Settings -> Integration Details.


    ![plist account values](http://staging.support.wizrocket.com.s3-website-eu-west-1.amazonaws.com/images/integration/plist-account.png)

### Swift

1. Follow the Install and Add Your CleverTap Account Credentials steps above.  
2. Add the [CleverTapSDK-Bridging-Header.h](https://github.com/CleverTap/clevertap-ios-sdk/blob/master/SwiftStarterProject/CleverTapSDK-Bridging-Header.h) (rename to YOUR-PROJECT-NAME-Bridging-Header.h, if you like) to your project.  
3. Add the path to that Bridging-Header.h in the Objective-C Bridging Header section of your project's Build Settings.  

Alternatively, add the contents of the CleverTapSDK-Bridging-Header.h to your existing Bridging Header file.    

## Example Usage
To run the example StarterProject, clone the repo, and run `pod install` from the StarterProject directory.  Then open the StarterProject.xcworkspace, add your CleverTap account credentials to the Info.plist and build and run.
For Swift, please refer to the SwiftStarterProject. 

For non-CocoaPods folks, check out the example StarterProjectManualInstall.  
For Swift, please refer to the SwiftStarterProjectManualInstall example. 

For App Extension and watchOS usage, [please refer to this demo project](https://github.com/CleverTap/ios-10-demo).
