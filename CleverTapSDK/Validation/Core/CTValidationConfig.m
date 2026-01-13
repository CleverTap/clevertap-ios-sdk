//
//  CTValidationConfig.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//
#import "CTValidationConfig.h"
#import "CTConstants.h"
#import "CTUtils.h"
#import "CTValidationResult.h"

static const int kMaxKeyChars = 120;
static const int kMaxValueChars = 1024;
static const int kMaxNestingDepth = 3;
static const int kMaxPropertiesPerLevel = 5;
static const int kMaxPropertiesPerObject = 100;

@implementation CTValidationConfig

+ (NSSet<NSString *> *)defaultRestrictedEventNames {
    static NSSet<NSString *> *defaultNames = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultNames = [NSSet setWithArray:@[
            @"Stayed",
            @"Notification Clicked",
            @"Notification Viewed",
            @"UTM Visited",
            @"Notification Sent",
            @"App Launched",
            @"wzrk_d",
            @"App Uninstalled",
            @"Notification Bounced",
            CLTAP_GEOFENCE_ENTERED_EVENT_NAME,
            CLTAP_GEOFENCE_EXITED_EVENT_NAME
        ]];
    });
    return defaultNames;
}

+ (NSSet<NSString *> *)defaultRestrictedMultiValueFields {
    static NSSet<NSString *> *defaultFields = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultFields = [NSSet setWithArray:@[
            @"Name", @"Email", @"Education", @"Married", @"DOB",
            @"Gender", @"Phone", @"Age", @"FBID", @"GPID", @"Birthday"
        ]];
    });
    return defaultFields;
}

+ (instancetype)defaultConfig {
    return [self defaultConfigWithCountryCode:nil];
}

+ (instancetype)defaultConfigWithCountryCode:(nullable NSString*)countryCode {
    CTValidationConfig *config = [[CTValidationConfig alloc] init];
    // Size validations
    config.maxKeyLength = @(kMaxKeyChars);
    config.maxValueLength = @(kMaxValueChars);
    config.maxDepth = @(kMaxNestingDepth);
    // Count validations
    config.maxArrayKeyPerLevelCount = @(kMaxPropertiesPerLevel);
    config.maxObjectKeyPerLevelCount = @(kMaxPropertiesPerLevel);
    config.maxArrayLength = @(kMaxPropertiesPerObject);
    config.maxKVPairCount = @(kMaxPropertiesPerObject);
    // Character validations for keys - create NSCharacterSet from string
    NSString *keyCharsNotAllowedString = @":$'\"\\";
    config.keyCharsNotAllowed = [NSCharacterSet characterSetWithCharactersInString:keyCharsNotAllowedString];
    // Character validations for values - create NSCharacterSet from string
    NSString *valueCharsNotAllowedString = @"'\"\\";
    config.valueCharsNotAllowed = [NSCharacterSet characterSetWithCharactersInString:valueCharsNotAllowedString];
        // Event name validations
    config.maxEventNameLength = @(kMaxValueChars);
    NSString *eventNameCharsNotAllowedString = @".:$'\"\\";
    config.eventNameCharsNotAllowed = [NSCharacterSet characterSetWithCharactersInString:eventNameCharsNotAllowedString];
    // Restricted names
    config.restrictedEventNames = [CTValidationConfig defaultRestrictedEventNames];
    config.restrictedMultiValueFields = [CTValidationConfig defaultRestrictedMultiValueFields];
    // Country code provider
    config.deviceCountryCode = countryCode;
    return config;
}

+ (BOOL)isRestrictedEventName:(NSString *)name {
    if (name == nil) {
        return NO;
    }
    NSSet<NSString *> *restrictedNames = [CTValidationConfig defaultRestrictedEventNames];
    for (NSString *restrictedName in restrictedNames) {
        if ([CTUtils areEqualNormalizedName:name andName:restrictedName]) {
            CleverTapLogStaticDebug(@"Restricted event name: %@", restrictedName);
            return YES;
        }
    }
    return NO;
}
@end
