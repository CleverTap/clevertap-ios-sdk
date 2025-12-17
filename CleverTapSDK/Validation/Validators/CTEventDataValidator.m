//
//  CTEventDataValidator.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import "CTEventDataValidator.h"
#import "CTValidationResult.h"
#import "CTConstants.h"

@interface CTEventDataValidator ()
@property (nonatomic, strong) CTValidationConfig *config;
@property (nonatomic, assign) NSInteger currentDepth;
@property (nonatomic, assign) NSInteger maxDepthReached;
@property (nonatomic, strong) NSMutableArray<CTValidationResult *> *warnings;
@end

@implementation CTEventDataValidator

- (instancetype)initWithConfig:(CTValidationConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
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
        CTValidationResult *warning = [CTValidationResult warningWithCode:541
                                                                  message:[NSString stringWithFormat:@"Max nesting depth limit: %ld exceeded at depth: %ld",
                                                                          (long)[self.config.maxDepth integerValue], (long)depth]
                                                                     data:nil];
        [self.warnings addObject:warning];
        // Continue processing but log the warning
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
            [self.warnings addObject:[CTValidationResult warningWithCode:512
                                                                 message:[NSString stringWithFormat:@"Found empty key in dictionary"]
                                                                    data:nil]];
            continue;
        }
        
        id value = dict[key];
        
        // Handle null - log warning and continue
        if (!value || [value isKindOfClass:[NSNull class]]) {
            [self.warnings addObject:[CTValidationResult warningWithCode:545
                                                                 message:[NSString stringWithFormat:@"Null value for key '%@'", cleanedKey]
                                                                    data:nil]];
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
                [self.warnings addObject:[CTValidationResult warningWithCode:546
                                                                     message:[NSString stringWithFormat:@"Empty array for key '%@' was removed", cleanedKey]
                                                                        data:nil]];
                continue;
            }
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            if ([(NSDictionary *)value count] == 0) {
                [self.warnings addObject:[CTValidationResult warningWithCode:547
                                                                     message:[NSString stringWithFormat:@"Empty dictionary for key '%@' was removed", cleanedKey]
                                                                        data:nil]];
                continue;
            }
        }
        
        // Drop restricted multi-value fields at 0th level if value is object or array
        if (depth == 0 &&
            self.config.restrictedMultiValueFields &&
            [self.config.restrictedMultiValueFields containsObject:cleanedKey]) {
            
            BOOL isObjectOrArray = [value isKindOfClass:[NSDictionary class]] ||
            [value isKindOfClass:[NSArray class]];
            
            if (isObjectOrArray) {
                [self.warnings addObject:[CTValidationResult warningWithCode:523
                                                                     message:[NSString stringWithFormat:@"%@ is a restricted key. It can't have an object/array as the value", value]
                                                                        data:nil]];
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
        [self.warnings addObject:[CTValidationResult warningWithCode:543
                                                             message:[NSString stringWithFormat:@"Object key count %ld exceeds limit %ld at depth %ld",
                                                                     (long)objectKeyCount, (long)objectKeyLimit, (long)depth]
                                                                data:nil]];
    }
    
    if (arrayKeyCount > arrayKeyLimit) {
        [self.warnings addObject:[CTValidationResult warningWithCode:542
                                                             message:[NSString stringWithFormat:@"Array key count %ld exceeds limit %ld at depth %ld",
                                                                     (long)arrayKeyCount, (long)arrayKeyLimit, (long)depth]
                                                                data:nil]];
    }
    
    return cleaned;
}

#pragma mark - Array Cleaning

