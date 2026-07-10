#import "CTLocationManager.h"

#define DEFAULT_LOCATION_ACCURACY kCLLocationAccuracyHundredMeters

typedef void (^CleverTapLocationSuccessBlock)(CLLocationCoordinate2D);
typedef void (^CleverTapLocationErrorBlock)(NSString *);

@interface CleverTapLocationRequest : NSObject
@property (nonatomic, copy) CleverTapLocationSuccessBlock successBlock;
@property (nonatomic, copy) CleverTapLocationErrorBlock errorBlock;
@end

@implementation CleverTapLocationRequest
@end

NSString *const kLocationTimeoutError = @"Location Request Timed Out: Have You Set NSLocationWhenInUseUsageDescription in Your Info.plist?";
NSString *const kLocationServicesNotEnabled = @"Location Services Not Enabled";
NSString *const kLocationPermissionDenied = @"Location Permission Denied";
NSString *const kLocationNetworkError = @"Unable To Get Location: Network Failure";
NSString *const kLocationUnavailable = @"Unable To Get Location";
static const double kLocationTimeout = 30.0;

static CLLocationManager *locationManager;

static NSMutableArray<CleverTapLocationRequest *> *pendingRequests;

static NSObject *requestsLockObject;

@implementation CTLocationManager

/**
 NOTE: If NSLocationWhenInUseUsageDescription is not set in the app's Info.plist, calls to the CLLocationManager instance will fail silently. Rely on the location timeout to stop updating and return an error in this case.
 */

+ (void)getLocationWithSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error {
    // locationServicesEnabled can block the main thread; check it off-main then resume on main.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        BOOL servicesEnabled = [CLLocationManager locationServicesEnabled];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!servicesEnabled) {
                if (error) {
                    error(kLocationServicesNotEnabled);
                }
                return;
            }
            [self requestLocationForSuccess:success andError:error];
        });
    });
}

+ (void)requestLocationForSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error {
    if (!locationManager) {
        locationManager = [CLLocationManager new];
        locationManager.desiredAccuracy = DEFAULT_LOCATION_ACCURACY;
    }

    CLAuthorizationStatus status = [self currentAuthorizationStatus];

    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        if (error) {
            error(kLocationPermissionDenied);
        }
        return;
    }

    // request the user location permission (iOS8+)
    if (status == kCLAuthorizationStatusNotDetermined) {
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
    }

    if (!requestsLockObject) {
        requestsLockObject = [NSObject new];
    }

    // keep an array of requests made while we are waiting for the location manager
    if (!pendingRequests) {
        pendingRequests = [NSMutableArray new];
    }

    // construct and add a new request
    CleverTapLocationRequest *request = [CleverTapLocationRequest new];
    request.successBlock = success;
    request.errorBlock = error;

    @synchronized (requestsLockObject) {
        [pendingRequests addObject:request];
    }

    locationManager.delegate = (id<CLLocationManagerDelegate>)self;
    if (locationManager && [locationManager respondsToSelector:@selector(startUpdatingLocation)]) {
        [locationManager performSelector:@selector(startUpdatingLocation)];
        [self scheduleLocationTimeout];
    } else if(locationManager && [locationManager respondsToSelector:@selector(requestLocation)]) {
        [locationManager performSelector:@selector(requestLocation)];
    }
}

// Use the non-blocking instance property where available.
+ (CLAuthorizationStatus)currentAuthorizationStatus {
    if (@available(iOS 14.0, *)) {
        return locationManager.authorizationStatus;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [CLLocationManager authorizationStatus];
#pragma clang diagnostic pop
    }
}


#pragma mark - CLLocationManagerDelegate

+ (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *newLocation = [locations lastObject];
    
    // test the age of the location measurement to determine if the measurement is cached
    // don't rely on cached measurements
    
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) {
        return;
    }
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) {
        return;
    }
    
    if (newLocation.horizontalAccuracy <= locationManager.desiredAccuracy) {
        if (CLLocationCoordinate2DIsValid(newLocation.coordinate)) {
            [self handleSuccess:newLocation.coordinate];
        }
    }
    
    // otherwise no-op; rely on the location timeout to stop updating
}

+ (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSString *reason;
    
    switch (error.code) {
        case kCLErrorDenied:
            reason = kLocationPermissionDenied;
            break;
        case kCLErrorNetwork:
            reason = kLocationNetworkError;
            break;
        case kCLErrorLocationUnknown:  //deliberate fall through here
        default:
            reason = kLocationUnavailable;
            break;
    }
    [self handleError:reason];
}

+ (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [self handleLocationPermissionDenied];
    }
}


#pragma mark - Helpers

+ (void)scheduleLocationTimeout {
    [self cancelLocationTimeout];
    [self performSelector:@selector(handleLocationTimeout)
               withObject:nil
               afterDelay:kLocationTimeout];
}


+ (void)cancelLocationTimeout {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(handleLocationTimeout) object:nil];
}

+ (void)handleLocationTimeout {
    [self stopUpdatingLocation];
    [self handleError:kLocationTimeoutError];
}

+ (void)handleSuccess:(CLLocationCoordinate2D)location {
    [self stopUpdatingLocation];
    
    @synchronized (requestsLockObject) {
        for (CleverTapLocationRequest *request in pendingRequests) {
            if (request.successBlock) {
                request.successBlock(location);
            }
        }
        [pendingRequests removeAllObjects];
    }
}

+ (void)handleError:(NSString *)error {
    @synchronized (requestsLockObject) {
        for (CleverTapLocationRequest *request in pendingRequests) {
            if (request.errorBlock) {
                request.errorBlock(error);
            }
        }
        [pendingRequests removeAllObjects];
    }
}

+ (void)handleLocationPermissionDenied {
    [self stopUpdatingLocation];
    [self handleError:kLocationPermissionDenied];
    locationManager = nil;
}

+ (void)stopUpdatingLocation {
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
    [self cancelLocationTimeout];
}

@end
