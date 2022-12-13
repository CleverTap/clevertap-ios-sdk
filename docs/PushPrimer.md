##  🔖 Overview

Push Primer allows you to enable runtime push permission for sending notifications from an app.

Starting with the 4.2.0 release, CleverTap supports Push primer for push notification runtime permission through local in-app.
Minimum iOS version supported: 10.0

### Push Primer using Half-Interstitial local In-app
```objc
// Objective-C
#import <CleverTapSDK/CTLocalInApp.h>

// Required field.
CTLocalInApp *localInAppBuilder = [[CTLocalInApp alloc] initWithInAppType:HALF_INTERSTITIAL
                                                                titleText:@"Get Notified"
                                                              messageText:@"Please enable notifications on your device to use Push Notifications."
                                                  followDeviceOrientation:YES
                                                          positiveBtnText:@"Allow"
                                                          negativeBtnText:@"Cancel"];

// Optional fields.
[localInAppBuilder setFallbackToSettings:YES];	// default is NO.
[localInAppBuilder setBackgroundColor:@"#FFFFFF"];	// default is White.
[localInAppBuilder setTitleTextColor:@"#FF0000"];
[localInAppBuilder setMessageTextColor:@"#FF0000"];
[localInAppBuilder setBtnBorderRadius:@"4"];	// default is @"2".
[localInAppBuilder setBtnTextColor:@"#FF0000"];
[localInAppBuilder setBtnBorderColor:@"#FF0000"];
[localInAppBuilder setBtnBackgroundColor:@"#FFFFFF"];	// default is White.
[localInAppBuilder setImageUrl:@"https://icons.iconarchive.com/icons/treetog/junior/64/camera-icon.png"];

// Prompt Push Primer with above settings.
[[CleverTap  sharedInstance] promptPushPrimer:localInAppBuilder.getLocalInAppSettings];
```
```swift
// Swift
import CleverTapSDK

// Required field.
let localInAppBuilder = CTLocalInApp(inAppType: CTLocalInAppType.HALF_INTERSTITIAL,
                                     titleText: "Get Notified",
                                     messageText: "Please enable notifications on your device to use Push Notifications.",
                                     followDeviceOrientation: true,
                                     positiveBtnText: "Allow",
                                     negativeBtnText: "Cancel")

// Optional fields.
localInAppBuilder.setFallbackToSettings(true)
localInAppBuilder.setBackgroundColor("#FFFFFF")
localInAppBuilder.setTitleTextColor("#FF0000")
localInAppBuilder.setMessageTextColor("#FF0000")
localInAppBuilder.setBtnBorderRadius("4")
localInAppBuilder.setBtnTextColor("#FF0000")
localInAppBuilder.setBtnBorderColor("#FF0000")
localInAppBuilder.setBtnBackgroundColor("#FFFFFF")
localInAppBuilder.setImageUrl("https://icons.iconarchive.com/icons/treetog/junior/64/camera-icon.png")

// Prompt Push Primer with above settings.
CleverTap.sharedInstance()?.promptPushPrimer(localInAppBuilder.getSettings())
```
### Push Primer using Alert local In-app
```objc
// Objective-C
#import <CleverTapSDK/CTLocalInApp.h>

// Required field.
CTLocalInApp *localInAppBuilder = [[CTLocalInApp alloc] initWithInAppType:ALERT
                                                                titleText:@"Get Notified"
                                                              messageText:@"Enable Notification permission"
                                                  followDeviceOrientation:YES
                                                          positiveBtnText:@"Allow"
                                                          negativeBtnText:@"Cancel"];

// Optional fields.
[localInAppBuilder setFallbackToSettings:YES];

// Prompt Push Primer with above settings.
[[CleverTap  sharedInstance] promptPushPrimer:localInAppBuilder.getLocalInAppSettings];
```
```swift
// Swift
import CleverTapSDK

// Required field.
let localInAppBuilder = CTLocalInApp(inAppType: .ALERT,
                                     titleText: "Get Notified",
                                     messageText: "Enable Notification permission",
                                     followDeviceOrientation: true,
                                     positiveBtnText: "Allow",
                                     negativeBtnText: "Cancel")

// Optional fields.
localInAppBuilder.setFallbackToSettings(true)

// Prompt Push Primer with above settings.
CleverTap.sharedInstance()?.promptPushPrimer(localInAppBuilder.getSettings())
```
### Call iOS Push Permission dialog without using Push Primer
Takes boolean as a parameter. If true and permission is denied then we fallback to app’s notification settings. If false then we just throw a verbose log saying permission is denied.
```objc
// Objective-C

[[CleverTap  sharedInstance] promptForPushPermission:YES];
```
```swift
// Swift

CleverTap.sharedInstance()?.prompt(forPushPermission: true)
```
### Get iOS Push notification permission status
Returns status of the push notification in completion handler.
```objc
// Objective-C

[[CleverTap  sharedInstance] getNotificationPermissionStatusWithCompletionHandler:^(UNAuthorizationStatus status) {
	if (status == UNAuthorizationStatusNotDetermined || status == UNAuthorizationStatusDenied) {
		// call push primer here.
	} else {
		NSLog(@"Push Persmission is already enabled.");
	}
}];
```
```swift
// Swift

CleverTap.sharedInstance()?.getNotificationPermissionStatus(completionHandler: { status in
	if status == .notDetermined || status == .denied {
		// call push primer here.
	} else {
		print("Push Persmission is already enabled.")
	}
})
```
###  CTLocalInApp builder methods description

