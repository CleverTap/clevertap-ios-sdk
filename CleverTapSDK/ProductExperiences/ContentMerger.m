//
//  ContentMerger.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "ContentMerger.h"

@implementation ContentMerger

+ (id)mergeWithVars:(id)vars diff:(id)diff {
    if (!diff) {
        return vars;
    }

    // Return the modified value if it is a `primitive`
    if ([diff isKindOfClass:[NSNumber class]] ||
        [diff isKindOfClass:[NSString class]] ||
        [diff isKindOfClass:[NSNull class]]) {
        return diff;
    }
    if ([vars isKindOfClass:[NSNumber class]] ||
        [vars isKindOfClass:[NSString class]] ||
        [vars isKindOfClass:[NSNull class]]) {
        return diff;
    }
    
    // Return nil if neither vars nor diff is dictionary.
    // Use isKindOfClass: to check first. Note that (NSDictionary *) cast will succeed if object is NSArray*.
    if (![vars isKindOfClass:[NSDictionary class]] && ![diff isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    if (![vars isKindOfClass:[NSDictionary class]]) {
        // diff is dictionary
        return diff;
    }
    
    // vars is dictionary
    NSMutableDictionary *merged = [NSMutableDictionary dictionaryWithDictionary:vars];
    if (![diff isKindOfClass:[NSDictionary class]]) {
        return merged;
    }

    // vars and diff are dictionary
    NSDictionary *diffDict = (NSDictionary *)diff;
    [diffDict enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id defaultValue = merged[key];
        id mergedValue = [self mergeWithVars:defaultValue diff:value];
        if (mergedValue) {
            merged[key] = mergedValue;
        }
    }];

    return merged;
}

@end
