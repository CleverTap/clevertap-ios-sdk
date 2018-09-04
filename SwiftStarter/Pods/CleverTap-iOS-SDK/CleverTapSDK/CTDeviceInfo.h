#import <Foundation/Foundation.h>

@class CleverTapInstanceConfig;

@interface CTDeviceInfo : NSObject

@property (strong, readonly) NSString *sdkVersion;
@property (strong, readonly) NSString *appVersion;
@property (strong, readonly) NSString *appBuild;
@property (strong, readonly) NSString *bundleId;
@property (strong, readonly) NSString *osName;
@property (strong, readonly) NSString *osVersion;
@property (strong, readonly) NSString *manufacturer;
@property (strong, readonly) NSString *model;
@property (strong, readonly) NSString *carrier;
@property (strong, readonly) NSString *countryCode;
@property (strong, readonly) NSString *timeZone;
@property (strong, readonly) NSString *radio;
@property (strong, readonly) NSString *advertisingIdentitier;
@property (strong, readonly) NSString *vendorIdentifier;
@property (strong, readonly) NSString *deviceWidth;
@property (strong, readonly) NSString *deviceHeight;
@property (atomic, readonly) NSString *deviceId;
@property (assign, readonly) BOOL wifi;
@property (assign, readonly) BOOL advertisingTrackingEnabled;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;
- (void)forceUpdateDeviceID:(NSString *)newDeviceID;
- (void)forceNewDeviceID;

@end
