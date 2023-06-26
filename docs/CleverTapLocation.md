# Overview
You can use the `CleverTapLocation` module to get the user's location (and possibly track the location for events).

# Installation

- Cocoapods
- Swift Package Manager
- Manual Installation

# Cocoapods

Add the following to your Podfile:

  ```
  target 'YOUR_TARGET_NAME' do  
      pod 'CleverTapLocation'  
  end     
  ```
Then run pod install.

# Swift Package Manager

1. Open your project and navigate to the project's settings. Select the tab named Swift Packages and click on the add button (+) at the bottom left.
 
  <p align="center">
  <img alt="Light" src="/docs/images/spm-image-1.png" width="85%">
  </p>  
  
2. Enter the URL of CleverTap GitHub repository - https://github.com/CleverTap/clevertap-ios-sdk.git and click Next.

  <p align="center">
  <img alt="Light" src="/docs/images/spm-image-2.png" width="85%">
  </p>  

3. On the next screen, select the preferred SDK version and click Next.
  
  <p align="center">
  <img alt="Light" src="/docs/images/spm-image-3.png" width="85%">
  </p>  

4. Click finish and ensure that the CleverTapLocation has been added to the appropriate target.

  <p align="center">
  <img alt="Light" src="/docs/images/spm-image-5.png" width="85%">
  </p>

# Manual Installation

- Clone the CleverTap iOS SDK repository recursively:
   ```
    git clone --recursive https://github.com/CleverTap/clevertap-ios-sdk.git
    ```
- Navigate to `CleverTapLocation` folder and add the `CleverTapLocation.xcodeproj` to your Xcode Project, by dragging the `CleverTapLocation.xcodeproj` under the main project file.

- Navigate to the project application’s target settings, open "General", click the "+" button under the "Frameworks, Libraries, and Embedded Content", add CleverTapLocation.framework as an embedded binary.

# Integration

```swift
// Swift

import CleverTapLocation

CTLocationManager.getLocationWithSuccess { coordinate in
    print(coordinate)
} andError: { reason in
        print(reason)
    }
```

```objectivec
// Objective-C

#import <CleverTapLocation/CTLocationManager.h>

[CTLocationManager getLocationWithSuccess:^(CLLocationCoordinate2D location) {
    NSLog(@"%@",location);
} andError:^(NSString *reason) {
    NSLog(@"%@",reason);
}];

```

