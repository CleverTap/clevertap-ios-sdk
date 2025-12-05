#import "CTValidator.h"
#import "CTValidationResult.h"
#import "CTConstants.h"
#import "CTKnownProfileFields.h"
#import "CTUtils.h"

static const int kMaxKeyChars = 120;
static const int kMaxValueChars = 1024;
static const int kMaxMultiValuePropertyArrayCount = 100;
static const int kMaxMultiValuePropertyValueChars = 1024;
static const int kMaxNestingDepth = 3;
static const int kMaxArrayPropertiesPerLevel = 5;
static const int kMaxObjectPropertiesPerLevel = 5;
static const int kMaxPropertiesPerObject = 100;

static NSArray *discardedEvents;

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
    NSArray *objectKeyCharsNotAllowed = @[@":", @"$", @"'", @"\"", @"\\"];
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

#pragma mark - Main Cleaning Method

+ (CTValidationResult *)cleanObjectValue:(NSObject *)o
                                 context:(CTValidatorContext)context
                                   depth:(int)depth {
    if (o == nil || [self isEmptyValue:o forKey:nil]) {
        return nil;
    }
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    CTValidationResult *depthValidation = [self validateNestingDepth:depth];
    if (depthValidation) {
        return depthValidation;
    }
    if ([o isKindOfClass:[NSNumber class]]) {
        [vr setObject:o];
        return vr;
    }
    if ([o isKindOfClass:[NSDate class]]) {
        NSString *date = [NSString stringWithFormat:@"%@%d",CLTAP_DATE_PREFIX, (int) ((NSDate *) o).timeIntervalSince1970];
        [vr setObject:date];
        return vr;
    }
    if ([o isKindOfClass:[NSString class]]) {
        return [self cleanString:(NSString *)o];
    }
    if ([o isKindOfClass:[NSArray class]]) {
        return [self cleanArray:(NSArray *)o context:context depth:depth];
    }
    if ([o isKindOfClass:[NSDictionary class]]) {
        return [self cleanDictionary:(NSDictionary *)o context:context depth:depth];
    }
    return nil;
}

#pragma mark - Validation Helpers

+ (BOOL)isEmptyValue:(id)value forKey:(NSString* _Nullable)key {
    BOOL isEmpty = false;
    if ([value isKindOfClass:[NSNull class]]) {
        isEmpty = true;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        isEmpty = [(NSDictionary *)value count] == 0;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        isEmpty = [(NSArray *)value count] == 0;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)value stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        isEmpty = trimmed.length == 0;
    }
    if (isEmpty && key) {
        CleverTapLogStaticDebug(@"Event validation - Empty value found for key: %@", key);
    }
    return isEmpty;
}

+ (CTValidationResult *)validateNestingDepth:(int)depth {
    if (depth > kMaxNestingDepth) {
        CTValidationResult *vr = [[CTValidationResult alloc] init];
        NSString *errStr = [NSString stringWithFormat:
                            @"Maximum nesting depth exceeded %d levels",
                            kMaxNestingDepth];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:542];
        return vr;
    }
    return nil;
}

+ (CTValidationResult *)validateArrayElementCount:(NSInteger)count {
    if (count > kMaxMultiValuePropertyArrayCount) {
        CTValidationResult *vr = [[CTValidationResult alloc] init];
        NSString *errStr = [NSString stringWithFormat:
                            @"Array exceeded maximum element count. Allowed maximum is %d elements",
                            kMaxMultiValuePropertyArrayCount];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:544];
        return vr;
    }
    return nil;
}

+ (CTValidationResult *)validateObjectPropertyCount:(NSInteger)count {
    if (count > kMaxPropertiesPerObject) {
        CTValidationResult *vr = [[CTValidationResult alloc] init];
        NSString *errStr = [NSString stringWithFormat:
                            @"Object exceeded maximum property count. Allowed maximum is %d key-value pairs",
                            kMaxPropertiesPerObject];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:544];
        return vr;
    }
    return nil;
}

