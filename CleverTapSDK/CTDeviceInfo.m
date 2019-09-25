#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#include <sys/types.h>

#import "CleverTap.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTDeviceInfo.h"
#import "CTValidator.h"
#import "CTValidationResult.h"
#import "CleverTapBuildInfo.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"

#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

NSString* const kCLTAP_DEVICE_ID_TAG = @"deviceId";
NSString* const kCLTAP_FALLBACK_DEVICE_ID_TAG = @"fallbackDeviceId";

NSString* const kCLTAP_ERROR_PROFILE_PREFIX = @"-i";

static BOOL advertisingTrackingEnabled;
static NSRecursiveLock *deviceIDLock;
static NSString *_idfv;
static NSString *_idfa;
static NSString *_sdkVersion;
static NSString *_appVersion;
static NSString *_bundleId;
static NSString *_build;
static NSString *_osVersion;
static NSString *_model;
static NSObject* _networkInfo;
static NSString *_carrier;
static NSString *_countryCode;
static NSString *_timeZone;
static NSString *_radio;
static NSString *_deviceWidth;
static NSString *_deviceHeight;
static NSString *_deviceName;
static BOOL _wifi;

#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
SCNetworkReachabilityRef _reachability;
#endif

@interface CTDeviceInfo () {}

@property (nonatomic, strong) CleverTapInstanceConfig *config;

@property (strong, readwrite) NSString *deviceId;
@property (strong, readwrite) NSString *fallbackDeviceId;
@property (strong, readwrite) NSString *advertisingIdentitier;
@property (strong, readwrite) NSString *vendorIdentifier;
@property (strong, readonly) NSObject *networkInfo;
@property (strong, readwrite) NSMutableArray *validationErrors;

@end

@implementation CTDeviceInfo

@synthesize deviceId=_deviceId;
@synthesize validationErrors=_validationErrors;

static dispatch_queue_t backgroundQueue;
#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
static const char *backgroundQueueLabel = "com.clevertap.deviceInfo.backgroundQueue";
#endif

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _idfa = [self getIDFA];
        _idfv = [self getIDFV];
        deviceIDLock = [NSRecursiveLock new];
    #if !CLEVERTAP_NO_REACHABILITY_SUPPORT
        backgroundQueue = dispatch_queue_create(backgroundQueueLabel, DISPATCH_QUEUE_SERIAL);
        // reachability callback
        if ((_reachability = SCNetworkReachabilityCreateWithName(NULL, "wzrkt.com")) != NULL) {
            SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
            if (SCNetworkReachabilitySetCallback(_reachability, CleverTapReachabilityHandler, &context)) {
                if (!SCNetworkReachabilitySetDispatchQueue(_reachability, backgroundQueue)) {
                    SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
                }
            }
        }
    #endif
    });
}

#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
static void CleverTapReachabilityHandler(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    [[CTDeviceInfo class] handleReachabilityUpdate:flags];
}

