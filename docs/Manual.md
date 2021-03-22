# Manual Installation for CleverTap

| :bulb:  We strongly recommend that you implement the SDK via a [CocoaPod](http://cocoapods.org/). However, if you are unable to do so you may complete installation manually using our manual integration instructions below. |
|-----------------------------------------|

- Clone the CleverTap iOS SDK repository recursively:
   ```
    git clone --recursive https://github.com/CleverTap/clevertap-ios-sdk.git
    ```
- Add the `CleverTapSDK.xcodeproj` to your Xcode Project, by dragging the `CleverTapSDK.xcodeproj` under the main project file.

- **SDWebImage Integration:** This library provides an async image downloader with cache support. We are using the SDWebImage cache library in our engagement channels. For example, CleverTap App Inbox uses SDWebImage for image cache and async loading for the image, another example would be CleverTap In-Apps that provides support to display gifs. 

  Please follow the steps below for integrating SDWebImage:
  - Navigate to the `Vendors/SDWebImage` directory found under the cloned CleverTap iOS SDK repository. 
  - Drag-n-drop `SDWebImage.xcodeproj` into the main Project file.
  
- Navigate to the project application’s target settings, open "General", click the "+" button under the "Frameworks, Libraries, and Embedded Content", add `CleverTapSDK.framework` and `SDWebImage.framework` as an embedded binary.
