#import "CTValidator.h"
#import "CTValidationResult.h"
#import "CTConstants.h"
#import "CTKnownProfileFields.h"

static const int kMaxKeyChars = 120;
static const int kMaxValueChars = 1024;
static const int kMaxMultiValuePropertyArrayCount = 100;
static const int kMaxMultiValuePropertyValueChars = 1024;

@implementation CTValidator

/**
 * Cleans the event name to the following guidelines:
 *
 * The following characters are removed:
 * dot, colon, dollar sign, single quote, double quote, and backslash.
 * Additionally, the event name is limited to kMaxKeyChars characters.
 *
 *
 * @param name The event name to be cleaned
 * @return The ValidationResult object containing the object,
 *         and the error code(if any)
 */
+ (CTValidationResult *)cleanEventName:(NSString *)name {
    NSArray *eventNameCharsNotAllowed = @[@".", @":", @"$", @"'", @"\"", @"\\"];
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *x in eventNameCharsNotAllowed)
        name = [name stringByReplacingOccurrencesOfString:x withString:@""];
    
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length > kMaxKeyChars) {
        name = [name substringToIndex:kMaxKeyChars-1];
        NSString *errStr = [NSString stringWithFormat:@"%@%@", name, [NSString stringWithFormat:@"... exceeded the limit of %d characters. Trimmed", kMaxKeyChars]];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:510];
    }
    
    if (!(name == nil || [name isEqualToString:@""])) {
        [vr setObject:name];
    }
    return vr;
}

/**
 * Cleans the object key.
 *
 * @param name Name of the object key
 * @return The ValidationResult object containing the object,
 *         and the error code(if any)
 */
+ (CTValidationResult *)cleanObjectKey:(NSString *)name {
    NSArray *objectKeyCharsNotAllowed = @[@".", @":", @"$", @"'", @"\"", @"\\"];
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *x in objectKeyCharsNotAllowed)
        name = [name stringByReplacingOccurrencesOfString:x withString:@""];
    
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length > kMaxKeyChars) {
        name = [name substringToIndex:kMaxKeyChars-1];
        NSString *errStr = [NSString stringWithFormat:@"%@%@", name, [NSString stringWithFormat:@"... exceeded the limit of %d characters. Trimmed", kMaxKeyChars]];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:520];
    }
    
    if (!(name == nil || [name isEqualToString:@""])) {
        [vr setObject:name];
    }
    return vr;
}

/**
 * Cleans a multi-value property key according to the following guidelines:
 *
 * call the cleanObjectKey method which does:
 
 * The following characters are removed:
 * dot, colon, dollar sign, single quote, double quote, and backslash.
 * Additionally, the event name is limited to kMaxKeyChars characters.
 *
 * Known property keys are reserved for multi-value properties, subsequent validation is done for those
 *
 */

+ (CTValidationResult *)cleanMultiValuePropertyKey:(NSString *)name {
    
    CTValidationResult *vr = [CTValidator cleanObjectKey:name];
    
    name = (NSString *) [vr object];
    
    if(name != nil && ![name isEqualToString:@""]) {
        // if we have a valid object key; make sure its not a known property key (reserved in the case of multi-value)
        KnownField kf = [CTKnownProfileFields getKnownFieldIfPossibleForKey:name];
        if (kf != UNKNOWN) {
            NSString *errStr = [NSString stringWithFormat:@"%@%@", name, @" is a restricted key for multi-value properties. Operation aborted."];
            [vr setErrorCode:523];
            [vr setErrorDesc:errStr];
            [vr setObject:nil];
        }
    }
    return vr;
}

+ (CTValidationResult *)cleanMultiValuePropertyValue:(NSString *)value {
    
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    
    if (value == nil) return vr;
    
    // trim
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // force lowercase
    value = [value lowercaseString];
    
    // remove reserved characters
    NSArray *objectValueCharsNotAllowed = @[@"'", @"\"", @"\\"];
    for (NSString *x in objectValueCharsNotAllowed)
        value = [value stringByReplacingOccurrencesOfString:x withString:@""];
    
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // check len
    if (value.length > kMaxMultiValuePropertyValueChars) {
        value = [value substringToIndex:kMaxMultiValuePropertyValueChars-1];
        NSString *errStr = [NSString stringWithFormat:@"%@%@", value, [NSString stringWithFormat:@"... exceeds the limit of %d characters. Trimmed", kMaxMultiValuePropertyValueChars]];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:521];
    }
    
    if (value) {
        [vr setObject:value];
    }
    return vr;
}