- (NSArray *)cleanArray:(NSArray *)array forKey:(NSString *)key depth:(NSInteger)depth {
    NSInteger maxLength = self.config.maxArrayLength ? [self.config.maxArrayLength integerValue] : 100;
    
    if (maxLength > 0 && array.count > maxLength) {
        [self.warnings addObject:[CTValidationResult warningWithCode:544
                                                             message:[NSString stringWithFormat:@"Array length %lu exceeds limit %ld for key '%@'",
                                                                     (unsigned long)array.count, (long)maxLength, key]
                                                                data:nil]];
        // Continue processing but truncate
    }
    
    NSMutableArray *cleaned = [NSMutableArray array];
    NSInteger processedCount = 0;
    
    for (id item in array) {
        if (maxLength > 0 && processedCount >= maxLength) {
            break; // Stop processing after limit
        }
        
        if (!item || [item isKindOfClass:[NSNull class]]) {
            [self.warnings addObject:[CTValidationResult warningWithCode:545
                                                                 message:[NSString stringWithFormat:@"Null value in array for key '%@'", key]
                                                                    data:nil]];
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
        [self.warnings addObject:[CTValidationResult warningWithCode:512
                                                             message:[NSString stringWithFormat:@"Non-primitive value for key '%@'", key]
                                                                data:nil]];
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
            [self.warnings addObject:[CTValidationResult warningWithCode:520
                                                                 message:[NSString stringWithFormat:@"Key '%@' contains invalid characters", key]
                                                                    data:nil]];
        }
    }
    
    // Truncate if needed
    NSInteger limit = self.config.maxKeyLength ? [self.config.maxKeyLength integerValue] : 120;
    
    if (cleaned.length > limit) {
        cleaned = [cleaned substringToIndex:limit];
        [self.warnings addObject:[CTValidationResult warningWithCode:520
                                                             message:[NSString stringWithFormat:@"Key '%@...' exceeds %ld characters",
                                                                     [cleaned substringToIndex:MIN(20, cleaned.length)], (long)limit]
                                                                data:nil]];
    }
    
    return [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)cleanStringValue:(NSString *)value forKey:(NSString *)key {
    NSString *cleaned = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (cleaned.length == 0) {
        [self.warnings addObject:[CTValidationResult warningWithCode:545
                                                             message:[NSString stringWithFormat:@"Empty value for key '%@' was removed", key]
                                                                data:nil]];
        return nil;
    }
    
    // Remove invalid characters using NSCharacterSet
    if (self.config.valueCharsNotAllowed) {
        NSString *filtered = [[cleaned componentsSeparatedByCharactersInSet:self.config.valueCharsNotAllowed]
                             componentsJoinedByString:@""];
        
        if (![filtered isEqualToString:cleaned]) {
            cleaned = filtered;
            [self.warnings addObject:[CTValidationResult warningWithCode:521
                                                                 message:[NSString stringWithFormat:@"Value for key '%@' contains invalid characters", key]
                                                                    data:nil]];
        }
    }
    
    // Truncate if needed
    NSInteger limit = self.config.maxValueLength ? [self.config.maxValueLength integerValue] : 1024;
    
    if (cleaned.length > limit) {
        cleaned = [cleaned substringToIndex:limit];
        [self.warnings addObject:[CTValidationResult warningWithCode:521
                                                             message:[NSString stringWithFormat:@"Value for key '%@' exceeds %ld characters", key, (long)limit]
                                                                data:nil]];
    }
    
    cleaned = [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return cleaned.length > 0 ? cleaned : nil;
}

#pragma mark - Phone Validation

- (BOOL)isValidPhone:(id)value {
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    NSString *phone = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // If no country code provider, phone must start with +
    NSString *countryCode = self.config.deviceCountryCodeProvider ? self.config.deviceCountryCodeProvider() : nil;
    
    if (!countryCode || countryCode.length == 0) {
        return [phone hasPrefix:@"+"];
    }
    
    return YES;
}


- (void)validatePhoneNumber:(NSString *)key value:(id)value {
    // Check if value is a string
    if (![value isKindOfClass:[NSString class]]) {
        [self.warnings addObject:[CTValidationResult warningWithCode:512
                                                             message:[NSString stringWithFormat:@"Invalid phone number for key '%@'", key]
                                                                data:nil]];
        return;
    }
    
    NSString *phoneValue = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // If no country code available, require phone to start with '+'
    NSString *countryCode = self.config.deviceCountryCodeProvider ? self.config.deviceCountryCodeProvider() : nil;
    
    if (!countryCode || countryCode.length == 0) {
        if (![phoneValue hasPrefix:@"+"]) {
            [self.warnings addObject:[CTValidationResult warningWithCode:512
                                                                 message:[NSString stringWithFormat:@"Device country code not available and profile phone: %@ does not appear to start with country code", value]
                                                                    data:nil]];
        }
    }
    CleverTapLogStaticInternal(@"Profile phone number is: %@, device country code is: %@", value, countryCode);
}

@end
