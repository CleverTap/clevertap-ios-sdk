//
//  CTDataFlattener.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 21/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import "CTDataFlattener.h"
#import "CTProfileChangeTracker.h"
#import "CTProfileOperationUtils.h"

@implementation CTDataFlattener

+ (NSDictionary<NSString *, id> *)flatten:(NSDictionary *)json {
    return [self flattenInternal:json prefix:@""];
}

/**
 * Flattens a nested NSDictionary into a single-level NSDictionary with dot-notation keys
 * @param json The NSDictionary to flatten
 * @param prefix Optional prefix for keys (used in recursion)
 * @return Flattened dictionary with dot-notation keys
 */
+ (NSDictionary<NSString *, id> *)flattenInternal:(NSDictionary *)json
                                            prefix:(NSString *)prefix {
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];
    
    for (NSString *key in json) {
        id value = json[key];
        NSString *newKey = (prefix.length == 0) ? key : [NSString stringWithFormat:@"%@.%@", prefix, key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            // Recursively flatten nested objects
            NSDictionary *flattenedDict = [self flattenInternal:(NSDictionary *)value
                                                         prefix:newKey];
            [result addEntriesFromDictionary:flattenedDict];
            
        } else if ([value isKindOfClass:[NSArray class]]) {
            // Keep NSArray as-is (after processing)
            result[newKey] = [CTProfileOperationUtils processDatePrefixes:value];
            
        } else if ([value isKindOfClass:[NSNull class]]) {
            // no-op - skip NSNull values
            
        } else if ([value isKindOfClass:[NSString class]]) {
            // Process string values
            result[newKey] = [CTProfileOperationUtils processDatePrefixes:value];
            
        } else {
            // Primitive values (NSNumber, etc.)
            result[newKey] = value;
        }
    }
    
    return [result copy];
}

@end