+ (CTValidationResult *)validateArrayAndObjectLimitsInDictionary:(NSDictionary *)dict {
    int arrayPropertiesCount = 0;
    int objectPropertiesCount = 0;
    
    //TODO: Count non-empty array and object properties
    for (id key in dict) {
        id value = dict[key];
        
        if ([self isEmptyValue:value forKey:key]) {
            continue;
        }
        if ([value isKindOfClass:[NSArray class]]) {
            arrayPropertiesCount++;
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            objectPropertiesCount++;
        }
    }
    if (arrayPropertiesCount > kMaxArrayPropertiesPerLevel) {
        CTValidationResult *vr = [[CTValidationResult alloc] init];
        NSString *errStr = [NSString stringWithFormat:
                            @"Maximum array-type properties exceeded. Found %d array properties, allowed maximum is %d per level",
                            arrayPropertiesCount, kMaxArrayPropertiesPerLevel];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:543];
        return vr;
    }
    if (objectPropertiesCount > kMaxObjectPropertiesPerLevel) {
        CTValidationResult *vr = [[CTValidationResult alloc] init];
        NSString *errStr = [NSString stringWithFormat:
                            @"Maximum object-type properties exceeded. Found %d object properties, allowed maximum is %d per level",
                            objectPropertiesCount, kMaxObjectPropertiesPerLevel];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:543];
        return vr;
    }
    return nil;
}

#pragma mark - String Cleaning

