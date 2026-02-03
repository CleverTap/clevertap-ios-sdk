//
//  CTDataValidator.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import "CTDataValidator.h"
#import "CTValidationResult.h"
#import "CTConstants.h"

@interface CTDataValidator ()
@property (nonatomic, assign) NSInteger currentDepth;
@property (nonatomic, assign) NSInteger maxDepthReached;
@property (nonatomic, strong) NSMutableArray<CTValidationResult *> *warnings;
@end

@implementation CTDataValidator

- (instancetype)initWithConfig:(CTValidationConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

- (CTValidationResult *)validate:(NSString *)value forKey:(NSString *)key {
    NSString *cleaned = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *warnings = [NSMutableArray array];
    if (cleaned.length == 0) {
        [warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorEmptyValueRemoved message:[NSString stringWithFormat:@"Empty value for key '%@' was removed", key] data:nil]];
        return nil;
    }
    // Remove invalid characters using NSCharacterSet
    if (self.config.valueCharsNotAllowed) {
        NSString *filtered = [[cleaned componentsSeparatedByCharactersInSet:self.config.valueCharsNotAllowed] componentsJoinedByString:@""];
        
        if (![filtered isEqualToString:cleaned]) {
            cleaned = filtered;
            [warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorInvalidKey message:[NSString stringWithFormat:@"Value '%@' for key '%@' contains invalid characters. Cleaned to '%@'", value, key, cleaned] data:nil]];
        }
    }
    // Truncate if needed
    NSInteger limit = self.config.maxValueLength ? [self.config.maxValueLength integerValue] : 1024;
    
    if (cleaned.length > limit) {
        cleaned = [cleaned substringToIndex:limit];
        [warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorValueTooLong message:[NSString stringWithFormat:@"Value '%@' for key '%@' exceeds the limit of %li characters. Trimmed to '%@'", value, key, limit, cleaned] data:nil]];
    }
    
    cleaned = [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    cleaned = cleaned.length > 0 ? cleaned : nil;
    if (warnings.count > 0 ) {
        return [CTValidationResult warningWithSubResults:warnings data:cleaned];
    }
    return [CTValidationResult successWithData:cleaned];
}

- (CTValidationResult *)cleanArray:(NSArray *)array forKey:(NSString *)key {
    NSMutableArray *warnings = [NSMutableArray array];
    NSInteger maxLength = self.config.maxArrayLength ? [self.config.maxArrayLength integerValue] : 100;
    
    if (maxLength > 0 && array.count > maxLength) {
        [warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorArrayLengthExceeded message:[NSString stringWithFormat:@"Event data exceeded maximum array length. Length: %li, Limit: %li, Key: %@", array.count, maxLength, key] data:nil]];
        // Continue processing but truncate
    }
    NSMutableArray *cleaned = [NSMutableArray array];
    NSInteger processedCount = 0;
    
    for (id item in array) {
        if (maxLength > 0 && processedCount >= maxLength) {
            break; // Stop processing after limit
        }
        if (!item || [item isKindOfClass:[NSNull class]]) {
            [warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorNullValueRemoved message:[NSString stringWithFormat:@"Null value for key '%@' was removed", key] data:nil]];
            continue; // Skip null but continue
        }
        id cleanedItem = [self cleanStringValue:item forKey:key];
        if (cleanedItem) {
            [cleaned addObject:cleanedItem];
            processedCount++;
        }
    }
    if (warnings.count > 0) {
        return [CTValidationResult warningWithSubResults:warnings data:cleaned];
    }
    return [CTValidationResult successWithData:cleaned];
}

- (CTValidationResult *)validateEventData:(NSDictionary *)eventData {
    self.warnings = [NSMutableArray array];
    self.currentDepth = 0;
    self.maxDepthReached = 0;
    if (!eventData) {
        return [CTValidationResult successWithData:@{}];
    }
    NSDictionary *cleaned = [self cleanDictionary:eventData depth:0];
    if (self.warnings.count > 0) {
        return [CTValidationResult warningWithSubResults:self.warnings data:cleaned];
    }
    return [CTValidationResult successWithData:cleaned];
}

#pragma mark - Dictionary Cleaning

