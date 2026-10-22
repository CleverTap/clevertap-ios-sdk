#import <Foundation/Foundation.h>

@class CleverTapInstanceConfig;
@class CTValidationResult;

@interface CTDeviceInfo : NSObject

@property (strong, readonly) NSString *sdkVersion;
@property (strong, readonly) NSString *appVersion;
@property (strong, readonly) NSString *appBuild;
@property (strong, readonly) NSString *bundleId;
@property (strong, readonly) NSString *osName;
@property (strong, readonly) NSString *osVersion;
@property (strong, readonly) NSString *manufacturer;
@property (atomic, readonly) NSString *model;
@property (strong, readonly) NSString *carrier;
@property (strong, readonly) NSString *countryCode;
@property (strong, readonly) NSString *timeZone;
@property (strong, readonly) NSString *radio;
@property (strong, readonly) NSString *vendorIdentifier;
@property (strong, readonly) NSString *deviceWidth;
@property (strong, readonly) NSString *deviceHeight;
@property (atomic, readonly) NSString *deviceId;
@property (atomic, readonly) NSString *fallbackDeviceId;
@property (atomic, readwrite) NSString *library;
@property (assign, readonly) BOOL wifi;
@property (assign, readonly) BOOL isOnline;
@property (assign, readonly) BOOL enableFileProtection;
@property (strong, readonly) NSMutableArray<CTValidationResult*>* validationErrors;
@property (strong, readonly) NSLocale *systemLocale;
@property (strong, readonly) NSNumber *deviceType;
@property (assign, readonly) BOOL lowPowerModeEnabled;
// NSProcessInfoThermalState raw value, nil below iOS/tvOS 11.
@property (strong, readonly) NSNumber *thermalState;
// Display settings are cached by refreshDisplaySettings, nil until the first refresh with a key window.
@property (atomic, strong, readonly) NSNumber *darkMode;
@property (atomic, strong, readonly) NSString *textSize;
@property (atomic, strong, readonly) NSNumber *reduceMotion;
// Raw UNAuthorizationStatus: 0 not asked, 1 denied, 2 allowed, 3 provisional, 4 ephemeral.
// Cached by refreshPushStatus, nil until the first read completes.
@property (atomic, strong, readonly) NSNumber *pushStatus;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config andCleverTapID:(NSString *)cleverTapID;
- (void)forceUpdateDeviceID:(NSString *)newDeviceID;
- (void)forceNewDeviceID;
- (void)forceUpdateCustomDeviceID:(NSString *)cleverTapID;
- (BOOL)isErrorDeviceID;
- (void)refreshDisplaySettings;
- (void)refreshPushStatus;
@end