+ (void)handleReachabilityUpdate:(SCNetworkReachabilityFlags)flags {
    _wifi = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN);
    CleverTapLogStaticInternal(@"Updating wifi to: %@", @(_wifi));
}
#endif

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config andCleverTapID:(NSString *)cleverTapID{
    if (self = [super init]) {
        _config = config;
        _validationErrors = [NSMutableArray new];
        [self initDeviceID:cleverTapID];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.DeviceInfo.%@", self.config.accountId];
}

- (NSString *)deviceId {
    return _deviceId ? _deviceId : self.fallbackDeviceId;
}

- (void)setDeviceId:(NSString *)deviceId {
    _deviceId = deviceId;
}

-(BOOL)isErrorDeviceID {
    return [self.deviceId hasPrefix:kCLTAP_ERROR_PROFILE_PREFIX];
}

+ (NSString *)getIDFV {
    NSString *identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (identifier && ![identifier isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
        identifier = [[identifier stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    } else {
        identifier = nil;
    }
    return identifier;
}

+ (NSString *)getIDFA {
    
    NSString *identifier;
    
    @try {
        Class asim = NSClassFromString(@"ASIdentifierManager");
        if (!asim) {
            return nil;
        }
        SEL smSelector = NSSelectorFromString(@"sharedManager");
        id sm = ((id (*)(id, SEL)) [asim methodForSelector:smSelector])(asim, smSelector);
        
        SEL ateSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        
        advertisingTrackingEnabled = ((BOOL(*)(id, SEL)) [sm methodForSelector:ateSelector])(sm, ateSelector);
        
        SEL aiSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID *(*)(id, SEL)) [sm methodForSelector:aiSelector])(sm, aiSelector);
        identifier = [uuid UUIDString];
        
        if (identifier && ![identifier isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
            identifier = [[identifier stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
        } else {
            identifier = nil;
        }
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"Error checking availability of IDFA: %@", e.debugDescription);
    }
    
    return identifier;
}

+ (NSString*)getPlatformName {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

- (void)initDeviceID:(NSString *)cleverTapID {
    @try {
        [deviceIDLock lock];

        _idfa = _idfa ? _idfa : [[self class] getIDFA];
        if (self.config.useIDFA && _idfa && [_idfa length] > 5) {
            self.advertisingIdentitier = _idfa;
        }
        _idfv = _idfv ? _idfv : [[self class] getIDFV];
        if (_idfv && [_idfv length] > 5) {
            self.vendorIdentifier = _idfv;
        }
        
        // set the fallbackdeviceId on launch, in the event this instance had a fallbackid on last close
        self.fallbackDeviceId = [self getStoredFallbackDeviceID];
        
        if (!self.config.useCustomCleverTapId && cleverTapID != nil) {
            NSString *errorString = [NSString stringWithFormat:@"%@: CleverTapUseCustomId has not been specified in the Info.plist/instance configuration. Custom CleverTap ID: %@ will not be used.", self, cleverTapID];
            CleverTapLogInfo(self.config.logLevel, @"%@", errorString);
            [self recordDeviceError:errorString];
        }
        
        // Is the device ID already present?
        NSString *existingDeviceID = [self getDeviceID];
        if (existingDeviceID) {
            if (self.config.useCustomCleverTapId && cleverTapID && ![[existingDeviceID substringFromIndex:2] isEqualToString:cleverTapID]) {
                NSString *errorString = [NSString stringWithFormat:@"%@: CleverTap ID: %@ already exists. Unable to set custom CleverTap ID: %@", self,  existingDeviceID, cleverTapID];
                CleverTapLogInfo(self.config.logLevel, @"%@", errorString);
                [self recordDeviceError:errorString];
            }
            self.deviceId = existingDeviceID;
            return;
        }
        
        if (self.config.useCustomCleverTapId) {
            [self forceUpdateCustomDeviceID:cleverTapID];
            return;
        }
        
        if (self.advertisingIdentitier) {
            [self forceUpdateDeviceID:[NSString stringWithFormat:@"-g%@", self.advertisingIdentitier]];
            return;
        }
        if (self.vendorIdentifier) {
            [self forceUpdateDeviceID:[NSString stringWithFormat:@"-v%@", self.vendorIdentifier]];
            return;
        }
        
        // Nothing? Generate one
        [self forceNewDeviceID];
        
    } @finally {
        [deviceIDLock unlock];
    }
}

- (NSString*)deviceIdStorageKey {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, kCLTAP_DEVICE_ID_TAG];
}

- (NSString*)fallbackDeviceIdStorageKey {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, kCLTAP_FALLBACK_DEVICE_ID_TAG];
}

- (NSString *)getDeviceID {
    NSString *deviceID;
    @try {
        [deviceIDLock lock];
        // Try to get the device ID from persistent storage
        // if default instance try legacy key first
        if (self.config.isDefaultInstance) {
            deviceID = [CTPreferences getStringForKey:kCLTAP_DEVICE_ID_TAG withResetValue:nil];
            if (deviceID
                && [[deviceID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
                deviceID = nil;
            }
            
            if (deviceID) {
                [self forceUpdateDeviceID:deviceID];
            }
        }
        
        if (!deviceID) {
            deviceID = [CTPreferences getStringForKey:[self deviceIdStorageKey] withResetValue:nil];
        }
        
        if (deviceID
            && [[deviceID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            deviceID = nil;
        }
        return deviceID;
    } @finally {
        [deviceIDLock unlock];
    }
}

- (void)forceNewDeviceID {
    [self forceUpdateDeviceID:[self generateGUID]];
}

- (NSString *)generateGUID {
    NSString *guid = [[NSUUID UUID] UUIDString];
    guid = [guid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    guid = [NSString stringWithFormat:@"-%@", guid];
    return [guid lowercaseString];
}

- (NSString *)generateFallbackGUID {
    NSString *guid = [[NSUUID UUID] UUIDString];
    guid = [guid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    guid = [NSString stringWithFormat:@"%@%@", kCLTAP_ERROR_PROFILE_PREFIX ,guid];
    return [guid lowercaseString];
}

- (void)forceUpdateDeviceID:(NSString *)newDeviceID {
    @try {
        [deviceIDLock lock];
        self.deviceId = newDeviceID;
        [CTPreferences putString:newDeviceID forKey:[self deviceIdStorageKey]];
    } @finally {
        [deviceIDLock unlock];
    }
}

- (NSString *)getStoredFallbackDeviceID {
    NSString *fallbackdeviceID;
    NSString *storageKey = [NSString stringWithFormat:@"%@:%@", self.config.accountId, kCLTAP_FALLBACK_DEVICE_ID_TAG];
    fallbackdeviceID = [CTPreferences getStringForKey:storageKey withResetValue:nil];
    if (fallbackdeviceID
        && [[fallbackdeviceID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        fallbackdeviceID = nil;
    }
    return fallbackdeviceID;
}
- (NSString*)findOrCreateFallbackDeviceID {
    NSString *fallbackDeviceID = [self getStoredFallbackDeviceID];
    if (!fallbackDeviceID) {
        fallbackDeviceID = [self generateFallbackGUID];
         [CTPreferences putString:fallbackDeviceID forKey:[self fallbackDeviceIdStorageKey]];
    }
    return fallbackDeviceID;
}

- (void)forceUpdateCustomDeviceID:(NSString *)cleverTapID {
    if ([CTValidator isValidCleverTapId:cleverTapID]) {
        [self forceUpdateDeviceID:[NSString stringWithFormat:@"-h%@", cleverTapID]];
        CleverTapLogInfo(self.config.logLevel, "%@: Updating CleverTap ID to custom CleverTap ID: %@", self, cleverTapID);
    } else {
        // clear the guid for current user
        [self forceRemoveDeviceID];
        if (!self.fallbackDeviceId) {
            self.fallbackDeviceId = [self findOrCreateFallbackDeviceID];
        }
        NSString *errorString = [NSString stringWithFormat:@"%@: Attempted to set invalid custom CleverTap ID: %@, falling back to default error CleverTap ID: %@", self, cleverTapID, self.fallbackDeviceId];
        CleverTapLogInfo(self.config.logLevel, @"%@", errorString);
        [self recordDeviceError:errorString];
    }
}

- (void)forceRemoveDeviceID {
    self.deviceId = nil;
    [CTPreferences removeObjectForKey:[self deviceIdStorageKey]];
}

- (void)recordDeviceError: (NSString*)errorString {
    CTValidationResult *error = [[CTValidationResult alloc] init];
    [error setErrorCode:514];
    [error setErrorDesc:[NSString stringWithFormat:@"%@", errorString]];
    @synchronized (_validationErrors) {
        [_validationErrors addObject:error];
    }
}

- (void)setValidationErrors:(NSMutableArray *)validationErrors {
    _validationErrors = validationErrors;
}

- (NSMutableArray*)validationErrors {
    @synchronized (_validationErrors) {
        NSMutableArray *errors = [NSMutableArray arrayWithArray:_validationErrors];
        [_validationErrors removeAllObjects];
        return errors;
    }
}

- (NSString*)sdkVersion {
    if (!_sdkVersion) {
        _sdkVersion = WR_SDK_REVISION;
    }
    return _sdkVersion;
}

- (NSString*)appVersion {
    if (!_appVersion) {
        _appVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    }
    return _appVersion;
}

- (NSString*)bundleId {
    if (!_bundleId) {
        _bundleId = [NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"];
    }
    return _bundleId;
}

- (NSString*)appBuild {
    if (!_build) {
        _build = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    }
    return _build;
}


- (NSString*)osName {
#if TARGET_OS_TV
     return @"tvOS";
#else
     return @"iOS";
#endif
}

- (NSString*)osVersion {
    if (!_osVersion) {
        _osVersion = [[UIDevice currentDevice] systemVersion];
    }
    return _osVersion;
}

- (NSString*)manufacturer {
    return @"Apple";
}

- (NSString*)model {
    if (!_model) {
        _model = [[self class] getPlatformName];
    }
    return _model;
}

- (NSString*)deviceWidth {
    if (!_deviceWidth) {
        float scale = [[UIScreen mainScreen] scale];
        float ppi = scale * ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 132 : 163);
        float width = ([[UIScreen mainScreen] bounds].size.width * scale);
        float rWidth = width / ppi;
        _deviceWidth = [NSString stringWithFormat:@"%.2f", [CTUtils toTwoPlaces:rWidth]];
    }
    return _deviceWidth;
}

- (NSString*)deviceHeight {
    if (!_deviceHeight) {
        float scale = [[UIScreen mainScreen] scale];
        float ppi = scale * ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 132 : 163);
        float height = ([[UIScreen mainScreen] bounds].size.height * scale);
        float rHeight = height / ppi;
        _deviceHeight = [NSString stringWithFormat:@"%.2f", [CTUtils toTwoPlaces:rHeight]];
    }
    return _deviceHeight;
}

- (NSString*)deviceName {
    if (!_deviceName) {
        _deviceName = [UIDevice currentDevice].name;
    }
    return _deviceName;
}

- (NSString*)carrier {
#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
    if (!_carrier) {
        Class CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
        if ([self.networkInfo isKindOfClass:CTTelephonyNetworkInfo]) {
            SEL subscriberCellularProvider = NSSelectorFromString(@"subscriberCellularProvider");
            SEL carrierName = NSSelectorFromString(@"carrierName");
            id carrier = nil;
            id (*imp1)(id, SEL) = (id (*)(id, SEL))[_networkInfo methodForSelector:subscriberCellularProvider];
            if (imp1) {
                carrier = imp1(_networkInfo, subscriberCellularProvider);
            }
            NSString* (*imp2)(id, SEL) = (NSString* (*)(id, SEL))[carrier methodForSelector:carrierName];
            if (imp2) {
                _carrier = imp2(carrier, carrierName);
            }
        }
        if (!_carrier) {
            _carrier = @"";
        }
    }
#endif
    return _carrier;
}

- (NSString*)countryCode {
#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
    if (!_countryCode) {
        Class CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
        if ([self.networkInfo isKindOfClass:CTTelephonyNetworkInfo]) {
            SEL subscriberCellularProvider = NSSelectorFromString(@"subscriberCellularProvider");
            SEL isoCountryCode = NSSelectorFromString(@"isoCountryCode");
            id (*imp1)(id, SEL) = (id (*)(id, SEL))[_networkInfo methodForSelector:subscriberCellularProvider];
            id carrier = nil;
            if (imp1) {
                carrier = imp1(_networkInfo, subscriberCellularProvider);
            }
            NSString* (*imp2)(id, SEL) = (NSString* (*)(id, SEL))[carrier methodForSelector:isoCountryCode];
            if (imp2) {
                _countryCode = imp2(carrier, isoCountryCode);
            }
        }
        if (!_countryCode) {
            _countryCode = @"";
        }
    }
#endif
    return _countryCode;
}


- (NSString*)timeZone {
    if (!_timeZone) {
        _timeZone =[NSTimeZone localTimeZone].name;
    }
    return _timeZone;
}

- (NSString*)radio {
#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
    if (!_radio) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_updateRadio)
                                                     name:CTRadioAccessTechnologyDidChangeNotification
                                                   object:nil];
        [self _updateRadio];
    }
#endif
    return _radio;
}

- (BOOL)wifi {
    return _wifi;
}

- (BOOL)advertisingTrackingEnabled {
    return advertisingTrackingEnabled;
}

- (void)_updateRadio {
#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
    Class CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
    if ([self.networkInfo isKindOfClass:CTTelephonyNetworkInfo]) {
        SEL currentRadioAccessTechnology = NSSelectorFromString(@"currentRadioAccessTechnology");
        NSString* (*imp1)(id, SEL) = (NSString* (*)(id, SEL))[_networkInfo methodForSelector:currentRadioAccessTechnology];
        if (imp1) {
            NSString *radio = imp1(self.networkInfo, currentRadioAccessTechnology);
            if (radio && [radio hasPrefix:@"CTRadioAccessTechnology"]) {
                _radio = [radio substringFromIndex:23];
            }
        }
    }
    if (!_radio) {
        _radio = @"";
    }
    CleverTapLogStaticInternal(@"Updated radio to %@", _radio);
#endif
}

- (NSObject*)networkInfo {
#if !CLEVERTAP_NO_REACHABILITY_SUPPORT
    if (!_networkInfo) {
        Class CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
        SEL subscriberCellularProvider = NSSelectorFromString(@"subscriberCellularProvider");
        SEL carrierName = NSSelectorFromString(@"carrierName");
        if (CTTelephonyNetworkInfo && subscriberCellularProvider && carrierName) {
            _networkInfo = [[NSClassFromString(@"CTTelephonyNetworkInfo") alloc] init];
        } else {
            _networkInfo = [NSObject new];
        }
    }
#endif
    return _networkInfo;
}

@end
