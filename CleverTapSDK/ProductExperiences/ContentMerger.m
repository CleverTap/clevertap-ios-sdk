//
//  ContentMerger.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 17/02/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "ContentMerger.h"

@implementation ContentMerger

+ (id)mergeWithVars:(id)vars diff:(id)diff {
    if (diff == nil) {
        return vars;
    }
    
    // Return the modified value if it is a `primitive`
    if ([diff isKindOfClass:NSNumber.class] ||
        [diff isKindOfClass:NSString.class] ||
        [diff isKindOfClass:NSNull.class]) {
        return diff;
    }
    
    if ([vars isKindOfClass:[NSNumber class]] ||
        [vars isKindOfClass:[NSString class]] ||
        [vars isKindOfClass:NSNull.class]) {
        return diff;
    }
    
    NSMutableDictionary *merged = [NSMutableDictionary dictionary];
    BOOL isVarsDict = NO;
    if ([vars isKindOfClass:[NSDictionary class]]) {
        // Create new dictionary from vars
        merged = [NSMutableDictionary dictionaryWithDictionary:vars];
        isVarsDict = YES;
    }
    
    if ([diff isKindOfClass:[NSDictionary class]]) {
        NSDictionary *diffDict = (NSDictionary*)diff;
        [diffDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            id defaultValue = merged[key] ?: [NSNull null];
            merged[key] = [self mergeWithVars:defaultValue diff:value];
        }];
        
        return merged;
    } else if (isVarsDict) {
        // vars is a dictionary but diff is not or diff is nil, return vars
        return vars;
    }
    
    return [NSNull null];
}

@end
