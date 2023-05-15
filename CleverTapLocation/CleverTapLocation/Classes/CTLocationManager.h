#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CTLocationManager : NSObject

/*!
 @method
 
 @abstract
 Get the device location if available.  Calling this will prompt the user location permissions dialog.
 
 Please be sure to include the NSLocationWhenInUseUsageDescription key in your Info.plist.  See https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW26
 
 Uses desired accuracy of kCLLocationAccuracyHundredMeters.
 
 If you need background location updates or finer accuracy please implement your own location handling.  Please see https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/index.html for more info.
 
 @discussion
 Optional.  You can use location to pass it to CleverTap via the setLocation API
 for, among other things, more fine-grained geo-targeting and segmentation purposes. 
 */
+ (void)getLocationWithSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error;

@end
