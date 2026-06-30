# Manual Installation for CleverTap

| :bulb:  We strongly recommend that you implement the SDK via a [CocoaPod](http://cocoapods.org/). However, if you are unable to do so you may complete installation manually using our manual integration instructions below. |
|-----------------------------------------|

- Clone the CleverTap iOS SDK repository:
   ```
    git clone https://github.com/CleverTap/clevertap-ios-sdk.git
    ```
- Add the `CleverTapSDK.xcodeproj` to your Xcode Project, by dragging the `CleverTapSDK.xcodeproj` under the main project file.

- Navigate to the project application’s target settings, open "General", click the "+" button under the "Frameworks, Libraries, and Embedded Content", add `CleverTapSDK.framework` as an embedded binary.