- (NSDictionary *)cleanDictionary:(NSDictionary *)dict depth:(NSInteger)depth {
    // Track depth
    self.maxDepthReached = MAX(self.maxDepthReached, depth);
    if (self.config.maxDepth && depth > [self.config.maxDepth integerValue]) {
        CTValidationResult *warning = [CTValidationResult warningWithCode: CTValidationErrorObjectKeyLimitExceeded message:[NSString stringWithFormat:@"Event data exceeded maximum object count. Count: %ld, Limit: %li", (long)[self.config.maxDepth integerValue], (long)depth] data:nil];
        [self.warnings addObject:warning];
    }
    NSMutableDictionary *cleaned = [NSMutableDictionary dictionary];
    NSInteger objectKeyCount = 0;
    NSInteger arrayKeyCount = 0;
    // Limits
    NSInteger objectKeyLimit = self.config.maxObjectKeyPerLevelCount ?
    [self.config.maxObjectKeyPerLevelCount integerValue] : 5;
    NSInteger arrayKeyLimit = self.config.maxArrayKeyPerLevelCount ?
    [self.config.maxArrayKeyPerLevelCount integerValue] : 5;
    
    for (NSString *key in dict) {
        // Clean key
        NSString *cleanedKey = [self cleanKey:key];
        if (!cleanedKey || cleanedKey.length == 0) {
            [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorEmptyValueRemoved message:[NSString stringWithFormat:@"Empty value for key '%@' was removed, depth: %li", key, depth] data:nil]];
            continue;
        }
        id value = dict[key];

        // Drop restricted multi-value fields at 0th level if value is object or array
        if (depth == 0 && self.config.restrictedMultiValueFields != nil &&
            [self.config.restrictedMultiValueFields containsObject:[cleanedKey lowercaseString]]) {
            BOOL isObjectOrArray = [value isKindOfClass:[NSDictionary class]] ||
                                  [value isKindOfClass:[NSArray class]];
            if (isObjectOrArray) {
                [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorRestrictedKey message:[NSString stringWithFormat:@"'%@'is a restricted key for multi-value properties. Dropped, Depth: %li", key, depth] data:nil]];
                continue;
            }
        }
        // Handle null - log warning and continue
        if (!value || [value isKindOfClass:[NSNull class]]) {
            [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorNullValueRemoved message:[NSString stringWithFormat:@"Null value for key '%@' was removed, depth: %li", key, depth] data:nil]];
            continue;
        }
        // Count arrays and dictionaries FIRST (including empty ones)
        if ([value isKindOfClass:[NSArray class]]) {
            arrayKeyCount++;
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            objectKeyCount++;
        }
        // THEN check for empty collections - log and skip
        if ([value isKindOfClass:[NSArray class]]) {
            if ([(NSArray *)value count] == 0) {
                [self.warnings addObject:[CTValidationResult warningWithCode: CTValidationErrorEmptyValueRemoved message:[NSString stringWithFormat:@"Empty array for key '%@' was removed, depth: %li", cleanedKey, depth] data:nil]];
                continue;
            }
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            if ([(NSDictionary *)value count] == 0) {
                [self.warnings addObject:[CTValidationResult warningWithCode: CTValidationErrorEmptyValueRemoved message:[NSString stringWithFormat:@"Empty dictionary for key '%@' was removed, depth: %li", cleanedKey, depth] data:nil]];
                continue;
            }
        }
        // Drop restricted multi-value fields at 0th level if value is object or array
        if (depth == 0 && self.config.restrictedMultiValueFields && [self.config.restrictedMultiValueFields containsObject:cleanedKey]) {
            
            BOOL isObjectOrArray = [value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSArray class]];
            
            if (isObjectOrArray) {
                [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorRestrictedKey message:[NSString stringWithFormat:@"%@ is a restricted key for multi-value properties. Dropped, depth: %li", value, depth] data:nil]];
                continue;
            }
        }
        // Special phone validation
        if ([cleanedKey.lowercaseString isEqualToString:@"phone"]) {
            // make sure Phone is a string and debug check for country code and phone format, but always send
#if !defined(CLEVERTAP_TVOS)
            [self validatePhoneNumber:cleanedKey value:value];
#endif
        }
        // Clean value recursively
        id cleanedValue = [self cleanValue:value forKey:cleanedKey depth:depth + 1];
        if (cleanedValue) {
            cleaned[cleanedKey] = cleanedValue;
        }
    }
    // Check limits ONCE after counting all items (including empties)
    if (objectKeyCount > objectKeyLimit) {
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorKVPairCountExceeded message:[NSString stringWithFormat:@"Event data exceeded maximum key-value pair count. Count: %li, Limit: %li, Depth: %li", objectKeyCount, objectKeyLimit, depth] data:nil]];
    }
    if (arrayKeyCount > arrayKeyLimit) {
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorArrayLengthExceeded message:[NSString stringWithFormat:@"Event data exceeded maximum array length. Length: %li, Limit: %li Depth: %li", arrayKeyCount, arrayKeyLimit, depth] data:nil]];
    }
    return cleaned;
}

#pragma mark - Array Cleaning

