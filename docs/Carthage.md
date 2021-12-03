# [Carthage](https://github.com/Carthage/Carthage) for CleverTap

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
