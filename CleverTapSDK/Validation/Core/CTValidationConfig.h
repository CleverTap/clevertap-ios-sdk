//
//  CTValidationConfig.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#pragma mark - Error Codes
typedef NS_ENUM(int, CTValidationErrorCode) {
    // Event Errors (510)
    CTValidationErrorEventNameNull = 510,
    CTValidationErrorEventNameTooLong = 510,
    CTValidationErrorInvalidCharacters = 510,

    // Profile Key Errors (512)
    CTValidationErrorInvalidCountryCode = 512,
    CTValidationErrorInvalidPhone = 512,
    CTValidationErrorEmptyKey = 512,
    CTValidationErrorEmptyKeyAbort = 512, //not used
    CTValidationErrorNonPrimitiveValue = 512,
    
    // Event Restriction Errors (513)
    CTValidationErrorDropEvent = 513,
    CTValidationErrorRestrictedEventName = 513,
    CTValidationErrorDiscardedEventName = 513,
    
    // Custom CleverTap ID Error (514)
    CTValidationErrorCustomID = 514,
    
    // Key Errors (520)
    CTValidationErrorInvalidKey = 520,
    CTValidationErrorKeyTooLong = 520,
    
    // Value Errors (521)
    CTValidationErrorValueTooLong = 521,
    CTValidationErrorInvalidValue = 521,
    
    // Multi-value key Errors (521)
    CTValidationErrorRestrictedKey = 523,
    
    // Depth & Structure Errors (540-544)
    CTValidationErrorDepthLimitExceeded = 540,
    CTValidationErrorArrayKeyCountLimitExceeded = 541,
    CTValidationErrorObjectKeyLimitExceeded = 542,
    CTValidationErrorArrayLengthExceeded = 543,
    CTValidationErrorKVPairCountExceeded = 544,

    // Empty/Null Value Errors (545)
    CTValidationErrorNullValueRemoved = 545,
    CTValidationErrorEmptyValueRemoved = 545,
};

/**
 * Configuration for validation rules.
 * Create an instance and set properties directly, or use defaultConfig for common CleverTap limits.
 */
@interface CTValidationConfig : NSObject

// Size validations
@property (nonatomic, strong, nullable) NSNumber *maxKeyLength;
@property (nonatomic, strong, nullable) NSNumber *maxValueLength;
@property (nonatomic, strong, nullable) NSNumber *maxDepth;

// Count validations
@property (nonatomic, strong, nullable) NSNumber *maxArrayKeyPerLevelCount;
@property (nonatomic, strong, nullable) NSNumber *maxObjectKeyPerLevelCount;
@property (nonatomic, strong, nullable) NSNumber *maxArrayLength;
@property (nonatomic, strong, nullable) NSNumber *maxKVPairCount;

// Character validations - using NSCharacterSet for efficient filtering
@property (nonatomic, strong, nullable) NSCharacterSet *keyCharsNotAllowed;
@property (nonatomic, strong, nullable) NSCharacterSet *valueCharsNotAllowed;

// Event name validations
@property (nonatomic, strong, nullable) NSNumber *maxEventNameLength;
@property (nonatomic, strong, nullable) NSCharacterSet *eventNameCharsNotAllowed;

// Restricted names - using NSSet for lookups
@property (nonatomic, strong, nullable) NSSet<NSString *> *restrictedEventNames;
@property (nonatomic, strong, nullable) NSSet<NSString *> *restrictedMultiValueFields;

/**
 * Mutable set of discarded event names from Dashboard.
 * Can be updated at runtime to sync with Dashboard settings.
 */
@property (nonatomic, strong, nullable) NSSet<NSString *> *discardedEventNames;

/**
 * Provider block for device country code.
 * This block will be called whenever the country code is needed.
 */
@property (nonatomic, copy, nullable) NSString* deviceCountryCode;

/**
 * Default restricted event names set.
 */
+ (NSSet<NSString *> *)defaultRestrictedEventNames;

/**
 * Default restricted multi-value fields set.
 */
+ (NSSet<NSString *> *)defaultRestrictedMultiValueFields;

/**
 * Creates a default validation configuration with common CleverTap limits.
 * @param countryCode Optional provider for device country code
 * @return Default ValidationConfig instance
 */
+ (instancetype)defaultConfigWithCountryCode:(nullable NSString*)countryCode;

+ (BOOL)isRestrictedEventName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
