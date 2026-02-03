//
//  CTEventNameValidator.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import "CTEventNameValidator.h"

@interface CTEventNameValidator ()
@property (nonatomic, strong) NSMutableArray<CTValidationResult *> *warnings;
@end

@implementation CTEventNameValidator

- (instancetype)initWithConfig:(CTValidationConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

- (CTValidationResult *)validateEventName:(NSString *)eventName {
    //Check for null/empty
    if (!eventName || eventName.length == 0) {
        return [CTValidationResult dropWithCode:CTValidationErrorEventNameNull
                                        message:@"Event name is null or empty"
                                         reason:CTDropReasonNullEventName];
    }
    
    //Normalize the event name
    NSString *originalName = eventName;
    NSString *cleaned = [self normalizeEventName:eventName];
    //Check if became empty after normalization
    if (!cleaned || cleaned.length == 0) {
        return [CTValidationResult dropWithCode:CTValidationErrorEventNameNull
                                        message:@"Event name became empty after normalization"
                                         reason:CTDropReasonNullEventName];
    }
    //Check restricted event names
    if ([self isNameRestricted:cleaned]) {
        NSString *message = [NSString stringWithFormat:@"'%@' is a restricted event name", cleaned];
        return [CTValidationResult dropWithCode:CTValidationErrorRestrictedEventName
                                        message:message
                                         reason:CTDropReasonRestrictedEventName];
    }
    //Check discarded event names
    if ([self isNameDiscarded:cleaned]) {
        NSString *message = [NSString stringWithFormat:@"'%@' is a discarded event name", cleaned];
        return [CTValidationResult dropWithCode:CTValidationErrorDiscardedEventName
                                        message:message
                                         reason:CTDropReasonDiscardedEventName];
    }
    //Truncate if exceeds max length
    if (self.config.maxEventNameLength) {
        NSInteger maxLength = [self.config.maxEventNameLength integerValue];
        if (cleaned.length > maxLength) {
            cleaned = [cleaned substringToIndex:maxLength];
        }
        [self.warnings addObject:[CTValidationResult warningWithCode:CTValidationErrorEventNameTooLong message:[NSString stringWithFormat:@"Event name '%@' exceeds the limit of %li characters. Trimmed to '%@'", eventName, (long)maxLength, cleaned] data:nil]];
    }
    //Check if modifications were made during normalization
    if (![cleaned isEqualToString:originalName]) {
        [self.warnings addObject:[CTValidationResult warningWithCode: CTValidationErrorInvalidCharacters message:[NSString stringWithFormat: @"Event name '%@' was normalized to '%@'", originalName, cleaned] data:cleaned]];
        return [CTValidationResult warningWithSubResults:self.warnings data:cleaned];
    }
    //Success - no issues found
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
    //Trim leading/trailing whitespace
    NSString *cleaned = [eventName stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //Remove invalid characters using NSCharacterSet
    if (self.config.eventNameCharsNotAllowed) {
        NSString *filtered = [[cleaned componentsSeparatedByCharactersInSet:self.config.eventNameCharsNotAllowed]
                             componentsJoinedByString:@""];
        cleaned = filtered;
    }
    //Final trim to remove any trailing whitespace
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
