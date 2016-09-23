
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

    - **Install Using [CocoaPods](http://cocoapods.org)**

        To install in your main app target, add the following to your Podfile:

        ```
        target 'YOUR_TARGET_NAME' do  
            pod 'CleverTap-iOS-SDK'  
         end     
         ```

        If your main app is a host for a WatchOS app, instead add this:

        ```
        target 'YOUR_TARGET_NAME' do  
            pod 'CleverTap-iOS-SDK', :subspecs => ['HostWatchOS']  
        end  
        ```
        
        To install in a main app extension target, add the following to your Podfile:

        ```
        target 'YOUR_APP_EXTENSION_TARGET_NAME' do  
            pod 'CleverTap-iOS-SDK', :subspecs => ['AppExtension']  
        end
        ```

        To install in a WatchOS app extension target, add the following to your Podfile:

        ```
        target 'YOUR_WATCH_EXTENSION_TARGET_NAME' do  
             pod 'CleverTapWatchOS'  
        end
        ```

        Then run `pod install`.

    - **Manually Install the Framework** 

         - Download the latest framework [release](https://github.com/CleverTap/clevertap-ios-sdk/releases). Unzip the download.

         - Add the CleverTapSDK.framework to your Xcode Project, by dragging the CleverTapSDK.framework directory into your Project Navigator.

         - Add the following frameworks to your Xcode Project: 
            - SystemConfiguration
            - CoreTelephony
            - Security
            - UIKit
            - CoreLocation

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

