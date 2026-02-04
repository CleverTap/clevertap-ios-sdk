//
//  CTPropertyKeyValidator.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import "CTPropertyKeyValidator.h"
#import "CTValidationResult.h"

@interface CTPropertyKeyValidator ()
@end

@implementation CTPropertyKeyValidator

- (instancetype)initWithConfig:(CTValidationConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

/**
 * Cleans the object key.
 *
 * @param key Name of the object key
 * @return The ValidationResult object containing the object,
 *         and the error code(if any)
 */
- (CTValidationResult *)validateKey:(NSString *)key {
    NSMutableArray<CTValidationResult *> *warnings = [NSMutableArray array];
    // Check for null/empty
    if (!key || key.length == 0) {
        CTValidationResult *warning = [CTValidationResult warningWithCode:CTValidationErrorEmptyKey message:@"Key is null or empty" data:nil];
        return warning;
    }
    // Normalize key
    NSString *cleaned = [self normalizeKey:key warnings:warnings];
    // Check if became empty after normalization
    if (!cleaned || cleaned.length == 0) {
        return [CTValidationResult dropWithCode:CTValidationErrorEmptyKey message:@"Key became empty after normalization" reason:CTDropReasonEmptyKey];
    }
    // Return result based on warnings
    if (warnings.count > 0) {
        return [CTValidationResult warningWithSubResults:warnings data:cleaned];
    }
    return [CTValidationResult successWithData:cleaned];
}

- (CTValidationResult *)validateMultiValueKey:(NSString *)key {
    // First perform base validation
    CTValidationResult *result = [self validateKey:key];
    if (result.shouldDrop) {
        return result;
    }
    NSString *cleanedKey = (NSString *)result.cleanedData;
    // Check multi-value restrictions
    if ([self isKeyRestrictedForMultiValue:cleanedKey]) {
        NSString *message = [NSString stringWithFormat:@"'%@' is restricted for multi-value operations", cleanedKey];
        return [CTValidationResult dropWithCode:CTValidationErrorRestrictedKey
                                        message:message
                                         reason:CTDropReasonRestrictedMultiValueKey];
    }
    // If there were warnings in the base validation, preserve them
    if (result.outcome == CTValidationOutcomeWarning) {
        return result;
    }
    return [CTValidationResult successWithData:cleanedKey];
}

#pragma mark - Private Helper Methods

- (BOOL)isKeyRestrictedForMultiValue:(NSString *)key {
    if (!self.config.restrictedMultiValueFields) {
        return NO;
    }
    NSString *normalizedKey = [key lowercaseString];
    for (NSString *restricted in self.config.restrictedMultiValueFields) {
        NSString *normalizedRestricted = [restricted lowercaseString];
        if ([normalizedKey isEqualToString:normalizedRestricted]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)normalizeKey:(NSString *)key warnings:(NSMutableArray<CTValidationResult *> *)warnings {
    // Step 1: Trim whitespace
    NSString *cleaned = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // Step 2: Remove invalid characters
    if (self.config.keyCharsNotAllowed) {
        NSString *filtered = [[cleaned componentsSeparatedByCharactersInSet:self.config.keyCharsNotAllowed]
                             componentsJoinedByString:@""];
        
        if (![filtered isEqualToString:cleaned]) {
            cleaned = filtered;
            NSString *message = [NSString stringWithFormat:@"Key '%@' contains invalid characters", key];
            [warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorInvalidKey
                                                            message:message
                                                               data:nil]];
        }
    }
    // Step 3: Truncate if exceeds max length
    if (self.config.maxKeyLength) {
        NSInteger maxLength = [self.config.maxKeyLength integerValue];
        if (cleaned.length > maxLength) {
            cleaned = [cleaned substringToIndex:maxLength];
            NSString *message = [NSString stringWithFormat:@"Key '%@' exceeds %ld characters", key, (long)maxLength];
            [warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorKeyTooLong
                                                            message:message
                                                               data:nil]];
        }
    }
    // Step 4: Final trim
    return [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
@end
