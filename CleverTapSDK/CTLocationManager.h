
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CTLocationManager : NSObject

#if defined(CLEVERTAP_LOCATION)
+ (void)getLocationWithSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error;
#endif

@end
