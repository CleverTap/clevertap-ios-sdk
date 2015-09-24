
[![CleverTap Logo](http://staging.support.wizrocket.com.s3-website-eu-west-1.amazonaws.com/images/CleverTap_logo.png)](http:www.clevertap.com)

# CleverTap iOS SDK  
[![CI Status](http://img.shields.io/travis/CleverTap/clevertap-ios-sdk.svg?style=flat)](https://travis-ci.org/CleverTap/clevertap-ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![Platform](https://img.shields.io/cocoapods/p/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)

The CleverTap iOS SDK for App Personalization and Engagement  

CleverTap is the next generation app engagement platform. It enables marketers to identify, engage and retain users and provides developers with unprecedented code-level access to build dynamic app experiences for multiple user groups. CleverTap includes out-of-the-box prescriptive campaigns, omni-channel messaging, uninstall data and the industry's largest FREE messaging tier.

For more information check out our [website](http://www.clevertap.com "CleverTap") and [documentation](http://support.wizrocket.com "CleverTap Technical Documentation").

## Getting Started

1. Sign Up

    [Sign up](http://www.clevertap.com/sign-up.html) for a free account.  

2.  Install the Framework

    - **Install Using [CocoaPods](http://cocoapods.org)**

        Just add the following line to your Podfile:

        ```
        pod "CleverTap-iOS-SDK"
        ```

        Then run `pod install`.

    - **Manually Install the Framework** 

         - Download the latest framework [release](https://github.com/CleverTap/clevertap-ios-sdk/releases). Unzip the download.

         - Add the CleverTapSDK.framework to your Xcode Project, by dragging the CleverTapSDK.framework directory into your Project Navigator.

         - Add the following frameworks to your Xcode Project: 
            - SystemConfiguration
            - CoreTelephony
            - UIKit
            - CoreLocation (optional)

3. Add Your CleverTap Account Credentials

    Update your .plist file:

    * Create a key called CleverTapAccountID with a string value
    * Create a key called CleverTapToken with a string value
    * Insert the values from your CleverTap [Dashboard](https://dashboard.clevertap.com) -> Settings -> Integration Details.


    ![plist account values](http://staging.support.wizrocket.com.s3-website-eu-west-1.amazonaws.com/images/integration/plist-account.png)

## Example Usage
To run the example StarterProject, clone the repo, and run `pod install` from the StarterProject directory.  Then open the StarterProject.xcworkspace, add your CleverTap account credentials to the Info.plist and build and run.

