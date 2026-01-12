//
//  CTEventNameValidator.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import "CTEventNameValidator.h"

@interface CTEventNameValidator ()
@property (nonatomic, strong) CTValidationConfig *config;
@end

@implementation CTEventNameValidator

- (instancetype)initWithConfig:(CTValidationConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

- (CTValidationResult *)validateEventName:(NSString *)eventName {
    // Step 1: Check for null/empty
    if (!eventName || eventName.length == 0) {
        return [CTValidationResult dropWithCode:510
                                        message:@"Event name is null or empty"
                                         reason:CTDropReasonNullEventName];
    }
    
    // Step 2: Normalize the event name
    NSString *originalName = eventName;
    NSString *cleaned = [self normalizeEventName:eventName];
    // Step 3: Check if became empty after normalization
    if (!cleaned || cleaned.length == 0) {
        return [CTValidationResult dropWithCode:510
                                        message:@"Event name became empty after normalization"
                                         reason:CTDropReasonNullEventName];
    }
    // Step 4: Check restricted event names
    if ([self isNameRestricted:cleaned]) {
        NSString *message = [NSString stringWithFormat:@"'%@' is a restricted event name", cleaned];
        return [CTValidationResult dropWithCode:513
                                        message:message
                                         reason:CTDropReasonRestrictedEventName];
    }
    // Step 5: Check discarded event names
    if ([self isNameDiscarded:cleaned]) {
        NSString *message = [NSString stringWithFormat:@"'%@' is a discarded event name", cleaned];
        return [CTValidationResult dropWithCode:513
                                        message:message
                                         reason:CTDropReasonDiscardedEventName];
    }
    // Step 6: Check if modifications were made during normalization
    if (![cleaned isEqualToString:originalName]) {
        NSString *message = [NSString stringWithFormat:
            @"Event name '%@' was normalized to '%@'", originalName, cleaned];
        return [CTValidationResult warningWithCode:510
                                           message:message
                                              data:cleaned];
    }
    // Step 7: Success - no issues found
    return [CTValidationResult successWithData:cleaned];
}

#pragma mark - Private Helper Methods

/**
 * Normalizes an event name by:
 * 1. Trimming whitespace
 * 2. Removing invalid characters
 * 3. Truncating to max length
 * 4. Final trim
 */
- (NSString *)normalizeEventName:(NSString *)eventName {
    // Step 1: Trim leading/trailing whitespace
    NSString *cleaned = [eventName stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // Step 2: Remove invalid characters using NSCharacterSet
    if (self.config.eventNameCharsNotAllowed) {
        NSString *filtered = [[cleaned componentsSeparatedByCharactersInSet:self.config.eventNameCharsNotAllowed]
                             componentsJoinedByString:@""];
        cleaned = filtered;
    }
    // Step 3: Truncate if exceeds max length
    if (self.config.maxEventNameLength) {
        NSInteger maxLength = [self.config.maxEventNameLength integerValue];
        if (cleaned.length > maxLength) {
            cleaned = [cleaned substringToIndex:maxLength];
        }
    }
    // Step 4: Final trim to remove any trailing whitespace
    return [cleaned stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/**
 * Checks if the event name is in the restricted list.
 * Uses case-insensitive comparison.
 */
- (BOOL)isNameRestricted:(NSString *)name {
    if (!self.config.restrictedEventNames) {
        return NO;
    }
    NSString *normalizedName = [name lowercaseString];
    for (NSString *restricted in self.config.restrictedEventNames) {
        NSString *normalizedRestricted = [restricted lowercaseString];
        if ([normalizedName isEqualToString:normalizedRestricted]) {
            return YES;
        }
    }
    return NO;
}

/**
 * Checks if the event name is in the discarded list.
 * Uses case-insensitive comparison.
 */
- (BOOL)isNameDiscarded:(NSString *)name {
    if (!self.config.discardedEventNames) {
        return NO;
    }
    NSString *normalizedName = [name lowercaseString];
    for (NSString *discarded in self.config.discardedEventNames) {
        NSString *normalizedDiscarded = [discarded lowercaseString];
        if ([normalizedName isEqualToString:normalizedDiscarded]) {
            return YES;
        }
    }
    return NO;
}
@end