Builder Methods | Parameters | Description | Required
:---:|:---:|:---:|:---
`inAppType(CTLocalInAppType)` | CTLocalInAppType.HALF_INTERSTITIAL OR CTLocalInAppType.ALERT | Accepts only HALF_INTERSTITIAL & ALERT type to display the type of InApp | Required
`titleText(NSString *)` | Text | Sets the title of the local in-app | Required
`messageText(NSString *)` | Text | Sets the subtitle of the local in-app | Required
`followDeviceOrientation(BOOL)` | YES/NO | If true then the local InApp is shown for both portrait and landscape. If it sets false then local InApp only displays for portrait mode | Required
`positiveBtnText(NSString *)` | Text | Sets the text of the positive button | Required
`negativeBtnText(NSString *)` | Text | Sets the text of the negative button | Required
`setFallbackToSettings(BOOL)` | YES/NO | If true and the permission is denied then we fallback to app’s notification settings, if it’s false then we just throw a verbose log saying permission is denied | Optional
`setBackgroundColor(NSString *)` | Accepts Hex color as String | Sets the background color of the local in-app | Optional
`setBtnBorderColor(NSString *)` | Accepts Hex color as String | Sets the border color of both positive/negative buttons | Optional
`setTitleTextColor(NSString *)` | Accepts Hex color as String | Sets the title color of the local in-app | Optional
`setMessageTextColor(NSString *)` | Accepts Hex color as String | Sets the sub-title color of the local in-app | Optional
`setBtnTextColor(NSString *)` | Accepts Hex color as String | Sets the color of text for both positive/negative buttons | Optional
`setBtnBackgroundColor(NSString *)` | Accepts Hex color as String | Sets the background color for both positive/negative buttons | Optional
`setBtnBorderRadius(NSString *)` | Text | Sets the radius for both positive/negative buttons. Default radius is “2” if not set | Optional
`(NSDictionary *)getLocalInAppSettings` | Returns Dictionary containing all parameters | The dictionary is passed as an argument in `promptPushPrimer` to display push primer | Required

###  Available Callbacks for Push Primer in iOS
Based on notification permission grant/deny, we’ll be providing a callback with permission status. To use this, make sure your class conforms the `CleverTapPushPermissionDelegate` and implement following method as below:
```objc
// Objective-C
// Set the delegate 
[[CleverTap  sharedInstance] setPushPermissionDelegate:self];

// CleverTapPushPermissionDelegate method
- (void)onPushPermissionResponse:(BOOL)accepted {
	NSLog(@"Push Permission response called ---> accepted = %d", accepted);
}
```
```swift
// Swift
// Set the delegate 
CleverTap.sharedInstance()?.setPushPermissionDelegate(self)

// CleverTapPushPermissionDelegate method
func  onPushPermissionResponse(_ accepted: Bool) {
	print("Push Permission response called ---> accepted = \(accepted)")
}
```


