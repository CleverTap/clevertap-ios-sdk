//
//  CTProfileOperationUtils.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import "CTProfileOperationUtils.h"
#import "CTConstants.h"

@implementation CTProfileOperationUtils

+ (BOOL)isDeleteMarker:(id)value {
    if (![value isKindOfClass:[NSString class]]) return NO;
    return [value isEqualToString:kCLTAP_DELETE_MARKER];
}

+ (id)processDatePrefix:(NSString *)value {
    if (![value isKindOfClass:[NSString class]]) return value;
    
    if ([value hasPrefix:CLTAP_DATE_PREFIX]) {
        NSString *numberString = [value substringFromIndex:[CLTAP_DATE_PREFIX length]];
        return @([numberString longLongValue]);
    }
    return value;
}

+ (NSArray *)processArrayDatePrefixes:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];
    for (id item in array) {
        [result addObject:[self processDatePrefixes:item]];
    }
    return [result copy];
}

+ (NSDictionary *)processObjectDatePrefixes:(NSDictionary *)obj {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:obj.count];
    for (NSString *key in obj) {
        id value = obj[key];
        result[key] = [self processDatePrefixes:value];
    }
    return [result copy];
}

+ (id)processDatePrefixes:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return [self processDatePrefix:(NSString *)value];
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        return [self processArrayDatePrefixes:(NSArray *)value];
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        return [self processObjectDatePrefixes:(NSDictionary *)value];
    }
    else {
        return value;
    }
}
@end

@implementation CTArrayMergeUtils

+ (NSArray *)copyArray:(NSArray *)array {
    return [[NSArray alloc] initWithArray:array copyItems:YES];
}

+ (BOOL)hasDeleteMarkerElements:(NSArray *)array {
    for (id element in array) {
        if ([CTProfileOperationUtils isDeleteMarker:element]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)hasJsonObjectElements:(NSArray *)array {
    for (id element in array) {
        if ([element isKindOfClass:[NSDictionary class]]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)shouldMergeArrayElements:(NSArray *)array {
    // Check if array contains objects or numbers that should be merged
    for (id element in array) {
        if ([element isKindOfClass:[NSDictionary class]] ||
            [element isKindOfClass:[NSNumber class]]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)arrayContainsString:(NSArray *)array string:(NSString *)string {
    return [array containsObject:string];
}
@end

@implementation CTNumberOperationUtils

+ (nonnull NSNumber *)addNumbers:(nonnull NSNumber *)a number:(nonnull NSNumber *)b {
    const char *aType = [a objCType];
    const char *bType = [b objCType];
    
    // Check if both are integers
    if (strcmp(aType, @encode(int)) == 0 && strcmp(bType, @encode(int)) == 0) {
        return @([a intValue] + [b intValue]);
    }
    // Check if either is long
    else if (strcmp(aType, @encode(long)) == 0 || strcmp(bType, @encode(long)) == 0 ||
             strcmp(aType, @encode(long long)) == 0 || strcmp(bType, @encode(long long)) == 0) {
        return @([a longLongValue] + [b longLongValue]);
    }
    // Check if either is float
    else if (strcmp(aType, @encode(float)) == 0 || strcmp(bType, @encode(float)) == 0) {
        return @([a floatValue] + [b floatValue]);
    }
    // Default to double
    else {
        return @([a doubleValue] + [b doubleValue]);
    }
}

+ (nonnull NSNumber *)subtractNumbers:(nonnull NSNumber *)a number:(nonnull NSNumber *)b {
    const char *aType = [a objCType];
    const char *bType = [b objCType];
    
    // Check if both are integers
    if (strcmp(aType, @encode(int)) == 0 && strcmp(bType, @encode(int)) == 0) {
        return @([a intValue] - [b intValue]);
    }
    // Check if either is long
    else if (strcmp(aType, @encode(long)) == 0 || strcmp(bType, @encode(long)) == 0 ||
             strcmp(aType, @encode(long long)) == 0 || strcmp(bType, @encode(long long)) == 0) {
        return @([a longLongValue] - [b longLongValue]);
    }
    // Check if either is float
    else if (strcmp(aType, @encode(float)) == 0 || strcmp(bType, @encode(float)) == 0) {
        return @([a floatValue] - [b floatValue]);
    }
    // Default to double
    else {
        return @([a doubleValue] - [b doubleValue]);
    }
}

+ (NSNumber *)negateNumber:(NSNumber *)n {
    // Get the underlying type using objCType
    const char *type = [n objCType];
    
    if (strcmp(type, @encode(int)) == 0 ||
        strcmp(type, @encode(NSInteger)) == 0 ||
        strcmp(type, @encode(short)) == 0 ||
        strcmp(type, @encode(char)) == 0) {
        return @(-[n integerValue]);
    }
    else if (strcmp(type, @encode(long)) == 0 ||
             strcmp(type, @encode(long long)) == 0) {
        return @(-[n longLongValue]);
    }
    else if (strcmp(type, @encode(float)) == 0) {
        return @(-[n floatValue]);
    }
    else if (strcmp(type, @encode(double)) == 0) {
        return @(-[n doubleValue]);
    }
    else {
        // Default case: treat as double
        return @(-[n doubleValue]);
    }
}
@end

@implementation CTJsonComparisonUtils

+ (BOOL)areEqual:(id)value1 value:(id)value2 {
    if (value1 == value2) return YES;
    if (!value1 || !value2) return NO;
    if ([value1 isKindOfClass:[NSString class]] && [value2 isKindOfClass:[NSString class]]) {
        return [(NSString *)value1 isEqualToString:(NSString *)value2];
    }
    if ([value1 isKindOfClass:[NSNumber class]] && [value2 isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value1 isEqualToNumber:(NSNumber *)value2];
    }
    if ([value1 isKindOfClass:[NSArray class]] && [value2 isKindOfClass:[NSArray class]]) {
        return [(NSArray *)value1 isEqualToArray:(NSArray *)value2];
    }
    if ([value1 isKindOfClass:[NSDictionary class]] && [value2 isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)value1 isEqualToDictionary:(NSDictionary *)value2];
    }
    return [value1 isEqual:value2];
}
@end
