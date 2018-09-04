
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CTLocationManager : NSObject

+ (void)getLocationWithSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error;

@end