+ (CTValidationResult *)cleanMultiValuePropertyArray:(NSArray *)multi forKey:(NSString*)key {
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    
    if(multi && [multi count] > kMaxMultiValuePropertyArrayCount) {
        NSMutableArray *_new = [NSMutableArray arrayWithArray:multi];
        
        long start = [multi count] - kMaxMultiValuePropertyArrayCount;
        
        multi = [_new subarrayWithRange:NSMakeRange((NSUInteger) start, (NSUInteger) kMaxMultiValuePropertyArrayCount)];
        NSString *errStr = [NSString stringWithFormat:@"Multi value user property for key %@ exceeds the limit of %d items. Trimmed", key, kMaxMultiValuePropertyArrayCount];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:521];
    }
    [vr setObject:multi];
    return vr;
}

+ (CTValidationResult *)cleanObjectValue:(NSObject *)o context:(CTValidatorContext)context {
    if (o == nil) {
        return nil;
    }
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    // If it's any type of number, send it back
    if ([o isKindOfClass:[NSNumber class]]) {
        [vr setObject:o];
        return vr;
    } else if ([o isKindOfClass:[NSString class]]) {
        NSString *value = (NSString *) o;
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSArray *objectValueCharsNotAllowed = @[@"'", @"\"", @"\\"];
        for (NSString *x in objectValueCharsNotAllowed)
            value = [value stringByReplacingOccurrencesOfString:x withString:@""];
        
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (value.length > kMaxValueChars) {
            value = [value substringToIndex:kMaxValueChars-1];
            NSString *errStr = [NSString stringWithFormat:@"%@%@", value, [NSString stringWithFormat:@"... exceeds the limit of %d characters. Trimmed", kMaxValueChars]];
            [vr setErrorDesc:errStr];
            [vr setErrorCode:521];
        }
        
        if (value) {
            [vr setObject:value];
        }
        return vr;
    } else if ([o isKindOfClass:[NSDate class]]) {
        NSString *date = [NSString stringWithFormat:@"$D_%d", (int) ((NSDate *) o).timeIntervalSince1970];
        [vr setObject:date];
        return vr;
        
    } else if ([o isKindOfClass:[NSArray class]]) {
        // allow string arrays for profiles
        if (context == CTValidatorContextProfile) {
            NSArray *values = (NSArray *) o;
            // make sure the values really are all strings
            NSMutableArray *_allStrings = [NSMutableArray new];
            for (id value in values) {
                @try {
                    [_allStrings addObject:[NSString stringWithFormat:@"%@", value]];
                }
                @catch (NSException *e) {
                    // no-op
                }
            }
            values = _allStrings;
            if (values.count > 0 && values.count <= kMaxMultiValuePropertyArrayCount) {
                [vr setObject:values];
            } else {
                NSString *errStr = [NSString stringWithFormat:@"Invalid user profile property array count: %lu; max is: %d", (unsigned long)values.count, kMaxMultiValuePropertyArrayCount];
                [vr setErrorDesc:errStr];
                [vr setErrorCode:521];
            }
            return vr;
        }
        
    } else {
        vr = nil;
    }
    return vr;
}

/**
 * Checks whether the specified event name is restricted. If it is,
 * then create a pending error, and abort.
 *
 * @param name The event name
 * @return Boolean indication whether the event name is restricted
 */
+ (BOOL)isRestrictedEventName:(NSString *)name {
    NSArray *restrictedNames = @[@"Notification Sent", @"Notification Viewed", @"Notification Clicked",
                                 @"UTM Visited", @"App Launched", @"Stayed", @"App Uninstalled", @"wzrk_d"];
    for (NSString *x in restrictedNames)
        if ([name.lowercaseString isEqualToString:x.lowercaseString]) {
            // The event name is restricted
            CTValidationResult *error = [[CTValidationResult alloc] init];
            [error setErrorCode:513];
            NSString *errStr = [NSString stringWithFormat:@"%@%@", name, @" is a restricted event name. Last event aborted."];
            [error setErrorDesc:errStr];
            return true;
        }
    return false;
}

+ (BOOL)isValidCleverTapId:(NSString *)cleverTapID {
    NSString *allowedCharacters = @"[A-Za-z0-9()!:@$_-]*";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", allowedCharacters];
    if (!cleverTapID) {
        CleverTapLogStaticInternal(@"CleverTapUseCustomId has been specified true in Info.plist but custom CleverTap ID passed is NULL.");
        return NO;
    } else if(cleverTapID.length <= 0){
        CleverTapLogStaticInfo(@"CleverTapUseCustomId has been specified true in Info.plist but custom CleverTap ID passed is empty.");
        return NO;
    } else if (cleverTapID.length > 64) {
        CleverTapLogStaticInfo(@"Custom CleverTap ID passed is greater than 64 characters.")
        return NO;
    } else if (![predicate evaluateWithObject:cleverTapID]) {
        CleverTapLogStaticInfo(@"Custom CleverTap ID cannot contain special characters apart from (, ), !, :, @, $, _, and -");
        return NO;
    }
    return YES;
}
@end