+ (CTValidationResult *)cleanString:(NSString *)string {
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    
    NSString *value = [string stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *restrictedChars = @[@"'", @"\"", @"\\"];
    for (NSString *c in restrictedChars) {
        value = [value stringByReplacingOccurrencesOfString:c withString:@""];
    }
    value = [value stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (value.length == 0) {
        return nil;
    }
    if (value.length > kMaxValueChars) {
        value = [value substringToIndex:kMaxValueChars - 1];
        NSString *errStr = [NSString stringWithFormat:
                            @"%@... exceeds the limit of %d characters. Trimmed",
                            value, kMaxValueChars];
        [vr setErrorDesc:errStr];
        [vr setErrorCode:521];
    }
    [vr setObject:value];
    return vr;
}

#pragma mark - Array Cleaning

+ (CTValidationResult *)cleanArray:(NSArray *)array
                           context:(CTValidatorContext)context
                             depth:(int)depth {
    // Validate array size
    CTValidationResult *sizeValidation = [self validateArrayElementCount:array.count];
    if (sizeValidation) {
        return sizeValidation;
    }
    if ([self arrayHasNestedStructures:array]) {
        return [self cleanNestedArray:array context:context depth:depth];
    } else {
        return [self cleanPrimitiveArray:array context:context];
    }
}

+ (BOOL)arrayHasNestedStructures:(NSArray *)array {
    for (id item in array) {
        if ([item isKindOfClass:[NSDictionary class]] ||
            [item isKindOfClass:[NSArray class]]) {
            return YES;
        }
    }
    return NO;
}

+ (CTValidationResult *)cleanNestedArray:(NSArray *)array
                                 context:(CTValidatorContext)context
                                   depth:(int)depth {
    NSMutableArray *cleanedArray = [NSMutableArray new];
    
    for (id item in array) {
        if ([self isEmptyValue:item forKey:nil]) {
            continue;
        }
        
        // Recursively clean nested items
        CTValidationResult *itemResult = [self cleanObjectValue:item
                                                        context:context
                                                          depth:depth + 1];
        
        if (itemResult && itemResult.errorCode != 0) {
            return itemResult;
        }
        
        if (itemResult && itemResult.object) {
            [cleanedArray addObject:itemResult.object];
        }
    }
    if (cleanedArray.count == 0) {
        return nil;
    }
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    [vr setObject:cleanedArray];
    return vr;
}

+ (CTValidationResult *)cleanPrimitiveArray:(NSArray *)array
                                    context:(CTValidatorContext)context {
    NSMutableArray *cleanedArray = [NSMutableArray new];
    
    for (id value in array) {
        if ([value isKindOfClass:[NSNull class]]) {
            continue;
        }
        //TODO: //check if existing logic is required
        if (context == CTValidatorContextProfile) {
            // Convert to strings for profile context
            @try {
                NSString *stringValue = [NSString stringWithFormat:@"%@", value];
                if (stringValue && stringValue.length > 0) {
                    [cleanedArray addObject:stringValue];
                }
            }
            @catch (NSException *e) {
                // Skip values that can't be converted
            }
        } else {
            // Keep original type for non-profile context
            if (value) {
                [cleanedArray addObject:value];
            }
        }
    }
    if (cleanedArray.count == 0) {
        return nil;
    }
    // Validate cleaned array size
    CTValidationResult *sizeValidation = [self validateArrayElementCount:cleanedArray.count];
    if (sizeValidation) {
        return sizeValidation;
    }
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    [vr setObject:cleanedArray];
    return vr;
}

#pragma mark - Dictionary Cleaning

+ (CTValidationResult *)cleanDictionary:(NSDictionary *)dict
                                context:(CTValidatorContext)context
                                  depth:(int)depth {
    CTValidationResult *countValidation = [self validateObjectPropertyCount:dict.count];
    if (countValidation) {
        return countValidation;
    }
    CTValidationResult *typeValidation = [self validateArrayAndObjectLimitsInDictionary:dict];
    if (typeValidation) {
        return typeValidation;
    }
    NSMutableDictionary *cleanedDict = [NSMutableDictionary new];
    
    for (id key in dict) {
        id value = dict[key];
        if ([self isEmptyValue:value forKey:nil]) {
            continue;
        }
        // Recursively clean the value
        CTValidationResult *cleanedValue = [self cleanObjectValue:value
                                                          context:context
                                                            depth:depth + 1];
        if (cleanedValue && cleanedValue.errorCode != 0) {
            CleverTapLogStaticDebug(@"Event validation - %@ for key: %@", cleanedValue.errorDesc, key);
            continue;
        }
        if (cleanedValue && cleanedValue.object) {
            cleanedDict[key] = cleanedValue.object;
        }
    }
    if (cleanedDict.count == 0) {
        return nil;
    }
    CTValidationResult *vr = [[CTValidationResult alloc] init];
    [vr setObject:cleanedDict];
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
                                 @"UTM Visited", @"App Launched", @"Stayed", @"App Uninstalled", @"wzrk_d", @"wzrk_fetch", @"SCCampaignOptOut", CLTAP_GEOFENCE_ENTERED_EVENT_NAME, CLTAP_GEOFENCE_EXITED_EVENT_NAME];
    for (NSString *x in restrictedNames)
        if ([CTUtils areEqualNormalizedName:name andName:x]) {
            // The event name is restricted
            CTValidationResult *error = [[CTValidationResult alloc] init];
            [error setErrorCode:513];
            NSString *errStr = [NSString stringWithFormat:@"%@%@", name, @" is a restricted event name. Last event aborted."];
            [error setErrorDesc:errStr];
            return true;
        }
    return false;
}

+ (BOOL)isDiscardedEventName:(NSString *)name {
    for (NSString *x in discardedEvents)
        if ([CTUtils areEqualNormalizedName:name andName:x]) {
            // The event name is discarded
            CTValidationResult *error = [[CTValidationResult alloc] init];
            [error setErrorCode:513];
            NSString *errStr = [NSString stringWithFormat:@"%@%@%@", name, @" is a discarded event, dropping event: ", name];
            [error setErrorDesc:errStr];
            return true;
        }
    return false;
}

+ (void)setDiscardedEvents:(NSArray *)events {
    discardedEvents = events;
}

+ (BOOL)isValidCleverTapId:(NSString *)cleverTapID {
    NSString *allowedCharacters = @"[=|<>;+.A-Za-z0-9()!:$@_-]*";
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