- (NSArray *)cleanArray:(NSArray *)array forKey:(NSString *)key depth:(NSInteger)depth {
    NSInteger maxLength = self.config.maxArrayLength ? [self.config.maxArrayLength integerValue] : 100;
    if (maxLength > 0 && array.count > maxLength) {
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorArrayLengthExceeded message:[NSString stringWithFormat:@"Event data exceeded maximum array length. Length: %li, Limit: %li, Key: %@, Depth: %li", array.count, maxLength, key, depth] data:nil]];
        // Continue processing but truncate
    }
    NSMutableArray *cleaned = [NSMutableArray array];
    NSInteger processedCount = 0;
    
    for (id item in array) {
        if (maxLength > 0 && processedCount >= maxLength) {
            break; // Stop processing after limit
        }
        if (!item || [item isKindOfClass:[NSNull class]]) {
            [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorNullValueRemoved message:[NSString stringWithFormat:@"Null value for key '%@' was removed, Depth: %li", key, depth] data:nil]];
            continue; // Skip null but continue
        }
        id cleanedItem = [self cleanValue:item forKey:key depth:depth];
        if (cleanedItem) {
            [cleaned addObject:cleanedItem];
            processedCount++;
        }
    }
    return cleaned.count > 0 ? cleaned : nil;
}

#pragma mark - Value Cleaning

- (id)cleanValue:(id)value forKey:(NSString *)key depth:(NSInteger)depth {
    if (!value || [value isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [self cleanStringValue:(NSString *)value forKey:key];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        return [self cleanDictionary:(NSDictionary *)value depth:depth];
    } else if ([value isKindOfClass:[NSArray class]]) {
        return [self cleanArray:(NSArray *)value forKey:key depth:depth];
    } else if ([value isKindOfClass:[NSDate class]]) {
        NSTimeInterval timestamp = [(NSDate *)value timeIntervalSince1970];
        return [NSString stringWithFormat:@"$D_%ld", (long)timestamp];
    } else {
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorNonPrimitiveValue message:[NSString stringWithFormat:@"Property value for key '%@' wasn't a primitive '%@', Depth: %li", key, value, depth] data:nil]];
        return nil;
    }
}

#pragma mark - String and Key Cleaning

- (NSString *)cleanKey:(NSString *)key {
    NSString *cleaned = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // Remove invalid characters using NSCharacterSet
    if (self.config.keyCharsNotAllowed) {
        NSString *filtered = [[cleaned componentsSeparatedByCharactersInSet:self.config.keyCharsNotAllowed]
                             componentsJoinedByString:@""];
        
        if (![filtered isEqualToString:cleaned]) {
            cleaned = filtered;
            [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorInvalidKey  message:[NSString stringWithFormat:@"Key '%@' contains invalid characters", key] data:nil]];
        }
    }
    // Truncate if needed
    NSInteger limit = self.config.maxKeyLength ? [self.config.maxKeyLength integerValue] : 120;
    if (cleaned.length > limit) {
        cleaned = [cleaned substringToIndex:limit];
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorKeyTooLong message:[NSString stringWithFormat:@"Key '%@' exceeds %li characters. Trimmed to '%@", key, limit, cleaned] data:nil]];
    }
    return [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)cleanStringValue:(NSString *)value forKey:(NSString *)key {
    NSString *cleaned = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (cleaned.length == 0) {
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorEmptyValueRemoved message:[NSString stringWithFormat:@"Empty value for key '%@' was removed", key] data:nil]];
        return nil;
    }
    // Remove invalid characters using NSCharacterSet
    if (self.config.valueCharsNotAllowed) {
        NSString *filtered = [[cleaned componentsSeparatedByCharactersInSet:self.config.valueCharsNotAllowed]
                             componentsJoinedByString:@""];
        
        if (![filtered isEqualToString:cleaned]) {
            cleaned = filtered;
            [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorInvalidValue message:[NSString stringWithFormat:@"Value for key '%@' contains invalid characters", key] data:nil]];
        }
    }
    // Truncate if needed
    NSInteger limit = self.config.maxValueLength ? [self.config.maxValueLength integerValue] : 1024;
    if (cleaned.length > limit) {
        cleaned = [cleaned substringToIndex:limit];
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorValueTooLong message:[NSString stringWithFormat:@"Value for key '%@' exceeds %ld characters", key, (long)limit] data:nil]];
    }
    cleaned = [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return cleaned.length > 0 ? cleaned : nil;
}

#pragma mark - Phone Validation

- (void)validatePhoneNumber:(NSString *)key value:(id)value {
    // Check if value is a string
    if (![value isKindOfClass:[NSString class]]) {
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorInvalidPhone message:[NSString stringWithFormat:@"Invalid phone number for key '%@'", key] data:nil]];
        return;
    }
    NSString *phoneValue = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // If no country code available, require phone to start with '+'
    NSString *countryCode = self.config.deviceCountryCode ? self.config.deviceCountryCode : nil;
    
    if (!countryCode || countryCode.length == 0) {
        if (![phoneValue hasPrefix:@"+"]) {
            [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorInvalidCountryCode message:[NSString stringWithFormat:@"Device country code not available and profile phone: %@ does not appear to start with country code", value] data:nil]];
        }
    }
    CleverTapLogStaticInternal(@"Profile phone number is: %@, device country code is: %@", value, countryCode);
}
@end
